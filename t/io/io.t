use strict;
use warnings;
use Test::More;
use Config::General;
use Fist::IO::Test;

my $tester;

eval {$tester = Fist::IO::Test->new({fn => 't/files/pdb4hhb.ent'}); };
ok(!$@, 'File::IO::Test object created');

ok($tester->fh, 'opened uncompressed file');

$tester = Fist::IO::Test->new({fn => 't/files/pdb4hhb.ent.Z'});
ok($tester->fh, 'open compressed file');

$tester = Fist::IO::Test->new({fn => 't/files/pdb4hhb.ent.gz'});
ok($tester->fh, 'open gziped file');

$tester = Fist::IO::Test->new({fn => 't/files/pdb4hhb.ent.bz2'});
ok($tester->fh, 'open bzip2ed file');

done_testing();
