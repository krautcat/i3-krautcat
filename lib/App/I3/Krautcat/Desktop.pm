package App::I3::Krautcat::Desktop;

use strict;
use warnings;
use feature 'say';

use overload
    '""' => \&stringify;

use Moo;

sub new {
    my ($class, $value) = @_;

    my $self = bless {}, $class;

    if (ref($value) eq "HASH") {
        $self->_init_from_i3_msg($value);
    } else {
        $self->_init_from_desktop_name_string($value);
    }

    return $self;
}

sub _init_from_i3_msg {
    my ($self, $ws) = @_;

    $self->_init_();

    if ($ws->{focused}) {
        $self->{focused} = 1;
    } else {
        $self->{focused} = 0;
    }
    $self->{original_name} = $ws->{name};
    $self->{output_name} = $ws->{output};

    my ($number, $output_number, $name) = $self->_get_desktop_properties($ws->{name});

    $self->{number} = $number if defined $number;
    $self->{output_number} = $output_number if defined $number;
    $self->{name} = $name if defined $name;
}

sub _init_from_desktop_name_string {
    my ($self, $value) = @_;

    $self->_init_();

    $self->{original_name} = $value;

    my ($number, $output_number, $name) = $self->_get_desktop_properties($value);

    $self->{number} = $number if defined $number;
    $self->{output_number} = $output_number if defined $number;
    $self->{name} = $name if defined $name;
}

sub _init_ {
    my $self = shift;

    $self->{number} = undef;
    $self->{output_number} = undef;
    $self->{output_name} = undef;
    $self->{name} = undef;
    $self->{original_name} = undef;

    $self->{focused} = undef;

    return $self;
}

sub _get_desktop_properties {
    my ($self, $desktop_name) = @_;

    my ($number, $output_number, $name) = (undef, undef, undef);

    my $tag = undef;
    ($tag, $name) = split /:/, $desktop_name;
    if (not defined $name) {
        $name = $tag;
    } else {
        ($number, $output_number) = split / /, $tag;
    }

    return ($number, $output_number, $name);
}

sub stringify {
    my $self = shift;

    return $self->{original_name};
}

sub full_name {
    my $self = shift;

    return "$self->{number} $self->{output_number}:$self->{name}";
}

sub is_name_fully_qualified {
    my $self = shift;

    if (defined $self->{name}
        and defined $self->{number} != 0
        and defined $self->{output_number}) {
        return 1
    } else {
        return 0
    }
}

1;
