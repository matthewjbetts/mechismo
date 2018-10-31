use strict;
use warnings;
use Test::More;

use Fist::NonDB::SeqGroup;

my $seqgroup;

eval { $seqgroup = Fist::NonDB::SeqGroup->new(); };
ok(!$@, 'construct seqgroup object');

done_testing();
