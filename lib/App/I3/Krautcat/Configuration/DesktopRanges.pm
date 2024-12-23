package App::I3::Krautcat::Configuration::DesktopRanges;

use strict;
use warnings;
use 5.016;

use Moo;
use Types::Standard qw( Str Map InstanceOf );

use App::I3::Krautcat::Configuration::DesktopRange;

has ranges => (
    is => "ro",
    isa => Map[Str, InstanceOf["App::I3::Krautcat::Configuration::DesktopRange"]]
);

around BUILDARGS => sub {
    my ($class, $orig, @args) = @_;

    my %ranges = map {
            my $step = 1;
            if ($_ eq "__tickets__") {
                $step = 10
            }
            "$_" => App::I3::Krautcat::Configuration::DesktopRange->new($args[0]{$_}, step => $step)
        } keys %{$args[0]}; 

    return {
        ranges => \%ranges
    }
};

1;