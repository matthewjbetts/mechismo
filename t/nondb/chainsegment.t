use strict;
use warnings;
use Test::More;

use Fist::NonDB::ChainSegment;
use Config::General;

my $segment;

eval { $segment = Fist::NonDB::ChainSegment->new(); };
ok(!$@, 'construct chain_segment object');

done_testing();
