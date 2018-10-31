use strict;
use warnings;
use Test::More;

use Fist::NonDB::Alias;

my $taxon;

eval { $taxon = Fist::NonDB::Alias->new(); };
ok(!$@, 'constructed alias object');

done_testing();
