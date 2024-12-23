package App::I3::Krautcat::API::YouTrack;

use strict;
use warnings;
use feature 'say';

use Scalar::Util qw( blessed );

use Moo;
use Types::Standard qw( Str );

use AnyEvent;
use AnyEvent::HTTP ();

use URI ();

has _server => (
    is => "ro",
    isa => sub { die "$_[0] is not URI" unless blessed($_[0]) && $_[0]->isa("URI") }
);

has _token => (
    is => "ro",
    isa => Str
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    
    if (blessed($args[0]) && $args[0]->isa("App::I3::Krautcat::Configuration")) {
        return {
            _server => URI->new($args[0]->{api}->{youtrack}->{server}),
            _token => $args[0]->{api}->{youtrack}->{token}
        }
    } else {
        return {
           _server => URI->new(shift),
           _token => shift
        }
    }
};

sub is_issue_exists {
    my $self = shift;
    my $issue = shift;
    return $self->_check_status_code("/api/issues/$issue")->recv();
}

sub is_project_exists {
    my $self = shift;
    my $project = shift;
    return $self->_check_status_code("/api/admin/projects/$project")->recv();
}

sub get_project_name {
    my $self = shift;
    my $issue = shift;

    my ($project, $issue_number) = split /-([^-]+)$/, $issue;

    if ($self->is_project_exists($project)) {
        return $project
    } else {
        return undef
    }
}

sub _check_status_code {
    my $self = shift;
    my $endpoint = shift; 

    my $cv = AnyEvent->condvar;

    my %headers = (
        "Accept" => "application/json",
        "Authorization" => "Bearer " . $self->_token,
        "Cache-Control" => "no-cache",
        "Content-Type"=> "application/json"
    );
    my %params = (
        headers => \%headers
    );
    my $url = URI->new_abs($endpoint, $self->_server);

    AnyEvent::HTTP::http_get($url, %params, sub {
        my ($data, $headers) = @_;
        my $status = $headers->{Status};
        
        if ($status == 200) {
            $cv->send(1)
        } elsif ($status == 404) {
            $cv->send(0)
        } else {
            die "Error $status"
        }
    });

    $cv
}

1;
