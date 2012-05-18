#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;

name 'Judoon-Web';
all_from 'lib/Judoon/Web.pm';

requires 'Authen::Passphrase::BlowfishCrypt';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Controller::REST';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Session::Store::Memcached';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Runtime' => '5.90007';
requires 'Catalyst::View::TT';
requires 'CatalystX::SimpleLogin';
requires 'Config::General';
requires 'Data::Printer';
requires 'Data::Section::Simple';
requires 'DBI';
requires 'DBIx::Class';
requires 'DBIX::Class::InflateColumn::Serializer';
requires 'DBIx::Class::PassphraseColumn';
requires 'File::Temp';
requires 'FindBin';
requires 'HTML::TreeBuilder';
requires 'JSON';
requires 'List::AllUtils';
requires 'Method::Signatures';
requires 'Module::Pluggable';
requires 'Moose';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::NonMoose';
requires 'MooseX::Storage';
requires 'namespace::autoclean';
requires 'Spreadsheet::Read';

test_requires 'indirect';
test_requires 'multidimensional';
test_requires 'bareword::filehandles';
test_requires 'Pod::Coverage';
test_requires 'Test::DBIx::Class';
test_requires 'Test::More' => '0.88';
test_requires 'Test::Fatal';
test_requires 'Test::Pod';
test_requires 'Test::Pod::Coverage';

WriteAll(meta => 0);
