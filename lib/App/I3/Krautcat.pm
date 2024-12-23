package App::I3::Krautcat;

use strict;
use warnings;
use v5.30;
use utf8;

use App::Cmd::Setup -app;

sub prepare_args {
  map { utf8::decode($_) } @ARGV;
  @ARGV;
}

=head1 NAME

App::I3::Krautcat - The great new App::I3::Krautcat!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use App::I3::Krautcat;

    my $foo = App::I3::Krautcat->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Georgiy Odisharia, C<< <georgiy.odisharia at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-i3-krautcat at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-I3-Krautcat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::I3::Krautcat


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-I3-Krautcat>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-I3-Krautcat>

=item * Search CPAN

L<https://metacpan.org/release/App-I3-Krautcat>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Georgiy Odisharia.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of App::I3::Krautcat
