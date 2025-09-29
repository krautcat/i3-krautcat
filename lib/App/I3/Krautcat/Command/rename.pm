package App::I3::Krautcat::Command::rename;

use strict;
use warnings;
use v5.30;
use utf8;

use AnyEvent::I3;
use Carp qw/croak/;
use Moo;
use Types::Standard qw/InstanceOf Maybe/;

use App::I3::Krautcat -command;
use App::I3::Krautcat::Configuration;
use App::I3::Krautcat::Desktops;

sub abstract {
    "rename workspaces";
}

sub description {
    "Rename workspaces";
}

sub validate_source_workspace {
    my $opt = shift;
    my $i3 = i3();

    $i3->connect->recv or die "Error connecting to i3";

    my $workspaces = $i3->message(AnyEvent::I3::TYPE_GET_WORKSPACES)->recv;

    foreach (@$workspaces) {
        return 1 if "$opt" eq "$_->{name}";
    }
    die "Not valid workspace name";
}

sub opt_spec {
    return (
        [
            "with=s",
            "name issues' workspaces with prefixes",
        ],
        [
            "no-tracker|n",
            "don't use information from task tracker",
        ],
        [
            "source|s=s",
            "name of source workspace",
            {
                callbacks => {
                    "valid source workspace name" => sub {
                        validate_source_workspace(@_);
                    }
                },
                required => 1,
            }
        ],
        [ 
            "dest|d=s",
            "destination name of workspace",
            {
                required => 1
            }
        ]
    )
}

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(@args);

    $self->{i3_client} = i3();
    $self->{i3_client}->connect()->recv() or die "Error connecting to i3";

    $self->{configuration} = App::I3::Krautcat::Configuration->new();

    $self->{_task_tracker_client} = $self->_get_task_tracker_api_object();
    $self->{desktops} = App::I3::Krautcat::Desktops->new(
        $self->{i3_client}->message(AnyEvent::I3::TYPE_GET_WORKSPACES)->recv,
        $self->{configuration},
        $self->{_task_tracker_client},
    );

    return $self;
}

sub _get_task_tracker_api_object {
    my $self = shift;

    my $task_tracker = $self->{configuration}->{task_tracker};
    my $pkg_name = "App::I3::Krautcat::API::$task_tracker";
    if (defined eval "require $pkg_name") {
        no strict 'refs';
        return $pkg_name->new($self->{configuration});
    }
}

sub construct_dest_ws {
    my ($self, $dest_opt, $source_ws, $opt) = @_;

    my $dest = $dest_opt;

    my $dest_desktop = App::I3::Krautcat::Desktop->new($dest);
    if ($dest_desktop->is_name_fully_qualified) {
        return "$dest_opt";
    }

    if (not defined $dest_desktop->{tag} or not $opt->{no_tracker}) {
        if ($self->{_task_tracker_client}->can("get_issue_with_project")) {
            if ($self->{_task_tracker_client}->is_issue_exists($dest_opt)) {
                $dest = $self->{_task_tracker_client}->get_issue_with_project($dest_opt);
            }
        }
    }
    
    my $dest_number = $self->{desktops}->get_sort_number($dest_desktop);
    my $dest_output_number = undef;

    foreach my $ws (@{$self->{desktops}}) {
        # Detect monitor for workspace from configuration.
        if ("$ws" eq "$source_ws") {
            for (@{$self->{configuration}->monitor_to_number()}) {
                if ($_->{_output} eq $ws->{output_name}) {
                    $dest_output_number = $_->{_number};
                    last;
                }
            }
        }
    }

    return "$dest_number $dest_output_number:$dest";
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $source_ws = App::I3::Krautcat::Desktop->new($opt->{source});
    my $dest_ws = $self->construct_dest_ws($opt->{dest}, $source_ws, $opt);

    my $cmd = "rename workspace \"$source_ws\" to \"$dest_ws\"";
    my $reply = $self->{i3_client}->message(AnyEvent::I3::TYPE_COMMAND, $cmd)->recv();
    if (not $reply->[0]->{success}) {
        if ($reply->[0]->{error} eq "New workspace \"$dest_ws\" already exists") {
            die "New workspace exists";
        }
    };
}

1;
