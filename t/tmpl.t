#/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Judoon::Tmpl;

{
    my $tmpl;
    ok !exception { $tmpl = Judoon::Tmpl->new },
        'Can create a new empty Judoon::Tmpl';
    is_deeply $tmpl->nodes, [], 'initial nodelist is empty';
}

{
    my $tmpl = Judoon::Tmpl->new_from_jstmpl('foo{{=bar}}baz');
    ok my @nodes = $tmpl->get_nodes, 'can get nodes';
    is scalar(@nodes), 3, 'node count is correct';
    is $tmpl->node_count, '3', '...and node_count agrees';
    is_deeply [$tmpl->node_types], [qw(text variable text)],
        'correct node types';

    is $nodes[0]->value, 'foo', 'first node has correct value';
    is $nodes[1]->name,  'bar', 'second node has correct name';
    is $nodes[2]->value, 'baz', 'third node has correct value';


    is_deeply [$tmpl->get_variables], ['bar'], 'returns correct variables';
    is $tmpl->to_jstmpl, 'foo{{=bar}}baz', 'produces correct js template';
    like $tmpl->to_native, qr/CLASS/i, 'can get serialized';

}


done_testing();
