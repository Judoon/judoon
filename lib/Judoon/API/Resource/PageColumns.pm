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
    my ($self, $data) = @_;

    my $all_params = ref $data eq 'ARRAY' ? $data : [$data];
    for my $params (@$all_params) {

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
    }
};

around create_resource => sub {
    my $orig = shift;
    my $self = shift;
    my $data = shift;


    if ($self->request->method eq 'PUT') {
        if (ref $data ne 'ARRAY') {
            http_throw(UnprocessableEntity => {
                message => 'this PUT request expects a collection (array)',
            });
        }

        $self->set->result_source->schema->txn_do(
            sub {
                $self->set->delete;
                foreach my $newobj (@$data) {
                    $self->construct_template($newobj);
                    $self->set->create($newobj);
                }
            }
        );

        return;
    }
    elsif ($self->request->method eq 'POST') {
        if (ref $data ne 'HASH') {
            http_throw(UnprocessableEntity => {
                message => 'this POST request expects an object (hash)',
            });
        }

        $self->construct_template($data);
        return $self->$orig($data);
    }
};


around allowed_methods => sub {
    my $orig = shift;
    my $self = shift;

    my $allowed = $self->$orig;
    if ($self->writable) {
        push @$allowed, 'PUT';
    }

    return $allowed;
};


sub construct_template {
    my ($self, $data) = @_;

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

    return;
}




1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::PageColumns - An set of PageColumns

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 MODIFIED METHODS

=head2 allowed_methods

Permit C<PUT> requests if resource is writable.

=head2 create_resource

Validates the incoming data and handles both C<PUT> and C<POST>
methods.


=head1 METHODS

=head2 create_allows

List of columns permitted in a C<create_resource> payload.

=head2 construct_template( \%data )

Turn either C<<$data->{widgets}>> or C<<$data->{template}>> into a
L<Judoon::Tmpl> object that we can insert into the database.  Throws
error if template construction fails.

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
