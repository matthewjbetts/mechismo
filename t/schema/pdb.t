use strict;
use warnings;
use Test::More;

use Fist::Schema;
use Config::General;

my $conf;
my %config;
my $schema;
my $pdb;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;
$schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password});

eval { $pdb = $schema->resultset('Pdb')->new_result({idcode => '4HHB'}); };
ok(!$@, 'construct pdb object from idCode');
ok($pdb->idcode eq '4hhb', 'idCode converted to lowercase');
ok($pdb->fn, 'get pdb filename from idcode');
ok((-e $pdb->fn), 'named pdb file exists');

done_testing();
