package Judoon::Web::Controller::Info;

=pod

=for stopwords user-centric

=encoding utf8

=head1 NAME

Judoon::Web::Controller::Info - informational pages (news, about-us)

=cut

use Moose;
use namespace::autoclean;

BEGIN { extends 'Judoon::Web::Controller'; }


=head1 ACTIONS

=head2 base

Base action, everything chains off this.  Not used at the moment, but
may come in handy later.

=cut

sub base : Chained('/base') PathPart('') CaptureArgs(0) {}


=head2 news

News updates about the site.

=cut

sub news : Chained('base') PathPart('news') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'info/news.tt2';
}


=head2 about

Our "About us" page.

=cut

sub about : Chained('base') PathPart('about') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'info/about.tt2';
}


=head2 get_started

Show user the "getting started" page

=cut

sub get_started : Chained('base') PathPart('get_started') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'info/get_started.tt2';
}




__PACKAGE__->meta->make_immutable;

1;
__END__
