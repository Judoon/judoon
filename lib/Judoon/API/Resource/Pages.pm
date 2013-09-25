package Judoon::API::Resource::Pages;

use Moo;

extends 'Web::Machine::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';

use HTTP::Throwable::Factory qw(http_throw);


sub create_resource {
    my ($self, $data) = @_;

    my $user       = $self->set->related_resultset('dataset')
        ->related_resultset('user')->search({},{distinct => 1})->single;
    my $dataset_id = $data->{dataset_id};
    my $dataset    = $user->datasets_rs->find({id => $dataset_id});
    if (!$dataset) {
        http_throw(Forbidden => {
            message => "You don't have permission to access the given dataset",
        });
    }

    my $type    = delete $data->{type} // '';
    my $new_page;
    if ($type eq 'clone') {
        my $clone_id = $data->{clone_from} or die 'Bad request?';
        my $existing_page = $user->my_pages->find({id => $clone_id})
            or die q{That view doesn't exist!};

        $new_page = $dataset->new_related('pages',{})
            ->clone_from_existing($existing_page);
    }
    elsif ($type eq 'template') {
        my $uploads = $self->req->uploads;
        my $fh = $uploads->{'page.clone_template'}->fh;
        my $page_template = do { local $/ = undef; <$fh>; };
        $new_page = $dataset->new_related('pages',{})
            ->clone_from_dump($page_template);
    }
    else {
        $data->{title}     //= q{New Blank Page};
        $data->{preamble}  //= q{};
        $data->{postamble} //= q{};
        $new_page = $self->set->create($data);
    }

    return $new_page;
}


1;
__END__

=pod

=encoding utf8

=head1 NAME

Judoon::API::Resource::Pages - An set of Pages

=head1 DESCRIPTION

See L</Web::Machine::Resource>.

=head1 METHODS

=head2 create_resource

Clone an existing page if the C<type> parameter equals 'clone'.
Create a new page from the uploaded template if the C<type> parameter
equals 'template'. Otherwise, create a new blank page.

=cut
