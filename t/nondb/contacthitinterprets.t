use strict;
use warnings;
use Test::More;

use Fist::NonDB::ContactHitInterprets;

my $contacthitinterprets;

eval { $contacthitinterprets = Fist::NonDB::ContactHitInterprets->new(); };
ok(!$@, 'constructed contacthitinterprets object');

done_testing();
