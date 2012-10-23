#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;

name 'Judoon-Web';
all_from 'lib/Judoon/Web.pm';

requires 'Archive::Builder';
requires 'Archive::Extract';
requires 'Authen::Passphrase::BlowfishCrypt';
requires 'autodie';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Action::REST';
requires 'Catalyst::ActionRole::DetachOnDie';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Devel';
requires 'Catalyst::Controller::DBIC::API';
requires 'Catalyst::Model::Adaptor';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::ErrorCatcher';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Session::Store::Memcached';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Runtime' => '5.90013';
requires 'Catalyst::View::Download';
requires 'Catalyst::View::TT';
requires 'CatalystX::RoleApplicator';
requires 'Config::General' => '2.51';
requires 'Data::Printer';
requires 'Data::Section::Simple';
requires 'DateTime';
requires 'DBD::Pg';
requires 'DBD::SQLite' => '1.27'; # DBIx::Class::Fixtures needs this
requires 'DBIx::Class';
requires 'DBIx::Class::Migration';
requires 'DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase';
requires 'DBIx::Class::PassphraseColumn';
requires 'DBIx::Class::Schema::Loader';
requires 'DBIx::RunSQL';
requires 'File::Spec';
requires 'File::Temp';
requires 'FindBin';
requires 'Getopt::Long';
requires 'JSON';
requires 'JSON::XS';
requires 'List::AllUtils';
requires 'Method::Signatures';
requires 'Module::Pluggable';
requires 'Moo';
requires 'MooX::Types::MooseLike';
requires 'Moose';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::MethodAttributes::Role';
requires 'MooseX::Storage';
requires 'MooseX::Storage::Format::JSONpm';
requires 'namespace::autoclean';
requires 'Params::Validate';
requires 'Path::Class';
requires 'Pod::Usage';
requires 'Regexp::Grammars';
requires 'Spreadsheet::Read';
requires 'Spreadsheet::ParseExcel';
requires 'Spreadsheet::WriteExcel';
requires 'Spreadsheet::XLSX';
requires 'SQL::Translator' => '0.11016';
requires 'Template';
requires 'Throwable::Error' => '0.200003';
requires 'Try::Tiny';


# deploy deps
# Server::Starter => '1.12'
# Starman => '3.003'
# nost sure if this is deploy dep: DBIx::Class::Migration


test_requires 'indirect';
test_requires 'multidimensional';
test_requires 'bareword::filehandles';
test_requires 'CGI::Compile';
test_requires 'CGI::Emulate::PSGI';
test_requires 'HTTP::Request::Common';
test_requires 'Plack';
test_requires 'Pod::Coverage';
test_requires 'Test::DBIx::Class';
test_requires 'Test::More' => '0.88';
test_requires 'Test::Fatal';
test_requires 'Test::Pod';
test_requires 'Test::Pod::Coverage';
test_requires 'Test::postgresql';
test_requires 'Test::WWW::Mechanize::Catalyst';

WriteAll(meta => 0);
