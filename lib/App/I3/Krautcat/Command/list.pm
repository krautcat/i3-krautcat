package App::I3::Krautcat::Command::list;

use strict;
use warnings;
use v5.30;
use utf8;

use AnyEvent::I3;

use App::I3::Krautcat -command;
use App::I3::Krautcat::Desktop;

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    $self->{i3_client} = i3();
    $self->{i3_client}->connect()->recv() or die "Error connecting to i3";;

    return $self;
}

sub execute {
    my ($self, $opt, $args) = @_;

    my @workspaces;
    foreach (@{$self->{i3_client}->message(AnyEvent::I3::TYPE_GET_WORKSPACES)->recv}) {
        push @workspaces, App::I3::Krautcat::Desktop->new($_);
    }

    foreach (@workspaces) {
        utf8::encode($_);
        say;
    }
}

1;