use strict;
use warnings;
use Test::More;

use Fist::NonDB::ResContact;

my $rescontact;

eval { $rescontact = Fist::NonDB::ResContact->new(); };
ok(!$@, 'constructed rescontact object');

done_testing();
