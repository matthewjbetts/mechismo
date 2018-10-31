use strict;
use warnings;
use Test::More;

use Fist::NonDB::Hsp;

my $hsp;

eval { $hsp = Fist::NonDB::Hsp->new(); };
ok(!$@, 'constructed hsp object');
#print $pdb->id, "\n";

done_testing();
