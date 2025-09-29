package App::I3::Krautcat::Desktops;

use strict;
use warnings;
use v5.16;
use feature qw( switch );
use experimental qw( smartmatch );
no warnings qw( experimental::smartmatch );

use Moo;
use overload '@{}' => \&listify;

use List::Util qw( reduce );

use App::I3::Krautcat::Desktop;
use App::I3::Krautcat::Configuration::DesktopRanges;

has _desktops => (
    is => "ro",
);

has _ranges => (
    is => "ro"
);

has _fixed => (
    is => "ro"
);

has _pms_client => (
    is => "ro"
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    my $desktops = shift @args;
    my $configuration = shift @args;
    my $pms_client = shift @args;
    
    my @desktop_collection = map { App::I3::Krautcat::Desktop->new($_, $configuration) } @$desktops;
    return {
        _desktops => \@desktop_collection,
 
        _ranges => $configuration->{ranges},
        _fixed => $configuration->{fixed},

        _pms_client => $pms_client,
    };
};

sub listify {
    my $self = shift;
    return $self->_desktops
}

sub get_sort_number {
    my $self = shift;
    my $desktop = shift;

    if (grep { $desktop->name eq $_ } keys %{$self->_fixed}) {
        return $self->_fixed->{$desktop->name};
    }

    my $type = undef;

    if (not exists $self->_ranges->ranges->{$desktop->tag}) {
        my ($project, $issue_id) = $self->_pms_client->get_info_from_desktop_name($desktop->name);
        if (defined $project and $self->_pms_client->is_issue_exists($issue_id)) {
            $desktop->tag("__tickets__");
        } else {
            $desktop->tag("__unprefixed__");
        }
    }

    return $self->_guess_desktop_number($desktop);
}

sub _guess_desktop_number {
    my ($self, $desktop) = @_;

    my $number = undef;

    my @existing_desktops = grep { $_->name eq $desktop->name } @{$self->_desktops};
    if (@existing_desktops) {
        return $existing_desktops[0]->number
    }

    if ($desktop->tag =~ /^(?!__)/) {
        my $range = $self->_ranges->ranges->{$desktop->{tag}};
        $number = $range->get_first_free_number(
            grep { $range->in($_) }
            grep { defined $_ }
            map { $_->number }
            @{$self->_desktops}
        )
    } elsif ($desktop->tag eq "__unprefixed__") {
        $number = $self->_get_number_from_unprefixed 
    } elsif ($desktop->tag eq "__tickets__") {
        my ($project, $issue_id) = $self->_pms_client->get_info_from_desktop_name($desktop->name);
        my %project_to_range = $self->_get_project_ranges;
       
        my $get_from_unprefixed = 0; 
        my $subrange_start;
        if (exists $project_to_range{$project}) {
            $subrange_start = $project_to_range{$project}
        } else {
            $subrange_start = $self->_ranges->ranges->{__tickets__}->get_first_free_number(values %project_to_range);
            if (not defined $subrange_start) {
                 $get_from_unprefixed = 1; 
            }
        }

        if (not $get_from_unprefixed) {
            my $subrange = App::I3::Krautcat::Configuration::DesktopRange->new($subrange_start, step => 1);
            my @desktops_numbers_in_subrange = grep { $subrange->in($_) }
                grep { defined $_ }
                map { $_->number }
                @{$self->_desktops};

            $number = $subrange->get_first_free_number(@desktops_numbers_in_subrange);
            if (not defined $number) {
                $get_from_unprefixed = 1
            }
        } 

        if ($get_from_unprefixed) {
            $number = $self->_get_number_from_unprefixed
        }
    }

    return $number
}

sub _get_project_ranges {
    my $self = shift;
    
    my %range_to_project;

    foreach my $desktop (@{$self->_desktops}) {
        my ($project, $issue_id) = $self->_pms_client->get_info_from_desktop_name($desktop->name);
        if (not defined $project
                or not $self->_ranges->ranges->{__tickets__}->in($desktop->number)) {
            next
        }
        
        my $range_number = $desktop->number - $desktop->number % 10;
        $range_to_project{$range_number}{$project} += 1;
    }

    my %range_to_project_reduced = map {
            my $range = $_; 
            my $project = reduce {
                    $range_to_project{$range}{$a} > $range_to_project{$range}{$b} ? $a : $b 
                } keys %{$range_to_project{$range}};
            $range => $project
        } keys %range_to_project;

    my %project_to_ranges;
    foreach my $range (keys %range_to_project_reduced) {
        my $project = $range_to_project_reduced{$range};
        if (not exists $project_to_ranges{$project}) {
            $project_to_ranges{$project} = $range
        }
    }

    return %project_to_ranges
}

sub _get_number_from_unprefixed {
    my $self = shift;

    my $range = $self->_ranges->ranges->{__unprefixed__};
    my @desktops_numbers_in_range = grep { $range->in($_) } map { $_->number } @{$self->_desktops};
    return $range->get_first_free_number(@desktops_numbers_in_range);
}

1;
