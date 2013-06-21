#!/usr/bin/env perl

use Test::Roo;
use v5.16;

use lib 't/lib';

with 't::Role::Schema', 't::Role::Mech', 't::Role::WebApp';

use HTTP::Request::Common qw(GET POST PUT DELETE);
use JSON::MaybeXS;
use Test::JSON;

my ($user_rs, $testuser, $otheruser, $otheruser_tkn,
    $other_ds_rs, $test_ds_rs, $access_token);


after setup => sub {
    my ($self) = @_;
    $self->load_fixtures('basic');

    my $otheruser = $self->resultset('User')->create_user({
        username => 'otheruser', password => 'otheruser',
        name => 'Other User', email_address => 'otheruser@example.com',
    });

    # public dataset/page
    my $dataset = $otheruser->import_data_by_filename('t/etc/data/basic.xls');
    $dataset->permission('public');
    $dataset->update();
    my $page = $dataset->create_basic_page();
    $page->permission('public');
    $page->update();

    # private dataset/page
    $otheruser->import_data_by_filename('t/etc/data/basic.xls')
        ->create_basic_page();

    $user_rs     = $self->schema->resultset('User');
    $testuser    = $user_rs->find({username => 'testuser'});
    $otheruser   = $user_rs->find({username => 'otheruser'});
    $other_ds_rs = $otheruser->datasets_rs;
    $test_ds_rs  = $testuser->datasets_rs;

    $otheruser_tkn = $otheruser->new_or_refresh_access_token->value;
    $access_token  = "?access_token=$otheruser_tkn";

};
#after each_test => sub { $_[0]->reset_fixtures(); };


test 'dataset' => sub {
    my ($self) = @_;

    my %datasets = (
        public     => { obj => $other_ds_rs->public->first,  },
        private    => { obj => $other_ds_rs->private->first, },
        restricted => { obj => $test_ds_rs->private->first,  },
    );

    for my $ds (values %datasets) {
        my $obj     = $ds->{obj};
        $ds->{id}   = $obj->id;
        $ds->{url}  = "/api/dataset/" . $ds->{id};
        $ds->{json} = $obj->TO_JSON;
    }

    $self->_access_control_ok(@datasets{qw(public private restricted)});
};


test 'dataset column' => sub {
    my ($self) = @_;

    my %ds_cols = (
        public     => { obj => $other_ds_rs->public->first->ds_columns_ordered->first,  },
        private    => { obj => $other_ds_rs->private->first->ds_columns_ordered->first, },
        restricted => { obj => $test_ds_rs->private->first->ds_columns_ordered->first,  },
    );
    for my $ds_col (values %ds_cols) {
        my $obj     = $ds_col->{obj};
        $ds_col->{id}   = $obj->id;
        $ds_col->{url}  = "/api/dataset/" . $obj->dataset->id . "/column/" . $ds_col->{id};
        $ds_col->{json} = $obj->TO_JSON;
    }

    $self->_access_control_ok(@ds_cols{qw(public private restricted)});
};


test 'page' => sub {
    my ($self) = @_;

    my %pages = (
        public     => { obj => $other_ds_rs->related_resultset('pages')->public->first,  },
        private    => { obj => $other_ds_rs->related_resultset('pages')->private->first, },
        restricted => { obj => $test_ds_rs->related_resultset('pages')->private->first,  },
    );

    for my $page (values %pages) {
        my $obj       = $page->{obj};
        $page->{id}   = $obj->id;
        $page->{url}  = "/api/page/" . $page->{id};
        $page->{json} = $obj->TO_JSON,
    }

    $self->_access_control_ok(@pages{qw(public private restricted)});

    my $private = $pages{private};
    subtest 'new page' => sub {
        my $new_page = {
            dataset_id => 0+$private->{obj}->dataset->id,
            title     => "New POSTed Page",
            preamble  => "This is how it starts.",
            postamble => "...how it ends is up to you.",
        };
        $self->_POST_json("/api/page/" . $access_token, $new_page);
        ok($self->mech->success, "succesfully POSTed new page");
        my $new_url = $self->mech->res->headers->header('Location');
        $self->_GET_json($new_url);
        my $expected = {
            %$new_page, permission => 'private', columns => [], nbr_columns => 0,
            nbr_rows => 0+$private->{obj}->dataset->nbr_rows,
            dataset_id => 0+$private->{obj}->dataset->id,
            id => 0+($new_url =~ s{.+/}{}r),
        };
        my $got = decode_json($self->mech->content);
        delete @{$got}{qw(created modified)};
        is_deeply $got, $expected, ' ..new page has expected contents';

        my $update = { %$expected };
        $update->{title} = "Brand New Title";
        delete @{ $update }{qw(nbr_columns nbr_rows columns)};
        $self->_PUT_json($new_url, $update);
        ok($self->mech->success, 'successfully PUTed update');
        $self->_GET_json($new_url);
        my $got_put = decode_json($self->mech->content);
        delete @{$got_put}{qw(created modified)};
        is_deeply $got_put, {%$expected, title=>$update->{title}},
            '  ..new page has expected contents';

        $self->_DELETE_json($new_url);
        ok($self->mech->success, 'successfully DELETEd page');
        $self->_GET_json($new_url);
        is $self->mech->status, 404, "  ...yep, it's gone!";
    };


};


