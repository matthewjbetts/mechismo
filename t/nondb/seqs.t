use strict;
use warnings;
use Test::More;

use Fist::NonDB::Seqs;

my $seqs;

eval { $seqs = Fist::NonDB::Seqs->new(); };
ok(!$@, 'constructed seqs object');

done_testing();
