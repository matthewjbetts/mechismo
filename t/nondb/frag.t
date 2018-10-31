use strict;
use warnings;
use Test::More;

use Fist::NonDB::Pdb;
use Fist::NonDB::Frag;

my $pdb;
my $frag;
my @frags;

eval { $pdb = Fist::NonDB::Pdb->new(idcode => '4HHB'); };
ok(!$@, 'constructed pdb object from idCode');
#print $pdb->id, "\n";

eval { $frag = Fist::NonDB::Frag->new(pdb => $pdb, dom => 'ALL'); };
ok(!$@, 'constructed frag object from pdb object');
ok($frag->id, 'id generated');
$pdb->add_to_frags($frag);

eval { $frag = Fist::NonDB::Frag->new(pdb => $pdb, dom => 'CHAIN A'); };
ok(!$@, 'constructed second frag object from pdb object');
$pdb->add_to_frags($frag);

@frags = $pdb->frags;
ok(@frags == 2, '$pdb->frags returned a list of two values');

done_testing();
