use strict;
use warnings;
use Test::More;

use Fist::NonDB::FeatureContact;

my $featurecontact;

eval { $featurecontact = Fist::NonDB::FeatureContact->new(); };
ok(!$@, 'constructed featurecontact object');

done_testing();
