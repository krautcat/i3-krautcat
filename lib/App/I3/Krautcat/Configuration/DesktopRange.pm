package App::I3::Krautcat::Configuration::DesktopRange;

use strict;
use warnings;
use v5.30;

use Moo;
use Types::Standard qw/Int Undef Maybe/;

use overload 
    '@{}' => \&listify;

has from => (
    is => "ro",
    isa => Int->where(sub { $_ >= 0 })
);

has to => (
    is => "ro",
    isa => Maybe[Int->where(sub { $_ >= 0 })]
);

has step => (
    is => "ro",
    isa => Int->where(sub { $_ >= 0} )
);

around BUILDARGS => sub {
    my ($class, $orig, @args) = @_;

    my $range_param = shift @args;
    my %named_params = @args;

    if (ref $range_param eq 'ARRAY') {
        if (scalar @{$range_param} == 1) {
            return {
                from => $range_param->[0],
                to => undef,
                step => $named_params{step}
            }
        } else {
            return {
                from => $range_param->[0],
                to => $range_param->[1],
                step => $named_params{step}
            } 
        }
    } else {
        return {
            from => $range_param,
            to => $range_param + 10,
            step => $named_params{step}
        }
    }
};

sub listify {
    my $self = shift;
    if (not defined $self->to) {
        return []
    } else {
        my @range;
        for (my $num = $self->from; $num < $self->to; $num += $self->step) {
            push @range, $num
        }
        return \@range
    }
}

sub in {
    my ($self, $number) = @_;

    return 0 if not defined $number;

    if (defined $self->to) {
        return ($number >= $self->from and $number < $self->to) ? 1 : 0
    } else {
        return $number >= $self->from ? 1 : 0
    }
}

sub get_first_free_number {
    my $self = shift;
    my @ranges = @_;

    my $current_range = $self->from;
    if (not defined $self->to) {
        while (1) {
            if (not grep { $current_range == $_ } @ranges) {
                return $current_range
            } else {
                $current_range += $self->step;
            }
        }
    } else {
        foreach my $range (@$self) {
            if (not grep { $range == $_ } @ranges) {
                return $range
            }
        }
        return undef
    }
}

1;