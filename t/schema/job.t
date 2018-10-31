use strict;
use warnings;
use Test::More;

use Fist::Schema;
use Config::General;

my $conf;
my %config;
my $schema;
my $job;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;

eval { $schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password}); };
ok(!$@, 'connect to schema');

eval { $job = $schema->resultset('Job')->new_result({id_search => "wibble", type => "long", status => "finished"}); };
ok(!$@, 'construct job object');

eval { $job->insert; };
ok(!$@, 'insert job in to db');

eval { $job->delete; };
ok(!$@, 'delete job from db');

done_testing();
