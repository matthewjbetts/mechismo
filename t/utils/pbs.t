use strict;
use warnings;
use Test::More skip_all => 'PBS jobs currently unsupported';

use Fist::Utils::PBS;
use Config::General;

my $conf;
my %config;
my $pbs;
my $id_pbsjob;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;

eval { $pbs = Fist::Utils::PBS->new(host => $config{pbshost}); };
ok(!$@, 'constructed PBS object');

$pbs->connect();
ok($pbs->ssh, ('connected to PBS host ' . $pbs->host));

ok($pbs->create_jobs(name => 'test-ls', dn_out => 't/output', prog => 'ls', input => ['./', "$ENV{DS}"]), 'jobs created');
ok($pbs->create_jobs(name => 'test-wibble', dn_out => 't/output', prog => 'wibble', input => ['']), 'jobs created');
ok($pbs->submit, 'submitted jobs');
ok($pbs->monitor, 'queue monitored');

done_testing();
