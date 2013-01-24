#/usr/bin/env perl

use strict;
use warnings;

use lib q{t/lib};

use Test::More;
use Test::Fatal;

use Test::DBIx::Class {
    schema_class => 't::DBIC::Components::Schema',
};


fixtures_ok [
    UsState => [
        [qw/name state_abbr/],
        [qw(Maryland MD)],
        [qw(California CA)],
        [qw(Vermont VT)],
    ],
    SportType => [
        [qw/type/],
        map {[$_]} ('american football', 'baseball', 'pigeon-taunting')
    ],
    UsSportsTeam => [
        [qw/name/],
        ['Baltimore Orioles',    ],
        ['Baltimore Ravens',     ],
        ['San Francisco Giants', ],
        ['San Francisco 49ers',  ],
        ['Annapolis Poultry-Slanderers',],
        ['Burlington Squabmockers',],
    ],

], 'installed fixtures for Lookup Helpers';

my $team_rs           = ResultSet('UsSportsTeam');
my $lookup_failure_re = qr{not found in lookup relationship};

subtest 'lookup_proxy accessors' => sub {

    ok my $squabmockers = $team_rs->find({name => 'Burlington Squabmockers'}),
        'Go Squabmockers!';

    is $squabmockers->sport_type, undef, '  ...sport_type not yet set, returns undef';
    is $squabmockers->state_name, undef, '  ...state_name not yet set, returns undef';
    is $squabmockers->state_abbr, undef, '  ...state_abbr not yet set, returns undef';

    pass '  Time to set the sport:';
    like exception {
        $squabmockers->sport_type('goose-punching');
    }, $lookup_failure_re, '    ..."goose-punching" is not a valid sport';
    ok !exception {
        $squabmockers->sport_type('pigeon-taunting');
    }, '    ...but "pigeon-taunting" is';
    is $squabmockers->sport_type, 'pigeon-taunting',
        '     ...and our row object has the right value';

    pass '  Time to set the state by name:';
    like exception {
        $squabmockers->state_name('Drugachusetts');
    }, $lookup_failure_re, q{    ..."Drugachusetts" is not a real state name};
    ok !exception {
        $squabmockers->state_name('Vermont');
    }, '    ...but "Vermont" is';
    is $squabmockers->state_name, 'Vermont',
        '     ...and our row object has the right state name';
    is $squabmockers->state_abbr, 'VT',
        '     ...and our row object has the right state abbr';

    pass '  The Squabmockers are moving to Maryland?!?!';
    like exception {
        $squabmockers->state_abbr('WTF');
    }, $lookup_failure_re, q{    ..."WTF" is not a real state abbr};
    ok !exception {
        $squabmockers->state_abbr('MD');
    }, '    ...but "MD" is';
    is $squabmockers->state_abbr, 'MD',
        '     ...and our row object has the right state abbrev';
    is $squabmockers->state_name, 'Maryland',
        '     ...and our row object has the right state abbrev';

    pass '  Nope, the deal fell through!';
    my $vermont_obj = ResultSet('UsState')->find({name => 'Vermont'});
    ok !exception {
        $squabmockers->set_from_related('resident_state_rel', $vermont_obj);
    }, '    ...can set related obj state the traditional way (set_from_related)';


    ok !exception { $squabmockers->update; }, '  Saving to the db';

    ok my $sm_audit = $team_rs->find({name => 'Burlington Squabmockers'}),
        'Auditing the Squabmockers...';
    is $sm_audit->sport_type, 'pigeon-taunting', '  ...right sport';
    is $sm_audit->state_name, 'Vermont', '  ...right state name';
    is $sm_audit->state_abbr, 'VT', '  ...right state abbreviation';

};


subtest '$resultset->update' => sub {

    ok my $maryland_rs = $team_rs->search_rs({name => {like => 'Baltimore%'}}),
        'Updating our Baltimore, Maryland teams';
    is_deeply [map {$_->state_abbr} $maryland_rs->all], [undef, undef],
        '  ...state lookups are not yet set';
    like exception {
        $maryland_rs->update({state_name => 'Queensland'});
    }, $lookup_failure_re, '  ...$rs->update() dies on bad lookup';
    ok !exception {
        $maryland_rs->update({state_name => 'Maryland'});
    }, '   ...$rs->update() lives on valid lookup';
    is_deeply [map {$_->state_abbr} $maryland_rs->all], [qw(MD MD)],
        '    ...and all are set correctly.';

    ok !exception {
        $maryland_rs->update({owner => 'Proposition Joe'});
    }, '  ...no trouble setting non-lookup fields';
    is_deeply [map {$_->owner} $maryland_rs->all],
        ['Proposition Joe', 'Proposition Joe',],
            '    ...and non-lookup fields are set correctly.';
};


