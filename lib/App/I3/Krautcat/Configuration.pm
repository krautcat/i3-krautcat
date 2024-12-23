package App::I3::Krautcat::Configuration;

use strict;
use warnings;
use 5.016;

use TOML::Tiny;
use File::BaseDir;

use App::I3::Krautcat::MonitorToNumber;
use App::I3::Krautcat::Configuration::DesktopRanges;

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    my $bd = File::BaseDir->new();
    my $config_file_path = $bd->config_home('i3', 'krautcat.ini');

    my $toml_string = $self->_read_config($config_file_path);
    $self->{cfg} = my $cfg = TOML::Tiny->new()->decode($toml_string);

    $self->{_monitor_to_number} = $self->_parse_monitor_to_number($cfg);
    $self->{ranges} = App::I3::Krautcat::Configuration::DesktopRanges->new($cfg->{desktop}->{ranges});
    $self->{fixed} = $cfg->{desktop}->{fixed};

    $self->{task_tracker} = $cfg->{general}->{'task-tracker'};

    return $self;
}

sub _read_config {
    my ($self, $path) = @_;
    my $toml_string = do {
        local $/ = undef;
        open my $fh, "<", $path
            or die "Could not open file '$path': $!";
        <$fh>
    };

    $toml_string
}

sub _parse_monitor_to_number {
    my ($self, $cfg) = @_;
    my $section = "outputs";
    my @monitor_to_number = ();

    my $_outputs = $cfg->{outputs};

    while (my ($output, $number) = each %$_outputs) {
        push @monitor_to_number, App::I3::Krautcat::MonitorToNumber->new($output, $number);
    }

    return \@monitor_to_number;
}

sub monitor_to_number {
    my ($self, $value) = @_;

    if (not defined $value) {
        return $self->{_monitor_to_number};
    }

    my ($output, $number) = split /:/, $value;

    foreach (@{$self->{_monitor_to_number}}) {
        if ($_->{_output} == $output) {
            $_->{_number} = $number;
            return;
        }
    }

    push @{$self->{_monitor_to_number}}, App::I3::Krautcat::MonitorToNumber->new($output, $number);
    return;
}

sub output_number {
    my $self = shift;

    return $self->{output_number};
}

1;
