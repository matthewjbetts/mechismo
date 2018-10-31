use strict;
use warnings;
use Test::More;

use Fist::NonDB::Pmid;

my $seq;

eval { $seq = Fist::NonDB::Pmid->new(); };
ok(!$@, 'constructed pmid object');

print $@;

done_testing();
