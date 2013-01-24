package t::DBIC::Components::Schema::UsSportsTeam;

use t::DBIC::Components::Schema::Candy;

table 'us_sports_teams';

primary_column 'id' => serial_integer;
text_column 'name';
column 'owner' => { data_type => text, is_nullable => 1};
foreign_key_column 'sport_type_id';
foreign_key_column 'resident_state_id';


belongs_to(
    sport_type_rel => '::SportType',
    {id => 'sport_type_id',},
    {
        join_type => 'left',
        lookup_proxy => {sport_type => 'type'},
    },
);

belongs_to(
    resident_state_rel => '::UsState',
    {id => 'resident_state_id',},
    {
        join_type => 'left',
        lookup_proxy => [ # ooh, complicated
            {state_name => 'name'},
            'state_abbr',
        ],
    },
);

resultset_class( 't::DBIC::Components::Schema::BaseResultSet' );


1;
__END__
