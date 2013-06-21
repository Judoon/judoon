package Judoon::Schema::Result::UserRole;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::UserRole

=cut

use Judoon::Schema::Candy;
use Moo;

table 'user_roles';

column user_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
},
column role_id => {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
};

primary_key "user_id", "role_id";

belongs_to role => "::Role",
    { id => "role_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };

belongs_to user => "::User",
    { id => "user_id" },
    { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" };


1;
