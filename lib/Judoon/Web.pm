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
    ErrorCatcher
    Session
    Session::Store::Memcached
    Session::State::Cookie
    StackTrace
/;
use CatalystX::RoleApplicator;

extends 'Catalyst';

__PACKAGE__->apply_request_class_roles(qw[
    Catalyst::TraitFor::Request::REST::ForBrowsers
]);

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in judoon_web.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'Judoon::Web',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    default_view => 'HTML',
);

__PACKAGE__->config(
    'View::HTML' => {
        CATALYST_VAR => 'c',
        INCLUDE_PATH => [
            Judoon::Web->path_to('root', 'src'),
        ],
        ERROR        => 'error.tt2',
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
        },
    },
    'Plugin::Session' => {
        flash_to_stash => 1,
    },
    'Plugin::Static::Simple' => { dirs => ['static',], },
    'Plugin::ErrorCatcher' => {
        enable             => 1,
        context            => 5,
        always_log         => 1,
        include_session    => 1,
        user_identified_by => 'username',
        emit_module        => 'Catalyst::Plugin::ErrorCatcher::Email',
    },
   'Plugin::ErrorCatcher::Email' => {
       to       => 'felliott@virginia.edu',
       from     => 'felliott@virginia.edu',
       subject  => 'Judoon Error Report in %F, line %l',
       use_tags => 1,
   },
);


# Start the application
__PACKAGE__->setup();


=head1 NAME

Judoon::Web - Catalyst based application

=head1 SYNOPSIS

    script/judoon_web_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Judoon::Web::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Fitz Elliott

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
