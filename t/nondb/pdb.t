use strict;
use warnings;
use Test::More;

use Fist::NonDB::Pdb;

my $pdb;

eval { $pdb = Fist::NonDB::Pdb->new(idcode => '4HHB'); };
ok(!$@, 'construct pdb object from idCode');
ok($pdb->idcode eq '4hhb', 'idCode converted to lowercase');
ok($pdb->fn, 'get pdb filename from idcode');
ok((-e $pdb->fn), 'named pdb file exists');

done_testing();
