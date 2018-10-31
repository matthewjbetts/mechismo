use strict;
use warnings;
use Test::More;

use Fist::NonDB::ResResJaccard;

my $resresjaccard;

eval { $resresjaccard = Fist::NonDB::ResResJaccard->new(); };
ok(!$@, 'constructed resresjaccard object');

done_testing();
