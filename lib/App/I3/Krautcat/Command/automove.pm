package App::I3::Krautcat::Command::automove;

use strict;
use warnings;
use feature 'say';

use AnyEvent::I3;

use Data::Printer;

use App::I3::Krautcat -command;
use App::I3::Krautcat::CLI::Opts::MonitorToNumber;
use App::I3::Krautcat::Desktop;

sub abstract {
    "move workspaces";
}

sub description {
    "Move workspaces to monitor accoringly to tags' number";
}

sub validate_monitor_to_tag_mapping {
    my $opt = shift;

    foreach (@$opt) {
        if (not $_ =~ /:/) {
            die "Display and tag must be separated with semicolon";
        }
    }

    return 1;
}

sub opt_spec {
    return (
        [
            "monitor-to-number=s@",
            "monitor to tag number mapping",
            {
                callbacks => {
                    "valid mapping monitor to tag number" => sub {
                        validate_monitor_to_tag_mapping(@_);
                    }
                }
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

    return $self;
}

sub execute {
    use Data::Printer;
    my ($self, $opt, $args) = @_;

    my @monitor_to_number = ();
    foreach (@{$opt->{monitor_to_number}}) {
        $self->{configuration}->monitor_to_number($_);
    }

    my @workspaces;
    foreach (@{$self->{i3_client}->message(AnyEvent::I3::TYPE_GET_WORKSPACES)->recv}) {
        push @workspaces, App::I3::Krautcat::Desktop->new($_);
    }

    my $focused_ws;
    foreach my $ws (@workspaces) {
        if ($ws->{focused}) {
            $focused_ws = $ws;
        }

        # Find appropriate output.
        my $output = undef;
        if (defined $ws->{output_number}) {
            foreach (@{$self->{configuration}->monitor_to_number}) {
                if ($_->number == $ws->{output_number}) {
                    $output = $_->output;
                }
            }
        } else {
            $output = $ws->{output_name};
        }

        my $reply = $self->{i3_client}->message(AnyEvent::I3::TYPE_COMMAND, "workspace $ws")->recv;
        if (not $reply->[0]->{success}) {
            say "Cannot focus to workspace";
        }

        say "Move $ws to output $output";

        $reply = $self->{i3_client}->message(AnyEvent::I3::TYPE_COMMAND, "move workspace to output $output")->recv;
        if (not $reply->[0]->{success}) {
            say "Cannot move workspace to output";
        }
    }
    my $reply = $self->{i3_client}->message(AnyEvent::I3::TYPE_COMMAND, "workspace $focused_ws")->recv;
}

1;
