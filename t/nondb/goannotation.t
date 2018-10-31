use strict;
use warnings;
use Test::More;

use Fist::NonDB::GoAnnotation;

my $goannotation;

eval { $goannotation = Fist::NonDB::GoAnnotation->new(); };
ok(!$@, 'constructed new goannotation object');

done_testing();
