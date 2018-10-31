use strict;
use warnings;
use Test::More;

use Config::General;

my $conf = Config::General->new('fist.conf');
ok($conf, 'config loaded');

my %config = $conf->getall;
ok($config{'Model::FistDB'}->{connect_info}->{dsn}, 'dsn in config');
ok($config{'Model::FistDB'}->{connect_info}->{user}, 'db user in config');

done_testing();
