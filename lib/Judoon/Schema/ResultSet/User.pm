package Judoon::Schema::ResultSet::User;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::User

=cut

use Judoon::Error::Input;

use Moo;
use namespace::clean;

extends 'Judoon::Schema::ResultSet';


use constant MIN_PASSWORD_LENGTH => 8;
use constant USERNAME_MAXLEN => 40;


=head1 METHODS

=head2 create_user( \%params )

Add a new user to the database, with sanity checks

=cut

sub create_user {
    my ($self, $params) = @_;

    my %valid;
    for my $k (qw(username password name email_address active)) {
        $valid{$k} = $params->{$k} if (exists $params->{$k});
    }

    my $errmsg;
    if (not $valid{username}) {
        $errmsg = q{No username was given!};
    }
    elsif (not defined $valid{password}) {
        $errmsg = q{No password was given!};
    }
    elsif (not defined $valid{email_address}) {
        $errmsg = q{No email address was given!};
    }
    elsif (not $self->validate_username($valid{username})) {
        $errmsg = q{Invalid username! Use only a-z, 0-9, and '_'. Must be }
            . q{less than } . USERNAME_MAXLEN . q{ characters.};
    }
    elsif ($self->user_exists($valid{username})) {
        $errmsg = q{This username is already taken!};
    }
    elsif ($self->email_exists($valid{email_address})) {
        $errmsg = q{Another account already has this email address.};
    }
    elsif (not $self->validate_password($valid{password})) {
        $errmsg = q{Password is not valid!  Must be more than eight characters long.};
    }

    Judoon::Error::Input->throw({message => $errmsg}) if ($errmsg);


    my $new_user;
    $self->result_source->schema->txn_do(
        sub {
            $new_user = $self->create(\%valid);

            # create new schema for user on Pg
            $self->result_source->storage->dbh_do(
                sub {
                    my ($storage, $dbh) = @_;
                    my $schema_name = $new_user->schema_name;
                    $dbh->do("CREATE SCHEMA $schema_name");
                },
            );
        }
    );

    return $new_user;
}


=head2 validate_username( $username )

Makes sure C<$username> is valid.  Current regex is C<m/^\w+$/>.

=cut

sub validate_username {
    my ($self, $username) = @_;
    return $username && $username =~ m/^\w+$/
        && length($username) <= USERNAME_MAXLEN;
}


=head2 validate_password( $password )

Makes sure the password is valid.  Currently allows all defined passwords.

=cut

sub validate_password {
    my ($self, $password) = @_;
    return defined $password && length($password) >= MIN_PASSWORD_LENGTH;
}


=head2 user_exists( $username )

Check to see if the username C<username> is in the database.

=cut

sub user_exists {
    my ($self, $username) = @_;
    return $self->find({username => $username});
}


=head2 email_exists( $email_address )

Check to see if the email address C<$email_address> is already in the
database.

=cut

sub email_exists {
    my ($self, $email_address) = @_;
    return $self->find({email_address => $email_address});
}


1;
