package Judoon::API::Resource::PageColumns;

use HTTP::Throwable::Factory qw(http_throw);
use Judoon::Tmpl;

use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';


sub create_allows { qw(template widgets title) };

before create_resource => sub {
    my ($self, $params) = @_;

    # get updatable params, empty original param list, copy back valid params
    my %valid_params = map {$_ => $params->{$_}} grep {exists $params->{$_}}
        $self->create_allows();
    delete @{$params}{ keys %$params };
    @{$params}{keys %valid_params} = (values %valid_params);

    my @errors;
    push @errors, map {['invalid_null', $_]} grep {
        (not defined $valid_params{$_})
            &&
        (not $self->set->result_source->column_info($_)->{is_nullable})
    } keys %valid_params;

    if (@errors) {
        my @messages;

        if (my @invalid_null = grep {$_[0] eq 'invalid_null'} @errors) {
            push @messages,
                "Null not allowed for : " . join(', ', @invalid_null);
        }

        http_throw(UnprocessableEntity => {
            message => join("\n", @messages),
        });
    }
};

around create_resource => sub {
    my $orig = shift;
    my $self = shift;
    my $data = shift;

    if (not (exists($data->{template}) xor exists($data->{widgets}))) {
        http_throw(UnprocessableEntity => {
            message => "Must provide exactly one of 'template' xor 'widgets'",
        });
    }

    eval {
        $data->{template}
            = exists $data->{widgets}  ? Judoon::Tmpl->new_from_data(delete $data->{widgets})
            : exists $data->{template} ? Judoon::Tmpl->new_from_jstmpl(delete $data->{template})
            :                            die 'Unreachable condition';
    };
    if ($@) {
        http_throw(UnprocessableEntity => {
            message => 'Invalid template syntax',
        });
    }

    return $self->$orig($data);
};


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::PageColumns - An set of PageColumns

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 create_allows

List of columns permitted in a C<create_resource> payload.

=head2 create_resource

Translate the C<template> parameter into a L<Judoon::Tmpl> object
suitable for insertion into the database.

=cut
