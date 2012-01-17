package Judoon::DB::Roles::Deployer;

use version; our $VERSION = '0.0.1';
use autodie;
use open qw( :encoding(UTF-8) :std );

use Moose::Role;
use namespace::autoclean;


requires 'clear';
requires 'load_schema';
requires 'load_data';

sub reinit { return $_[0]->clear->init; }
sub init   { return $_[0]->load_schema->load_data; }


1;
__END__