subtest '$resultset->update_all' => sub {
    ok my $california_rs = $team_rs->search_rs({name => {like => 'San Francisco%'}}),
        'Updating our San Francisco, California teams';
    is_deeply [map {$_->state_abbr} $california_rs->all], [undef, undef],
        '  ...state lookups are not yet set';
    like exception {
        $california_rs->update_all({state_abbr => 'WTF'});
    }, $lookup_failure_re, '  ...$rs->update_all() dies on bad lookup';
    ok !exception {
        $california_rs->update_all({state_abbr => 'CA'});
    }, '  ...$rs->update_all lives on valid lookup';
    is_deeply [map {$_->state_abbr} $california_rs->all], [qw(CA CA)],
        '    ...and all are set correctly.';

    ok !exception {
        $california_rs->update_all({owner => 'Emperor Norton'});
    }, '  ...no trouble setting non-lookup fields via ->update_all()';
    is_deeply [map {$_->owner} $california_rs->all],
        ['Emperor Norton', 'Emperor Norton',],
            '    ...and non-lookup fields are set correctly.';
};


subtest '$resultset->new_result' => sub {
    pass('Adding a new team, the Bakersfield Cattlepunchers');
    my %new_team = (
        name       => 'Bakersfield Cattlepunchers',
        owner      => 'Merle Haggard',
        sport_type => 'american football',
    );
    like exception {
        $team_rs->new_result({ %new_team, state_abbr => 'WTF', });
    }, $lookup_failure_re, '  ...$rs->new_result dies on bad lookup';

    my $bakersfield_obj;
    ok !exception {
        $bakersfield_obj = $team_rs->new_result({ %new_team, });
    }, '   ...$rs->new_result() succeeds w/ good lookup';
    is $bakersfield_obj->sport_type, 'american football',
        '    ...sport_type correctly set';
    is $bakersfield_obj->state_abbr, undef,
        '    ...state_abbr correctly not set';
    ok !exception {
        $bakersfield_obj->insert;
    }, '  ...Cattlepunchers are inserted into the db';


    ok my $bcp_audit = $team_rs->search_rs({owner => 'Merle Haggard'})->first,
        'Auditing the Cattlepunchers';
    is_deeply [map {$bcp_audit->$_()} (sort keys %new_team), qw(state_name state_abbr)],
        [(@new_team{ sort keys %new_team }), undef, undef],
            q{  ...yep, they're legit};
};


subtest '$row->update' => sub {

    ok my $annapolis_obj = $team_rs->search_rs({name => {like => '%Poultry%'}})->first,
        'Managing the Annapolis Poultry-Slanders';
    is $annapolis_obj->state_name, undef, '  ..state name not yet set';
    my %team_attrs = (
        sport_type => 'pigeon-taunting',
        state_name => 'Maryland',
        owner      => 'Proposition Joe',
    );

    like exception {
        $annapolis_obj->update({ %team_attrs, state_name => 'Queensland', });
    }, $lookup_failure_re, '  ...$row->update() dies on bad lookup';
    is_deeply [map {$annapolis_obj->$_()} sort keys %team_attrs],
        [undef, undef, undef], '    ...and nothing got set on failure';

    ok !exception {
        $annapolis_obj->update(\%team_attrs);
    }, '  ...can set lookups & regular fields via $row->update()';
    is_deeply [map {$annapolis_obj->$_()} sort keys %team_attrs],
        [ @team_attrs{sort keys %team_attrs} ],
            '    ...and everything is set correctly';
    is $annapolis_obj->state_abbr, 'MD', '    ...and lookup has correct value';

    ok !exception { $annapolis_obj->update }, '  ...updating in database';

    ok my $aps_audit = $team_rs->search_rs({name => {like => '%Poultry%'}})->first,
        'Auditing Annapolis';
    is_deeply [map {$annapolis_obj->$_()} qw(owner sport_type state_name state_abbr)],
        ['Proposition Joe', 'pigeon-taunting', 'Maryland', 'MD'],
            '   ...looks good, all data as expected';
};



fixtures_ok [
    Genre => [
        [qw/genre/],
        map {[$_]} ('metal', 'rock', 'pop')
    ],

    CD => [
        [qw/artist title/],
        ['High on Fire', 'Snakes for the Divine',],
    ],

], 'installed CD / Genre fixtures';


my $cd_rs       = ResultSet('CD');
my $metal_genre = ResultSet('Genre')->find({genre => 'metal'});


subtest 'lookup_proxy w/o ResultSet Helper' => sub {
    ok my $cd = $cd_rs->find({title => 'Snakes for the Divine'}),
        'Setting genre for CD';
    $cd->set_from_related('genre_rel', $metal_genre);
    $cd->update;

    is $cd->genre, 'metal', '  ...lookup_proxy accessor works';
    like exception {
        $cd->genre('classical');
    }, $lookup_failure_re, '  ...lookup_proxy settor dies on bad lookup';
    ok !exception {
        $cd->genre('rock'); $cd->update;
    }, '  ...can set valid genre via lookup_proxy';

    ok !exception {
        $cd->update({title => 'Snakes for the Divine (2010)'});
    }, '  ...regular update works without Helper::RS::Lookup';
    like exception {
        $cd->update({genre => 'metal'});
    }, qr/No such column 'genre'/,
        '  ...but update with lookup field does not';
    ok !exception {
        $cd->update({ genre_rel => $metal_genre });
    }, '  ...->update({rel_name => $rel_obj}) still works, though';

    ok my $cd_audit = $cd_rs->find({title => 'Snakes for the Divine (2010)'}),
        'Double-checking our cd';
    is $cd_audit->genre, 'metal', '  ...yep, right genre';
};


done_testing;
