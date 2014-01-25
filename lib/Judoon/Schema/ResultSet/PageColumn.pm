package Judoon::Schema::ResultSet::PageColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::Schema::ResultSet::PageColumn

=cut

use Moo;
use namespace::clean;

extends 'Judoon::Schema::ResultSet';


=head1 METHODS

=head2 for_page( $page )

Filter C<PageColumn>s to those belonging to a particular C<Page>.

=cut

sub for_page {
    my ($self, $page) = @_;
    return $self->search_rs({page_id => $page->id},{order_by => {-asc => 'sort'}});
}


1;

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
