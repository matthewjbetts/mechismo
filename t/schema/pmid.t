use strict;
use warnings;
use Test::More;

use Fist::Schema;
use Config::General;

my $conf;
my %config;
my $schema;
my $pmid;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;

eval { $schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password}); };
ok(!$@, 'connect to schema');

eval { $pmid = $schema->resultset('Pmid'); };
ok(!$@, 'construct pmid result');

done_testing();
