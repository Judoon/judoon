package Judoon::DB::User::Schema::ResultSet::User;

=pod

=encoding utf8

=cut

use strict;
use warnings;
use feature ':5.10';
use base 'DBIx::Class::ResultSet';

# use Moose;
# use namespace::autoclean;
# use MooseX::NonMoose;
# extends 'DBIx::Class::ResultSet';
# 
# use feature ':5.10';
# 
# sub BUILDARGS { $_[2] }

use constant MIN_PASSWORD_LENGTH => 8;


=head2 B<C<create_user( \%params )>>

Add a new user to the database, with sanity checks

=cut

sub create_user {
    my ($self, $params) = @_;

    my %valid;
    for my $k (qw(username password name email_address phone_number mail_address active)) {
        $valid{$k} = $params->{$k} if (exists $params->{$k});
    }

    my $errmsg;
    if (not $valid{username}) {
        $errmsg = q{No username was given!};
    }
    elsif (not defined $valid{password}) {
        $errmsg = q{No password was given!};
    }
    elsif (not $self->validate_username($valid{username})) {
        $errmsg = q{Invalid username! Use only a-z, 0-9, and '_'.};
    }
    elsif ($self->user_exists($valid{username})) {
        $errmsg = q{This username is already taken!};
    }
    elsif (not $self->validate_password($valid{password})) {
        $errmsg = q{Password is not valid!  Must be more than eight characters long.};
    }

    die $errmsg if ($errmsg);

    $valid{active} //= 1;

    my $thing = $self->create(\%valid);
    return $thing;
}


=head2 B<C<validate_username( $username )>>

Makes sure C<$username> is valid.  Current regex is C<m/^\w+$/>.

=cut

sub validate_username {
    my ($self, $username) = @_;
    return $username && $username =~ m/^\w+$/;
}


=head2 B<C<validate_password( $password )>>

Makes sure the password is valid.  Currently allows all defined passwords.

=cut

sub validate_password {
    my ($self, $password) = @_;
    return defined $password && length($password) >= MIN_PASSWORD_LENGTH;
}


=head2 B<C<user_exists( $username )>>

Check to see if the username C<username> is in the database.

=cut

sub user_exists {
    my ($self, $username) = @_;
    return $self->find({username => $username});
}



#__PACKAGE__->meta->make_immutable;

1;
__END__
