package App::I3::Krautcat::CLI::Opts::MonitorToNumber;

use strict;
use warnings;

sub new {
    my ($class, $monitor_output, $i3_tag) = @_;
    my $self = bless {}, $class;

    $self->{monitor} = $monitor_output;
    $self->{tag} = $i3_tag;

    return $self;
}

1;