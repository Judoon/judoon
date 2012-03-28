#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'Judoon-Web';
all_from 'lib/Judoon/Web.pm';

requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Controller::REST';
requires 'Catalyst::Runtime' => '5.90007';
requires 'CatalystX::SimpleLogin';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Config::General';
requires 'Data::Printer';
requires 'DBI';
requires 'DBIx::Class';
requires 'DBIX::Class::InflateColumn::Serializer';
requires 'HTML::TreeBuilder';
requires 'JSON';
requires 'Method::Signatures';
requires 'Moose';
requires 'MooseX::MarkAsMethods';
requries 'MooseX::NonMoose';
requires 'namespace::autoclean';
requires 'Spreadsheet::Read';

test_requires 'Test::DBIx::Class';
test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
