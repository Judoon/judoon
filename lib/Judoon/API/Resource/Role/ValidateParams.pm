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

use HTTP::Throwable::Factory qw(http_throw);

use Moo::Role;


=head1 METHODS

=head2 update_allows() (requires)

Consuming role must provide an C<update_allows()> method that returns
a list of fields that can be updated.

=cut

requires 'update_allows';
requires 'update_valid';


=head2 update_resource( \%params ) (before)

Runs before C<update_resource()> and makes sure that the contents of
C<\%params> are suitable for insertion into the database.  Throws an
HTTP 422 'Unprocessable Entity' error is validation fails.

=cut

before update_resource => sub {
    my ($self, $params) = @_;

    # get updatable params, empty original param list, copy back valid params
    my %valid_params = map {$_ => $params->{$_}} grep {exists $params->{$_}}
        $self->update_allows();
    delete @{$params}{ keys %$params };
    @{$params}{keys %valid_params} = (values %valid_params);

    my @errors;
    push @errors, map {['invalid_null', $_]} grep {
        (not defined $valid_params{$_})
            &&
        (not $self->item->column_info($_)->{is_nullable})
    } keys %valid_params;


    my $update_valid = $self->update_valid();
    for my $key (keys %$update_valid) {
        my $validator = $update_valid->{$key};
        if (ref $validator eq 'Regexp') {
            $update_valid->{$key} = sub {
                my ($self, $val) = @_;
                return $val =~ $validator;
            };
        }
    }

    push @errors, map {['bad_value',$_]} grep {
        defined($valid_params{$_})
            &&
        (not $update_valid->{$_}->( $self, $valid_params{$_} ) )
    } keys %$update_valid;

    if (@errors) {
        my @messages;

        if (my @invalid_null = grep {$_[0] eq 'invalid_null'} @errors) {
            push @messages,
                "Null not allowed for : " . join(', ', @invalid_null);
        }
        if (my @bad_values = grep {$_[0] eq 'bad_value'} @errors) {
            push @messages,
                "Bad value for : " . join(', ', @bad_values);
        }

        http_throw(UnprocessableEntity => {
            message => join("\n", @messages),
        });
    }
};




1;
__END__

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
