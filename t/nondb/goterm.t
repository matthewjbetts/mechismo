use strict;
use warnings;
use Test::More;

use Fist::NonDB::GoTerm;

my $goterm;

eval { $goterm = Fist::NonDB::GoTerm->new(); };
ok(!$@, 'constructed new goterm object');

done_testing();
