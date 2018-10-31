use strict;
use warnings;
use Test::More;
use Fist::Utils::Jaccard;

my $set1;
my $set2;
my $set3;
my $jaccard;

# lists as input
$set1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
$set2 = [1, 2, 3, 4, 5];
$set3 = [8, 9, 10];

$jaccard = Fist::Utils::Jaccard::calc($set1, $set1);
ok($jaccard == 1.0, 'list jaccard == 1.0');

$jaccard = Fist::Utils::Jaccard::calc($set1, $set2);
ok($jaccard == 0.5, 'list jaccard == 0.5');

$jaccard = Fist::Utils::Jaccard::calc($set1, $set3);
ok($jaccard == 0.3, 'list jaccard == 0.3');

$jaccard = Fist::Utils::Jaccard::calc($set2, $set3);
ok($jaccard == 0.0, 'list jaccard == 0.0');

# hashes as input
$set1 = {A => 1, B => 1, C => 1, D => 1, E => 1, F => 1, G => 1, H => 1, I => 1, J => 1};
$set2 = {A => 1, B => 1, C => 1, D => 1, E => 1};
$set3 = {H => 1, I => 1, J => 1};

$jaccard = Fist::Utils::Jaccard::calc($set1, $set1);
ok($jaccard == 1.0, 'hash jaccard == 1.0');

$jaccard = Fist::Utils::Jaccard::calc($set1, $set2);
ok($jaccard == 0.5, 'hash jaccard == 0.5');

$jaccard = Fist::Utils::Jaccard::calc($set1, $set3);
ok($jaccard == 0.3, 'hash jaccard == 0.3');

$jaccard = Fist::Utils::Jaccard::calc($set2, $set3);
ok($jaccard == 0.0, 'hash jaccard == 0.0');

# lists with repeats
$set1 = [1, 2, 3, 4, 5, 5, 5, 5, 6, 7, 7, 7, 7, 7, 8, 9, 10];
$set2 = [1, 1, 1, 1, 2, 3, 4, 5];
$set3 = [8, 8, 8, 9, 9, 10];

$jaccard = Fist::Utils::Jaccard::calc($set1, $set1);
ok($jaccard == 1.0, 'repeat jaccard == 1.0');

$jaccard = Fist::Utils::Jaccard::calc($set1, $set2);
ok($jaccard == 0.5, 'repeat jaccard == 0.5');

$jaccard = Fist::Utils::Jaccard::calc($set1, $set3);
ok($jaccard == 0.3, 'repeat jaccard == 0.3');

$jaccard = Fist::Utils::Jaccard::calc($set2, $set3);
ok($jaccard == 0.0, 'repeat jaccard == 0.0');

done_testing();
