use strict;
use warnings;
use Test::More;

use Fist::Utils::Fork;
use Config::General;

my $conf;
my %config;
my $fork;
my $id_pbsjob;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;

eval { $fork = Fist::Utils::Fork->new(); };
ok(!$@, 'constructed PBS object');

ok($fork->create_jobs(name => 'test-ls', dn_out => 't/output', prog => 'ls', input => ['./', "$ENV{DS}"]), 'jobs created');
#ok($fork->create_jobs(name => 'test-wibble', dn_out => 't/output', prog => 'wibble', input => ['']), 'jobs created');
ok($fork->submit, 'submitted jobs');
ok($fork->monitor, 'queue monitored');

done_testing();
