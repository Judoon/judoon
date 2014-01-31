package Judoon::Web;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader
    Static::Simple
    Authentication
    Authorization::Roles
    CustomErrorMessage
    ErrorCatcher
    Session
    Session::Store::Memcached
    Session::State::Cookie
    StackTrace
/;
use CatalystX::RoleApplicator;

extends 'Catalyst';

use Safe::Isa;

our $VERSION = '0.01';

__PACKAGE__->config(
    name                     => 'Judoon::Web',
    default_view             => 'HTML',
    encoding                 => 'UTF-8',
    abort_chain_on_error_fix => 1,

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

__PACKAGE__->config(
    'View::HTML' => {
        CATALYST_VAR => 'c',
        ENCODING     => 'utf-8',
        INCLUDE_PATH => [
            Judoon::Web->path_to('root', 'src'),
        ],
        TIMER        => 0,
        render_die   => 1,
    },
    'Plugin::Authentication' => {
        default_realm => 'users',
        realms => {
            users => {
                credential => {
                    class          => 'Password',
                    password_field => 'password',
                    password_type  => 'self_check',
                },
                store => {
                    class         => 'DBIx::Class',
                    user_model    => 'User::User',
                    role_relation => 'roles',
                    role_field    => 'name',
                },
            },
            password_reset => {
                credential => {
                    class => 'NoPassword',
                },
                store => {
                    class         => 'DBIx::Class',
                    user_model    => 'User::User',
                    role_relation => 'roles',
                    role_field    => 'name',
                },
            },
            api => {
                credential => {
                    class => 'NoPassword',
                },
                store => {
                    class         => 'DBIx::Class',
                    user_model    => 'User::User',
                    role_relation => 'roles',
                    role_field    => 'name',
                },
            },
        },
    },
    'Plugin::Session' => {
        flash_to_stash => 1,
    },
    'Plugin::ErrorCatcher' => {
        enable             => 0,
        context            => 5,
        always_log         => 1,
        include_session    => 1,
        user_identified_by => 'username',
        emit_module        => 'Judoon::Web::Plugin::ErrorCatcher::Email',
    },
    'Plugin::ErrorCatcher::Email' => {
        to       => 'felliott@virginia.edu',
        from     => 'felliott@virginia.edu',
        subject  => 'Judoon Error Report in %F, line %l',
        use_tags => 1,
    },
    'custom-error-message' => {  # for ::Plugin::CustomErrorMessage
        'uri-for-not-found' => '/',
        'error-template'    => 'error.tt2',
        'content-type'      => 'text/html; charset=utf-8',
        'view-name'         => 'HTML',
        'response-status'   => 500,
    },
);



# Start the application
__PACKAGE__->setup();


=head2 finalize_error

Modify catalyst error output when debug is enabled.  Adds a summary of
the error types.

=cut

after finalize_error => sub {
    my ($c) = @_;

    if ( $c->debug() ) {
        my $err_summary = q{};
        my $cnt = 1;
        for my $error ( @{ $c->error } ) {
            my ($error_type, $error_msg)
                = !blessed($error)                ? ('Plain perl', $error)
                : $error->$_DOES('Judoon::Error') ? (ref($error), $error->message)
                :                                   (ref($error), (split /\n/, "$error")[0]);

            $err_summary .= "$cnt: Error type: $error_type\n    $error_msg\n\n";
            $cnt++;
        }
        $err_summary = qq{<div class="error"><h2>Summary</h2><pre wrap="">$err_summary</pre></div>};

        my $error_html = $c->res->body();
        $error_html =~ s/<div class="box">/<div class="box">$err_summary/;
        $c->res->body($error_html);
    }

};



1;
__END__

=pod

=encoding utf-8

=for stopwords NCBI sortable

=head1 NAME

Judoon::Web - Turn spreadsheets into web pages

=head1 SYNOPSIS

 plackup -Ilib judoon_web.psgi

=head1 DESCRIPTION

Judoon is a web application that converts tabular data in an Excel
spreadsheet into a searchable and sortable table presented on the
World Wide Web. After upload to the Judoon website, spreadsheet data
is immediately displayed; editing commands can be used to reformat the
data columns and add images or links to other web resources, including
NCBI databases and Google.

New data can be pulled in from other spreadsheets or external
databases and presented together.  The finished presentation can then
be downloaded and hosted on the researcher's own website.

=head1 SEE ALSO

L<Judoon::Web::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
