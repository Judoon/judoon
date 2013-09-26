package Judoon::Schema::Result::User;

=pod

=for stopwords Blowfish PassphraseColumn

=encoding utf8

=head1 NAME

Judoon::Schema::Result::User

=cut

use Judoon::Error::Devel::Arguments;
use Judoon::Error::Input;
use Judoon::Error::Input::Filename;
use Judoon::Schema::Candy;
use Judoon::Spreadsheet;

use Moo;
use namespace::clean;


use constant SCHEMA_PREFIX => 'user_';


table 'users';

primary_column id => {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
};
unique_column username => {
    data_type   => "varchar",
    size        => 40,
    is_nullable => 0,
};
column password => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 0,
};
column password_expires => {
    data_type       => "timestamp",
    is_nullable     => 1,
    is_serializable => 0,
};
column name => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 1,
};
unique_column email_address => {
    data_type       => "text",
    is_nullable     => 0,
    is_serializable => 1,
};
column active => {
    data_type     => "boolean",
    default_value => \'true',
    is_nullable   => 0,
};


has_many datasets => "::Dataset",
    { "foreign.user_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 };

has_many user_roles => "::UserRole",
    { "foreign.user_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 };
many_to_many roles => 'user_roles', 'role';

has_many tokens => '::Token',
    {'foreign.user_id' => 'self.id'},
    { cascade_copy => 0, cascade_delete => 0 };


=head1 EXTRA COMPONENTS

=head2 PassphraseColumn

Encrypt C<password> field using Blowfish cipher.

=cut

__PACKAGE__->load_components('PassphraseColumn');
__PACKAGE__->add_columns(
    '+password' => {
        passphrase       => 'rfc2307',
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {
            cost        => 8,
            salt_random => 20,
        },
        passphrase_check_method => 'check_password',
    }
);


=head2 ::Role::Result::HasTimestamps

Add <created> and <modified> columns to C<User>.

=cut

with qw(Judoon::Schema::Role::Result::HasTimestamps);
__PACKAGE__->register_timestamps;


=head1 METHODS

=head2 schema_name()

Get the name of the PostgreSQL schema for this user.

=cut

sub schema_name {
    return SCHEMA_PREFIX . $_[0]->username;
}


=head2 change_password( $password )

Validates and sets password

=cut

sub change_password {
    my ($self, $newpass) = @_;
    Judoon::Error::Input->throw({
        message => 'Invalid password.',
    }) unless ($self->result_source->resultset->validate_password($newpass));
    $self->password($newpass);
    $self->update;
}


=head2 import_data( $filehandle, $filetype )

C<import_data()> takes in a filehandle and file type and attempts to
turn it into a L<Judoon::Spreadsheet>.  A new C<Dataset> is created
from the C<Spreadsheet> and inserted into the database.

=cut

sub import_data {
    my ($self, $fh, $ext) = @_;

    Judoon::Error::Devel::Arguments->throw({
        message  => 'import_data() needs a filehandle',
        expected => q{filehandle},
        got      => ($fh // 'undef'),
    }) unless ($fh);
    Judoon::Error::Devel::Arguments->throw({
        message  => 'import_data() needs a filetype',
        expected => q{string},
        got      => ($ext // 'undef'),
    }) unless ($ext);

    my $spreadsheet = Judoon::Spreadsheet->new(
        filehandle => $fh, filetype => $ext,
    );

    my $dataset;
    $self->result_source->schema->txn_do( sub {
        $dataset = $self->create_related('datasets',{
            map({$_ => q{}} qw(name tablename original notes)),
            map({$_ => 0}   qw(nbr_rows nbr_columns)),
        });
        $dataset->import_from_spreadsheet($spreadsheet);
    });
    return $dataset;
}


=head2 import_data_by_filename( $filename )

Convenience method.  Opens C<$filename> then calls L</import_data>.

=cut

sub import_data_by_filename {
    my ($self, $filename) = @_;

    open my $SPREADSHEET, '<', $filename
         or Judoon::Error::Input::Filename->throw({
             message  => "Can't open test spreadsheet: $!",
             filename => $filename,
         });
    (my $ext = $filename) =~ s/^.*\.//;
    my $new_ds = $self->import_data($SPREADSHEET, $ext);
    close $SPREADSHEET;
    return $new_ds;
}


=head2 my_pages()

Convenience method to get C<User>'s pages as a resultset.

=cut

sub my_pages {
    my ($self) = @_;
    return $self->datasets_rs->related_resultset('pages');
}


=head2 new_reset_token

Generate a password reset token.

=cut

sub new_reset_token {
    my ($self) = @_;
    my $token = $self->new_related('tokens', {});
    $token->password_reset();
    $token->insert;
    return $token;
}


=head2 valid_reset_tokens

Get list of unexpired password reset tokens.

=cut

sub valid_reset_tokens {
    my ($self) = @_;
    return $self->search_related('tokens')->password_reset->unexpired->all;
}


=head2 new_or_refresh_access_token

Either create a new access token or extend the expiry of the current one.

=cut

sub new_or_refresh_access_token {
    my ($self) = @_;

    my $token = $self->tokens_rs->access_token->single;
    if (not $token) {
        $token = $self->new_related('tokens', {});
        $token->access_token;
        $token->insert();
    }
    else {
        $token->extend();
        $token->update();
    }

    return $token;
}


1;