test 'page column' => sub {
    my ($self) = @_;

    my %page_cols = (
        public     => { obj => $other_ds_rs->related_resultset('pages')->public->first->page_columns_ordered->first,  },
        private    => { obj => $other_ds_rs->related_resultset('pages')->private->first->page_columns_ordered->first, },
        restricted => { obj => $test_ds_rs->related_resultset('pages')->private->first->page_columns_ordered->first,  },
    );
    for my $page_col (values %page_cols) {
        my $obj           = $page_col->{obj};
        $page_col->{id}   = $obj->id;
        $page_col->{url}  = "/api/page/" . $obj->page->id . "/column/" . $page_col->{id};
        $page_col->{json} = $obj->TO_JSON;
    }

    $self->_access_control_ok(@page_cols{qw(public private restricted)});
};


after teardown => sub {
    my ($self) = @_;
    $self->schema->storage->disconnect;
};


run_me();
done_testing();


# utility functions


sub _get_json_ok {
    my ($self, $url, $object_json, $descr) = @_;

    $self->_GET_json($url);
    ok($self->mech->success, $descr,);
    my $response = $self->mech->content;
    is_valid_json($response, q{  ...and it's valid json});
    is_json($response, encode_json($object_json),
            q{  ...and it matches what we expect});
}

sub _not_found_ok {
    my ($self, $url, $descr) = @_;
    my $r = GET($url, 'Accept' => 'application/json');
    $self->mech->request($r);
    is $self->mech->status, 404, $descr;
}


sub _GET_json {
    my ($self, $url) = @_;
    my $r = GET($url, 'Accept' => 'application/json');
    $self->mech->request($r);
}

sub _POST_json {
    my ($self, $url, $object) = @_;
    my $r = POST(
        $url, 'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        Content => encode_json($object),
    );
    $self->mech->request($r);
}

sub _PUT_json {
    my ($self, $url, $object) = @_;
    my $r = PUT(
        $url, 'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        Content => encode_json($object),
    );
    $self->mech->request($r);
}

sub _DELETE_json {
    my ($self, $url) = @_;
    my $r = DELETE($url, 'Accept' => 'application/json',);
    $self->mech->request($r);
}


sub _access_control_ok {
    my ($self, $public, $private, $restricted) = @_;

    subtest 'no auth' => sub {
        $self->logout();
        $self->_get_json_ok($public->{url}, $public->{json}, 'can GET public object',);
        $self->_not_found_ok($private->{url}, 'forbidden for private url');
        $self->_not_found_ok($restricted->{url}, 'forbidden for restricted url'),
    };

    subtest 'with login' => sub {
        $self->login(qw(otheruser otheruser));
        $self->_get_json_ok($public->{url}, $public->{json}, 'can GET public object',);
        $self->_get_json_ok($private->{url}, $private->{json}, 'can GET private object');
        $self->_not_found_ok($restricted->{url}, 'forbidden for restricted url');
        $self->logout();
    };

    subtest 'with access token' => sub {
        $self->_get_json_ok($public->{url} . $access_token, $public->{json}, 'can GET public object',);
        $self->_get_json_ok($private->{url} . $access_token, $private->{json}, 'can GET private object');
        $self->_not_found_ok($restricted->{url} . $access_token, 'forbidden for restricted url');
    };

    subtest 'login takes priority' => sub {
        $self->logout;
        $self->login(qw(testuser), $self->testuser->{password});
        $self->_get_json_ok($public->{url} . $access_token, $public->{json}, 'can GET public object',);
        $self->_not_found_ok($private->{url} . $access_token, 'forbidden for private url');
        $self->_get_json_ok($restricted->{url} . $access_token, $restricted->{json}, 'can GET testuser object');
        $self->logout();
    };

}
