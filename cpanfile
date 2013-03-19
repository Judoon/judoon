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
requires 'Catalyst::Plugin::CustomErrorMessage';
requires 'Catalyst::Plugin::ErrorCatcher';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Session::Store::Memcached';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::Runtime' => '5.90013';
requires 'Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack';
requires 'Catalyst::View::TT';
requires 'CatalystX::RoleApplicator';
requires 'Config::General' => '2.51';
requires 'Data::UUID';
requires 'Data::Printer';
requires 'Data::Section::Simple';
requires 'Data::Visitor::Callback';
requires 'DateTime';
requires 'DBD::Pg';
requires 'DBD::SQLite' => '1.27'; # DBIx::Class::Fixtures needs this
requires 'DBIx::Class';
requires 'DBIx::Class::Candy';
requires 'DBIx::Class::Candy::Exports';
requires 'DBIx::Class::Helpers';
requires 'DBIx::Class::Migration';
requires 'DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase';
requires 'DBIx::Class::PassphraseColumn';
requires 'DBIx::Class::Schema::Loader';
requires 'DBIx::Class::TimeStamp';
requires 'DBIx::RunSQL';
requires 'Excel::Writer::XLSX';
requires 'File::Spec';
requires 'File::Temp';
requires 'FindBin';
requires 'FileHandle';
requires 'Getopt::Long';
requires 'HTML::TreeBuilder';
requires 'IO::File';
requires 'JSON';
requires 'JSON::XS';
requires 'List::AllUtils';
requires 'Module::Pluggable';
requires 'Module::Versions';
requires 'Moo';
requires 'MooX::Types::MooseLike';
requires 'Moose';
requires 'MooseX::MarkAsMethods';
requires 'MooseX::MethodAttributes::Role';
requires 'MooseX::NonMoose';
requires 'MooseX::Storage';
requires 'namespace::autoclean';
requires 'Params::Validate';
requires 'Path::Class';
requires 'Plack::Middleware::Debug';
requires 'Plack::Middleware::Debug::DBIC::QueryLog';
requires 'Pod::Usage';
requires 'Regexp::Common';
requires 'Safe::Isa';
requires 'Scalar::Util';
requires 'Spreadsheet::ParseExcel';
requires 'Spreadsheet::WriteExcel';
requires 'Sub::Name';
requires 'Template';
requires 'Text::CSV::Encoded';
requires 'Text::Unidecode';
requires 'Throwable::Error' => '0.200003';
requires 'Try::Tiny';

# Excel::Reader::XLSX deps
requires 'Archive::Zip';
requires 'OLE::Storage_Lite';
requires 'XML::LibXML';


# deployment deps
requires 'Net::Server::SS::PreFork';
requires 'Server::Starter' => '0.12';
requires 'Starman' => '0.3003';


on 'test' => sub {
    requires 'indirect';
    requires 'multidimensional';
    requires 'bareword::filehandles';
    requires 'CGI::Compile';
    requires 'CGI::Emulate::PSGI';
    requires 'HTTP::Request::Common';
    requires 'Plack';
    requires 'Pod::Coverage';
    requires 'Test::DBIx::Class';
    requires 'Test::Differences';
    requires 'Test::More' => '0.88';
    requires 'Test::Fatal';
    requires 'Test::JSON';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::postgresql';
    requires 'Test::WWW::Mechanize::Catalyst';
};


on 'develop' => sub {
   recommends 'Devel::NYTProf';
};