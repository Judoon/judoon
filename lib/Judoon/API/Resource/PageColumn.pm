package Judoon::API::Resource::PageColumn;

use Judoon::Tmpl;
use Regexp::Common qw(RE_num_int);

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::Role::ScrubHTML';
with 'Judoon::API::Resource::Role::Item';

sub update_allows { return qw(title sort widgets) }
sub update_valid  { return {
    # template => sub {
    #     my ($self, $val) = @_;
    #     eval { Judoon::Tmpl->new_from_jstmpl($val); };
    #     return $@ ? 0 : 1;
    # },
    sort    => RE_num_int(),
    widgets => sub {
        my ($self, $val) = @_;
        eval { Judoon::Tmpl->new_from_data($val); };
        return $@ ? 0 : 1;
    },
}};
with 'Judoon::API::Resource::Role::ValidateParams';


around update_resource => sub {
    my $orig = shift;
    my $self = shift;
    my $data = shift;

    if (exists $data->{title}) {
        $data->{title} = $self->scrub_html_string($data->{title});
    }

    # if (my $jstmpl = delete $data->{template}) {
    #     my $tmpl   = Judoon::Tmpl->new_from_jstmpl($jstmpl);
    #     $data->{template} = $tmpl;
    # }
    if (my $widgets = delete $data->{widgets}) {
        my $tmpl = Judoon::Tmpl->new_from_data($widgets);
        $data->{template} = $tmpl;
    }
    return $self->$orig($data);
};

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::PageColumn - An individual PageColumn

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 update_resource

Translate the C<template> parameter into a L<Judoon::Tmpl> object
suitable for insertion into the database.

=head2 update_allows()

List of updatable parameters.

=head2 update_valid()

List of validation checks

=cut
