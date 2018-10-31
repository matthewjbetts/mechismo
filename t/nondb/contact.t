use strict;
use warnings;
use Test::More;

use Fist::NonDB::Contact;

my $contact;

eval { $contact = Fist::NonDB::Contact->new(); };
ok(!$@, 'constructed contact object');

done_testing();
