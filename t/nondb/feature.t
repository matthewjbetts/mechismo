use strict;
use warnings;
use Test::More;

use Fist::NonDB::Feature;

my $feature;

eval { $feature = Fist::NonDB::Feature->new(); };
ok(!$@, 'constructed feature object');

done_testing();
