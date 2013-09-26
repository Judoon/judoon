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
