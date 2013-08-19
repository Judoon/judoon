package Judoon::Transform::Role::Base;

use Moo::Role;


requires 'result_data_type';
requires 'apply_batch';


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Transform::Role::Base - Common code for Judoon::Transforms

=head1 SYNOPSIS

 package Judoon::Transform::TimesTwo;

 use Moo;
 with 'Judoon::Transform::Role::Base;

 sub result_data_type { CoreType_Numeric }
 sub apply_batch {
   my ($self, $data) = @_;
   return map {$_ * 2} @$data;
 }

=head1 DESCRIPTION

This is our base role for C<Judoon::Transform>s. All C<Transforms>
should consume this role.

=head1 REQUIRED METHODS

=head2 result_data_type

The L<Judoon::Type> of the product of the transform.

=head2 apply_batch

The subroutine that performs the transform.

=cut
