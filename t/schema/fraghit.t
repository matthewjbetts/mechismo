use strict;
use warnings;
use Test::More;

use Fist::Schema;
use Config::General;

my $conf;
my %config;
my $schema;
my $fraghit;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;
eval { $schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password}); };
ok(!$@, 'connected to schema');

eval { $fraghit = $schema->resultset('FragHit')->new_result({}); };
ok(!$@, 'construct fraghit object');

done_testing();
