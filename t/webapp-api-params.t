#!/usr/bin/env perl

use MooX::Types::MooseLike::Base qw(ArrayRef HashRef);

use Test::Roo;
use v5.16;

use lib 't/lib';

with 't::Role::Schema', 't::Role::Mech', 't::Role::WebApp', 't::Role::API',
    'Judoon::Role::JsonEncoder';

use Clone qw(clone);

after setup => sub {
    my ($self) = @_;
    $self->load_fixtures(qw(init api));
};


# PUT  /user
# POST /user/datasets
# POST /user/pages
test '/user' => sub {
    my ($self) = @_;
    my $user_rs     = $self->schema->resultset('User');

  TODO: {
        local $TODO = 'Tests not yet written';
        fail('PUT /user');
        fail('POST /user/datasets');
        fail('POST /user/pages');
    }
};



# PUT    /datasets/$ds_id
# DELETE /datasets/$ds_id
# POST   /datasets/$ds_id/columns
# PUT    /datasets/$ds_id/columns/$dscol_id
test '/datasets' => sub {
    my ($self) = @_;

  TODO: {
        local $TODO = 'Tests not yet written';
        fail('PUT    /datasets/$ds_id');
        fail('DELETE /datasets/$ds_id');
        fail('POST   /datasets/$ds_id/columns');
        fail('PUT    /datasets/$ds_id/columns/$dscol_id');

    }
};



# PUT    /pages/$page_id
# DELETE /pages/$page_id
# POST   /pages/$page_id/columns
# DELETE /pages/$page_id/columns
# PUT    /pages/$page_id/columns/$dscol_id
# DELETE /pages/$page_id/columns/$dscol_id
test '/pages' => sub {
    my ($self) = @_;

  TODO: {
        local $TODO = 'Tests not yet written';
        fail('PUT    /pages/$page_id');
        fail('DELETE /pages/$page_id');
        fail('POST   /pages/$page_id/columns');
        fail('DELETE /pages/$page_id/columns');
        fail('PUT    /pages/$page_id/columns/$dscol_id');
        fail('DELETE /pages/$page_id/columns/$dscol_id');
    }
};


# POST /template
test '/services' => sub {
    my ($self) = @_;

  TODO: {
        local $TODO = 'Tests not yet written';
        fail('/template');
    }
};


run_me();
done_testing();

