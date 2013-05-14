package Judoon::Schema::ResultSet::Token;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::Token

=cut

use Moo;
extends 'Judoon::Schema::ResultSet';

use DateTime;


=head1 METHODS

=head2 find_by_value( $token_value )

Find a token with a given value

=head2 password_reset()

Find all tokens with a password_reset action.

=head2 unexpired()

Find all tokens that have not yet expired.

=cut

sub find_by_value  { shift->find({value => shift}); }
sub password_reset { shift->search({action => 'password_reset'}); }
sub unexpired      {
    my ($self) = @_;
    my $dtf = $self->result_source->schema->storage->datetime_parser;
    return $self->search({
        expires => {'>' => $dtf->format_datetime(DateTime->now)},
    });
}

1;
__END__
