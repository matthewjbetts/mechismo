use strict;
use warnings;
use Test::More;

use Fist::NonDB::FeatureInst;

my $featureinst;

eval { $featureinst = Fist::NonDB::FeatureInst->new(); };
ok(!$@, 'constructed featureinst object');

done_testing();
