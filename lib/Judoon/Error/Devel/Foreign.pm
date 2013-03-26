package Judoon::Error::Devel::Foreign;

use Moo;
extends 'Judoon::Error::Devel';

use MooX::Types::MooseLike::Base qw(Str);

has 'module' => (is => 'ro', isa => Str,);
has 'foreign_message' => (is => 'ro', isa => Str,);

1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::Error::Devel::Foreign - Wrap errors thrown by other modules.

=head1 SYNOPSIS

 use Template;

 my $tt = Template->new(@args)
   or Judoon::Error::Devel::Foreign->throw({
     message         => "unable to create TT object!"
     module          => 'Template',
     foreign_message => Template->error(),
   });

=head1 DESCRIPTION

This error type is for when using an external module that dies with a
known error.

=head1 ATTRIBUTES

=head2 module

Name of the module throwing the error.

=head2 foreign_message

The error message from the module.
