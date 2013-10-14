#!/usr/bin/env perl

use MooX::Types::MooseLike::Base qw(ArrayRef HashRef);

use Test::Roo;
use v5.16;

use lib 't/lib';

with 't::Role::Schema', 't::Role::Mech', 't::Role::WebApp',
    'Judoon::Role::JsonEncoder';

my %users = (
    me  => {
        username => 'me', password => 'mypassword',
        name => 'Me Who I Am', email_address => 'me@example.com',
    },
    you => {
        username => 'you', password => 'yourpassword',
        name => 'You Who You Are', email_address => 'you@example.com',
    },
);

after setup => sub {
    my ($self) = @_;
    $self->load_fixtures('init');

    $self->add_fixture(
        'api' => sub {
            my ($self) = @_;
            my $user_rs = $self->schema()->resultset('User');

            # build fixtures for me user
            my %me = (object => $user_rs->create_user($users{me}));
            my $my_pub_ds
                = $me{object}->import_data_by_filename('t/etc/data/api/me-public.xls')
                    ->update({permission => 'public'});
            my $my_priv_ds
                = $me{object}->import_data_by_filename('t/etc/data/api/me-private.xls');
            $me{public_ds} = {
                object       => $my_pub_ds,
                public_page  => $my_pub_ds->create_basic_page->update({permission => 'public'}),
                private_page => $my_pub_ds->create_basic_page,
            };
            $me{private_ds} = {
                object       => $my_priv_ds,
                public_page  => $my_priv_ds->create_basic_page->update({permission => 'public'}),
                private_page => $my_priv_ds->create_basic_page,
            };

            # build fixtures for you user
            my %you = (object => $user_rs->create_user($users{you}));
            my $you_pub_ds
                = $you{object}->import_data_by_filename('t/etc/data/api/you-public.xls')
                    ->update({permission => 'public'});
            $you{public_ds} = {
                object      => $you_pub_ds,
                public_page => $you_pub_ds->create_basic_page->update({permission => 'public'}),
            };

        }
    );

    $self->load_fixtures('api');
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

