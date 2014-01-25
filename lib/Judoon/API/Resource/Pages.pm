package Judoon::API::Resource::Pages;

use HTTP::Throwable::Factory qw(http_throw);
use Safe::Isa;
use Try::Tiny;


use Moo;
use namespace::clean;

extends 'Judoon::API::Resource';
with 'Judoon::Role::JsonEncoder';
with 'Judoon::API::Resource::Role::Set';

sub allowed_methods {
    return [
        qw(GET HEAD),
        ( $_[0]->writable ) ? (qw(POST)) : ()
    ];
}


sub base_uri { '/api/pages' }

sub create_resource {
    my ($self, $data) = @_;

    my $user = $self->set->related_resultset('dataset')
        ->related_resultset('user')->search({},{distinct => 1})->single;
    my $dataset_id = $data->{dataset_id};
    my $dataset    = $user->datasets_rs->find({id => $dataset_id});
    if (!$dataset) {
        http_throw(NotFound => {
            message => "You don't have a dataset with id: " . $dataset_id,
        });
    }

    my $type = delete $data->{type} // 'blank';
    my $new_page;
    if ($type eq 'clone') {
        my $clone_id = $data->{clone_from};
        unless ($clone_id && $clone_id =~ m/^\d+$/) {
            http_throw(UnprocessableEntity => {
                message => 'No clone specified'
            });
        }

        my $existing_page = $user->my_pages->find({id => $clone_id})
            or http_throw(UnprocessableEntity => {
                message => 'No such clone page',
            });

        try {
            $new_page = $dataset->new_related('pages',{})
                ->clone_from_existing($existing_page);
        }
        catch {
            my $e = $_;

            if ($e->$_DOES('Judoon::Error::Template')) {
                http_throw(UnprocessableEntity => {
                    message => "The page with id: " . $existing_page->id
                        . " is not clonable with this dataset.\nSee:\n" . $e,
                });
            }
            else {
                die $e;
            }
        };
    }
    elsif ($type eq 'basic') {
        $new_page = $dataset->create_basic_page();
    }
    elsif ($type eq 'blank') {
        $data->{title}     //= q{New Blank Page};
        $data->{preamble}  //= q{};
        $data->{postamble} //= q{};
        $new_page = $self->set->create($data);
    }
    else {
        http_throw(UnprocessableEntity => {message => 'No such clone page'});
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

=head1 AUTHOR

Fitz ELLIOTT <felliott@fiskur.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by the Rector and Visitors of the
University of Virginia.

This is free software, licensed under:

 The Artistic License 2.0 (GPL Compatible)

=cut
