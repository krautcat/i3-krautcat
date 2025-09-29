package App::I3::Krautcat::Desktop;

use strict;
use warnings;
use feature 'say';

use overload
    '""' => \&stringify;

use Moo;

has number => (
    is => "rw",
);

has output_number => (
    is => "rw",
);

has output_name => (
    is => "rw",
);

has tag => (
    is => "rw",
);

has name => (
    is => "rw",
);

has original_name => (
    is => "ro",
);

has focused => (
    is => "ro",
);

around BUILDARGS => sub {
    my ($orig, $class, $arg, $configuration) = @_;

    my $args = {number        => undef,
                output_number => undef,
                output_name   => undef,
                tag           => undef,
                name          => undef,
                original_name => undef,
                focused       => undef,
    };

    my $full_name;
    if (ref($arg) eq "HASH") {
        if ($arg->{focused}) {
            $args->{focused} = 1;
        } else {
            $args->{focused} = 0;
        }
        $args->{original_name} = $arg->{name};
        $args->{output_name} = $arg->{output};
        $full_name = $arg->{name}
    } else {
        $args->{original_name} = $arg;
        $full_name = $arg;
    }

    my ($number, $output_number, $tag, $name) = $class->_get_desktop_properties($full_name, $configuration);

    $args->{number} = $number               if defined $number;
    $args->{output_number} = $output_number if defined $number;
    $args->{tag} = $tag                     if defined $tag;
    $args->{name} = $name                   if defined $name;

    return $class->$orig($args);
};

sub _get_desktop_properties {
    my ($class, $desktop_name, $configuration) = @_;

    my ($number, $output_number, $name) = (undef, undef, undef);

    my $tag = undef;
    ($tag, $name) = split /:/x, $desktop_name;
    if (not defined $name) {
        $name = $tag;
    } else {
        ($number, $output_number) = split / /, $tag;
    }

    ($tag, $name) = split(/ \| /x, $name);
    if (not defined $name) {
        $name = $tag;
        $tag = undef;
    } elsif (defined $configuration and not exists $configuration->ranges->{ranges}->{$tag}) {
        $name = "$tag | $name";
        $tag = undef;
    }

    return ($number, $output_number, $tag, $name);
}

sub stringify {
    my $self = shift;

    return $self->{original_name};
}

sub full_name {
    my $self = shift;

    my $name;
    if (defined $self->tag) {
        $name = "$self->tag | $self->name";
    } else {
        $name = $self->name;
    }

    return "$self->{number} $self->{output_number}:$name";
}

sub is_name_fully_qualified {
    my $self = shift;

    if (defined $self->{name} and defined $self->{number} != 0 and defined $self->{output_number}) {
        return 1;
    } else {
        return 0;
    }
}

1;
