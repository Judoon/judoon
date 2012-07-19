#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;

name 'Judoon-Web';
all_from 'lib/Judoon/Web.pm';

requires 'Authen::Passphrase::BlowfishCrypt';
requires 'autodie';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Action::REST';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Session::Store::Memcached';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Runtime' => '5.90013';
requires 'Catalyst::View::Download';
requires 'Catalyst::View::TT';
requires 'CatalystX::RoleApplicator';
requires 'CatalystX::SimpleLogin';
requires 'Config::General' => '2.51';
requires 'Data::Printer';
requires 'Data::Section::Simple';
requires 'DateTime';
requires 'DBI';
requires 'DBIx::Class';
requires 'DBIx::Class::InflateColumn::Serializer';
requires 'DBIX::Class::Migration';
requires 'DBIx::Class::PassphraseColumn';
requires 'DBIx::Class::Schema::Loader';
requires 'DBIx::RunSQL';
requires 'File::Temp';
requires 'FindBin';
requires 'Getopt::Long';
requires 'HTML::TreeBuilder';
requires 'JSON';
requires 'JSON::Any';
requires 'List::AllUtils';
requires 'Method::Signatures';
requires 'Module::Pluggable';
requires 'Moo';
requires 'Moose';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::NonMoose';
requires 'MooseX::Storage';
requires 'namespace::autoclean';
requires 'Pod::Usage';
requires 'Spreadsheet::Read';
requires 'Spreadsheet::WriteExcel';
requires 'Throwable::Error';
requires 'Try::Tiny';

test_requires 'indirect';
test_requires 'multidimensional';
test_requires 'bareword::filehandles';
test_requires 'Pod::Coverage';
test_requires 'Test::DBIx::Class';
test_requires 'Test::More' => '0.88';
test_requires 'Test::Fatal';
test_requires 'Test::Pod';
test_requires 'Test::Pod::Coverage';
test_requires 'Test::WWW::Mechanize::Catalyst';

WriteAll(meta => 0);
