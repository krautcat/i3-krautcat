package App::I3::Krautcat::MonitorToNumber;

use strict;
use warnings;

sub new {
    my ($class, $output, $number) = @_;

    my $self = bless {}, $class;

    $self->{_output} = $output;
    $self->{_number} = $number;

    return $self;
}

sub output {
    my $self = shift;

    return $self->{_output};
}

sub number {
    my $self = shift;

    return $self->{_number};
}

1;
