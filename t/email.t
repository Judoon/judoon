#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use FindBin qw($Bin);

use Judoon::Email;

my $builder = Judoon::Email->new(kit_path => "$Bin/../root/src/email_kits/");

like exception { $builder->new_password_reset({}); },
    qr/Missing required 'reset_uri' field/,
    'cant send password reset email w/o reset uri';

my $email =  $builder->new_password_reset({reset_uri => 'moomoomoo'});
isa_ok($email, 'Email::MIME');

my $email_str = $email->as_string;
like $email_str, qr/reset your password/, 'got correct body';
like $email_str, qr/moomoomoo/, '  ..with correct reset_uri';
like $email_str, qr/Subject: Judoon password reset/, 'got correct subject';


done_testing();
