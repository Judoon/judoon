package Judoon::Schema::Result::Role;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::Result::Role

=cut

use Judoon::Schema::Candy;

use Moo;
use namespace::clean;


table "roles";

primary_column id => {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
};
unique_column name => {
    data_type   => "text",
    is_nullable => 0,
};



has_many user_roles => "::UserRole",
    { "foreign.role_id" => "self.id" },
    { cascade_copy => 0, cascade_delete => 0 };

many_to_many users => 'user_roles', 'user';


1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
