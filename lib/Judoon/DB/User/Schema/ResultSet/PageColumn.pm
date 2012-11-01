package Judoon::DB::User::Schema::ResultSet::PageColumn;

=pod

=encoding utf8

=head1 NAME

Judoon::DB::User::Schema::ResultSet::PageColumn

=head1 DESCRIPTION

Custom ResultSet class for PageColumns

=cut

use Moo;
use feature ':5.10';
extends 'DBIx::Class::ResultSet';

=head1 METHODS

=head2 B<C<for_page( $page )>>

Filter C<PageColumn>s to those belonging to a particular C<Page>.

=cut

sub for_page {
    my ($self, $page) = @_;
    return $self->search_rs({page_id => $page->id},{order_by => {-asc => 'sort'}});
}

1;
__END__
