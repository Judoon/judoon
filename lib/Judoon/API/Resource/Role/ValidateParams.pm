package Judoon::API::Resource::Role::ValidateParams;

=pod

=encoding utf8

=for stopwords Unprocessable

=head1 NAME

Judoon::API::Resource::Role::ValidateParams - validate parameters on update

=head1 DESCRIPTION

This role is intended to be consumed by endpoints that allow the
updating of resources.  It runs before the C<update_resource()> method
and analyzes the contents of C<$params> for errors.

=cut

use HTTP::Throwable::Factory ();
use Safe::Isa;

use Moo::Role;


=head1 METHODS

=head2 update_allows() (requires)

Consuming role must provide an C<update_allows()> method that returns
a list of fields that can be updated.

=cut

requires 'update_allows';
requires 'update_ignore';
requires 'update_valid';


=head2 update_resource( \%params ) (before)

Runs before C<update_resource()> and makes sure that the contents of
C<\%params> are suitable for insertion into the database.  Throws an
HTTP 422 'Unprocessable Entity' error is validation fails.

=cut

before update_resource => sub {
    my ($self, $params) = @_;

    delete @{$params}{ $self->update_ignore() };

    my %update_allows = map {$_ => 1} $self->update_allows();


    my @errors;
    push @errors, map {['cant_modify', $_]} grep {
        !$update_allows{$_} && (
            (defined $params->{$_} xor defined $self->item->get_column($_))
                ||
            (not defined $params->{$_})
                ||
            ($params->{$_} ne $self->item->get_column($_))
        )
    } keys %$params;

    push @errors, map {['invalid_null', $_]} grep {
        (not defined $params->{$_})
            &&
        (not $self->item->column_info($_)->{is_nullable})
    } keys %update_allows;


    my $update_valid = $self->update_valid();
    push @errors, map {['bad_value',$_]} grep {
        defined($params->{$_})
            &&
        ($params->{$_} !~ $update_valid->{$_})
    } keys %$update_valid;

    if (@errors) {
        my @messages;

        if (my @cant_modify = grep {$_[0] eq 'cant_modify'} @errors) {
            push @messages,
                "Update not allowed for: " . join(', ', @cant_modify);
        }
        if (my @invalid_null = grep {$_[0] eq 'invalid_null'} @errors) {
            push @messages,
                "Null not allowed for : " . join(', ', @invalid_null);
        }
        if (my @bad_values = grep {$_[0] eq 'bad_value'} @errors) {
            push @messages,
                "Bad value for : " . join(', ', @bad_values);
        }

        HTTP::Throwable::Factory->throw({
            status_code => 422,
            reason      => 'Unprocessable Entity',
            message     => join("\n", @messages),
        });
    }
};


=head2 finish_request() (override)

Overrides the C<finish_request()> method of L</Web::Machine::Resource>
to handle non-standard errors.

=cut

sub finish_request {
    my ($self, $metadata) = @_;
    if (my $e = $metadata->{exception}) {
        if ($e->$_DOES('HTTP::Throwable')) {
            $self->response->status( $e->status_code );
            $self->response->body( $e->message );
        }
        else {
            warn $e;
        }
    }
}


1;
__END__
