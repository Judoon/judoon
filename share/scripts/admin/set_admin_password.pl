#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../../lib";

BEGIN { $ENV{CATALYST_DEBUG} = 0 }

use Judoon::Web;
use DateTime;

my $admin = Judoon::Web->model('User::User')->find({ username => 'fge7z' });
$admin->update({ password => 'moomoo', password_expires => DateTime->now });
