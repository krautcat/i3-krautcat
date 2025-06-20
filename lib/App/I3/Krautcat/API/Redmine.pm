package App::I3::Krautcat::API::Redmine;

use strict;
use warnings;
use 5.016;

use AnyEvent;
use AnyEvent::HTTP qw//;
use Carp qw/croak/;
use JSON::PP;
use Moo;
use Scalar::Util qw/blessed/;
use Types::Standard qw/Str/;
use URI qw//;

has _server => (
    is => 'ro',
    isa => sub { croak "$_[0] is not URI" unless blessed($_[0]) && $_[0]->isa('URI') },
);

has _api_key => (
    is => 'ro',
    isa => Str,
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    if (blessed($args[0]) && $args[0]->isa("App::I3::Krautcat::Configuration")) {
        return {
            _server => URI->new($args[0]->{cfg}->{api}->{redmine}->{server}),
            _api_key => $args[0]->{cfg}->{api}->{redmine}->{api_key},
        }
    } else {
        return {
           _server => URI->new(shift),
           _api_key => shift
        }
    }
};

sub is_issue_exists {
    my $self = shift;
    my $issue_id = shift;

    my $cv = AnyEvent->condvar;

    my %headers = (
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "X-Redmine-API-Key" => $self->_api_key,
    );
    my %params = (
        headers => \%headers,
    );
    my $endpoint = "/issues/$issue_id.json";
    
    my $url = URI->new_abs($endpoint, $self->_server);

    AnyEvent::HTTP::http_get($url, %params, sub {
        my ($data, $headers) = @_;
        my $status_code = $headers->{Status};

        if ($status_code == 200) {
            $cv->send(1);
        } elsif ($status_code == 404) {
            $cv->send(0)
        } else {
            die "Error $status_code";
        }
    });

    $cv->recv;
}

sub get_project_name {
    my $self = shift;
    my $issue_id = shift;

    my $cv = $self->_get_issue_info_jsoned($issue_id);
    my $json_reply = $cv->recv;
    if (not defined $json_reply) {
        return undef;
    }
    my $reply = JSON::PP->new->decode($json_reply);


    my $issues = $reply->{issues};
    my $issue;
    foreach my $is (@$issues) {
        if (int($issue_id) == $is->{id}) {
            $issue = $is;
            last;
        }
    }

    if (not defined($issue)) {
        return $issue
    }

    my $project_name = $issue->{project}->{name};
    utf8::decode($project_name);
    $project_name;
}

sub get_issue_with_project {
    my $self = shift;
    my $issue_id = shift;
    my $project = $self->get_project_name($issue_id);


    "$project | $issue_id";
}

sub get_info_from_desktop_name {
    my $self = shift;
    my $desktop_name = shift;

    utf8::decode($desktop_name);
    my @splitted_name = split(/\ \|\ /x, $desktop_name);
    return @splitted_name;
}

sub _get_issue_info_jsoned {
    my $self = shift;
    my $issue_id = shift;

    my $cv = AnyEvent->condvar;

    my %headers = (
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "X-Redmine-API-Key" => $self->_api_key,
    );
    my %params = (
        headers => \%headers,
    );
    my $endpoint = "/issues.json";

    my $url = URI->new_abs($endpoint, $self->_server);
    my %url_params = (
        issue_id => "$issue_id"
    );
    $url->query_form(%url_params);

    my $json_reply;
    AnyEvent::HTTP::http_get($url, %params, sub {
        my ($data, $headers) = @_;
        my $status_code = $headers->{Status};

        if ($status_code == 200) {
            $cv->send($data);
        } elsif ($status_code == 404 or $status_code == 422) {
            $cv->send(undef);
        } else {
            die "Error $status_code";
        }
    });
    
    $cv;
}

1;

