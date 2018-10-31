use strict;
use warnings;
use Test::More;

use Fist::NonDB::FeatureInstContact;

my $featureinstcontact;

eval { $featureinstcontact = Fist::NonDB::FeatureInstContact->new(); };
ok(!$@, 'constructed featureinstcontact object');

done_testing();
