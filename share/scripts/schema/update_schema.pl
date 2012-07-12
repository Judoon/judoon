#!/usr/bin/env perl

# Author:       Fitz Elliott <felliott@virginia.edu>
# Date Created: Thu Jul 12 10:50:42 2012
# Description:  this script updates the static Judoon::DB::User schema
#               from either the live database or a defined sql file.

use strict;
use warnings;
use autodie;
use open qw( :encoding(UTF-8) :std );
use feature ':5.14';

use FindBin qw($Bin);
use lib qq{$Bin/../../../lib};

use DBIx::Class::Schema::Loader 'make_schema_at';
use DBIx::RunSQL;
use Getopt::Long;
use Judoon::Web;
use Pod::Usage;

main: {
    my ($confirm, $from, $help, $debug) = (q{});
    GetOptions(
        'help|h' => \$help, 'confirm=s' => \$confirm,
        'from|f=s' => \$from, 'verbose|v' => \$debug,
    ) or pod2usage(2);
    pod2usage(1) if ($help || $confirm ne 'yes');

    # set up arguments common to both scenarios
    my %common_args = (
        use_moose               => 1,
        dump_directory          => "$Bin/../../../lib",
        exclude                 => qr/^dbix_class/,
        overwrite_modifications => 1,
        debug                   => +$debug,
    );

    my ($connect_info, %dbicsl_args) = ([],);
    if ($from && -e $from) {
        my $test_dbh = DBIx::RunSQL->create(
            dsn     => 'dbi:SQLite:dbname=:memory:',
            sql     => $from,
            force   => 1,
            verbose => +$debug,
        );
        $connect_info = [ sub { $test_dbh }, {} ];
        $dbicsl_args{overwrite_modifications} = 1;
    }
    else {
        my $path_to_root = "$Bin/../../../";
        $connect_info = [{
            dsn => "dbi:SQLite:${path_to_root}share/judoon-db-user-schema.db",
        }];
        %dbicsl_args = (
            rel_name_map => {
                Dataset => { dataset_columns => 'ds_columns', },
            },
        );
    }

    make_schema_at(
        'Judoon::DB::User::Schema',
        { %common_args, %dbicsl_args, },
        $connect_info,
    );

}

__END__

=head1 NAME

update_schema.pl -- regenerate DBIC schema from a db or sql file

=head1 SYNOPSIS

update_schema.pl -- regenerate DBIC schema from a db or sql file

 $ update_schema.pl --confirm=yes

WARNING!!!  This script will overwrite the contents of the
lib/Judoon/DB/User/Schema/Result directory!!!  Only run this if all
your outstanding changes have been committed or stashed, or THEY WILL
BE LOST!  To prevent you (i.e. Fitz) from doing something stupid, this
script will only run if you add the --confirm=yes switch.

=head1 OPTIONS

=over

=item B<-h, --help>

Prints this message and exits.

=item B<--confirm>

Prove that you are not messing around. COMMIT YOUR CHANGES!

=item B<-v, --verbose>

Turns on the DBIx::Class::Schema::Loader debug option

=item B<-f, --from $filename>

Use an sql file as the schema source


=back
