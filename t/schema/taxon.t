use strict;
use warnings;
use Test::More;

use Fist::Schema;
use Config::General;

my $conf;
my %config;
my $schema;
my $taxon;
my @children;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;
eval { $schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password}); };
ok(!$@, 'connected to schema');

eval { $taxon = $schema->resultset('Taxon')->new_result({}); };
ok(!$@, 'construct taxon object');

eval { $taxon = $schema->resultset('Taxon')->search({id => 4932})->first; };
ok(!$@, 'taxon 4932 retrieved');

@children = $taxon->child_ids;
ok(@children > 70, 'child ids of taxon 4932 retrieved');

done_testing();
