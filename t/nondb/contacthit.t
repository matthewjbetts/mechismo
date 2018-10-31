use strict;
use warnings;
use Test::More;

use Fist::NonDB::ContactHit;

my $contacthit;

eval { $contacthit = Fist::NonDB::ContactHit->new(); };
ok(!$@, 'constructed contacthit object');

done_testing();
