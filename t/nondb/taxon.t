use strict;
use warnings;
use Test::More;

use Fist::NonDB::Taxon;

my $taxon;

eval { $taxon = Fist::NonDB::Taxon->new(); };
ok(!$@, 'constructed taxon object');

done_testing();
