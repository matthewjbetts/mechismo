use strict;
use warnings;
use Test::More;

use Fist::NonDB::ContactHitResidue;

my $contacthitresidue;

eval { $contacthitresidue = Fist::NonDB::ContactHitResidue->new(); };
ok(!$@, 'constructed contacthitresidue object');

done_testing();
