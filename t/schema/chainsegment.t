use strict;
use warnings;
use Test::More;

use Fist::Schema;
use Config::General;

my $conf;
my %config;
my $schema;
my $segment;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;
$schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password});

eval { $segment = $schema->resultset('ChainSegment')->new_result({chain => 'A'}); };
ok(!$@, 'construct segment1 object');

done_testing();
