#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Email::Sender::Simple;
use Email::Simple;
use Judoon::Emailer;


BEGIN {
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
}


my $emailer = Judoon::Emailer->new;


ok !$emailer->already_verp('test@example.com'), q{regular address isn't verp};
ok $emailer->already_verp('judoon+test=example.com@cellmigration.org'),
    q{verp address is verp};

is $emailer->make_verp_address('test@example.com'),
    'judoon+test=example.com@cellmigration.org', 'correctly build verp';


my $email = Email::Simple->create(
    header => [
        From => 'judoon@cellmigration.org',
        To   => 'to_in_header@example.com',
        Subject => 'Test Email',
    ], body => 'moo'
);
$emailer->send($email);
$emailer->send($email, {to => 'to_in_envelope@example.com'},);
$emailer->send($email, {from => 'from_in_envelope@cellmigration.org'},);

my @delivered = Email::Sender::Simple->default_transport->deliveries;
is $delivered[0]->{envelope}{from},
    'judoon+to_in_header=example.com@cellmigration.org',
    'verp To in email header';
is $delivered[1]->{envelope}{from},
    'judoon+to_in_envelope=example.com@cellmigration.org',
    'verp To in envelope';
is $delivered[2]->{envelope}{from},
    'from_in_envelope@cellmigration.org',
    q{don't overwrite from in envelope};



done_testing();
