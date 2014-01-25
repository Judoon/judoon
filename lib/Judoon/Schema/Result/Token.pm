package Judoon::Schema::Result::Token;

=pod

=for stopwords

=encoding utf8

=head1 NAME

Judoon::Schema::Result::Token - unique action tokens

=cut

use Data::Entropy::Algorithms qw/rand_bits/;
use DateTime;
use Judoon::Schema::Candy;
use MIME::Base64 qw/encode_base64url/;

use Moo;
use namespace::clean;


table 'tokens';

primary_column id => {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
};
unique_column value => {
    data_type     => "text",
    is_nullable   => 0,
    dynamic_default_on_create => \&_build_value,
};
column expires => {
    data_type     => 'timestamp with time zone',
    is_nullable   => 0,
    dynamic_default_on_create => \&_build_expires,
};
column action => {
    data_type   => "text",
    is_nullable => 0,
};
column user_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
};


belongs_to user => "::User",
    { "foreign.id" => "self.user_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };


sub _build_value {
    my ($self) = @_;
    return encode_base64url( rand_bits(192) );
}

sub _build_expires {
    my ($self) = @_;
    return DateTime->now->add(hours => 24);
}


=head1 METHODS

=head2 password_reset()

Sets the C<action> column to 'password_reset'.

=cut

sub password_reset { return $_[0]->action('password_reset'); }


=head2 access_token()

Sets the C<action> column to 'access'.

=cut

sub access_token { return $_[0]->action('access'); }


=head2 is_expired

Return true if C<Token>'s C<expires> field is less than now.

=cut

sub is_expired {
    my ($self) = @_;
    return DateTime->compare($self->expires, DateTime->now) != 1;
}


=head2 extend

Extended expiry for another default period;

=cut

sub extend {
    my ($self) = @_;
    $self->expires( $self->_build_expires() );
    return;
}

1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
