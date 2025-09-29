package App::I3::Krautcat::Configuration;

use strict;
use warnings;
use 5.016;

use Carp qw/croak/;

use File::BaseDir;
use Moo;
use TOML::Tiny;

use App::I3::Krautcat::MonitorToNumber;
use App::I3::Krautcat::Configuration::DesktopRanges;

has cfg => (
    is => "ro",
);

has _monitor_to_number => (
    is => "ro",
);

has ranges => (
    is => "ro",
);

has fixed => (
    is => "ro",
);

has task_tracker => (
    is => "ro",
);

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $config_file_path = File::BaseDir->new()->config_home("i3", "krautcat.ini");

    $args{cfg} = TOML::Tiny->new()->decode($class->_read_config($config_file_path));
    $args{_monitor_to_number} = $class->_parse_monitor_to_number($args{cfg});
    $args{ranges} = App::I3::Krautcat::Configuration::DesktopRanges->new($args{cfg}->{desktop}->{ranges});
    $args{fixed} = $args{cfg}->{desktop}->{fixed};
    $args{task_tracker} = $args{cfg}->{general}->{'task-tracker'};

    return $class->$orig(\%args);
};

sub _read_config {
    my ($class, $path) = @_;
    my $toml_string = do {
        local $/ = undef;
        open my $fh, "<", $path
            or croak "Could not open file '$path': $!";
        <$fh>
    };

    return $toml_string
}

sub _parse_monitor_to_number {
    my ($class, $cfg) = @_;
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
