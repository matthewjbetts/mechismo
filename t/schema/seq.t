use strict;
use warnings;
use Test::More;

use Fist::Schema;
use Config::General;

my $conf;
my %config;
my $schema;
my $rs_seq;
my $seq;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;

eval { $schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password}); };
ok(!$@, 'connect to schema');

eval { $rs_seq = $schema->resultset('Seq'); };
ok(!$@, 'construct seq result');

ok(defined($rs_seq->get_column('id')->max), 'get max id');

eval { $seq = $schema->resultset('Seq')->new_result({}); };
ok(!$@, 'construct seq object');

print "$@\n";

done_testing();
