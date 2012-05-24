package Judoon::DB::User::Schema::ResultSet::User;

use strict;
use warnings;
use feature ':5.10';

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::ResultSet';

sub create_user {
    my ($self, $params) = @_;

    $DB::single = 1;
    my %valid;
    for my $k (qw(username password name email_address phone_number mail_address active)) {
        $valid{$k} = $params->{$k} if (exists $params->{$k});
    }

    my $errmsg;
    if (not $valid{username}) {
        $errmsg = q{No username was given!};
    }
    elsif (not $valid{password}) {
        $errmsg = q{No password given!};
    }
    elsif (not $self->validate_username($valid{username})) {
        $errmsg = q{Invalid username! Use only a-z, 0-9, and '_'.};
    }
    elsif ($self->user_exists($valid{username})) {
        $errmsg = q{This username is already taken!};
    }
    elsif (not $self->validate_password($valid{password})) {
        $errmsg = q{Password must be at least 8 characters!};
    }

    die $errmsg if ($errmsg);

    $valid{active} //= 1;

    my $thing = $self->create(\%valid);
    return $thing;
}


=head2 B<C<validate_username>>

Makes sure the username is valid.  Current regex is C<m/^\w+$/>.

=cut

sub validate_username {
    my ($self, $username) = @_;
    return $username && $username =~ m/^\w+$/;
}


=head2 B<C<validate_password>>

Makes sure the password is valid.  Currently always return true.

=cut

sub validate_password { return 1; }


=head2 B<C<user_exists>>

=cut

sub user_exists {
    my ($self, $username) = @_;
    return $self->find({username => $username});
}



__PACKAGE__->meta->make_immutable;

1;
__END__
