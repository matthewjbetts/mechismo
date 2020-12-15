use strict;
use warnings;
use Test::More;

use File::Temp;
use Config::General;
use Fist::Schema;

my $conf;
my %config;
my $schema;
my $contacthit;
my $frag_a2;
my $seq_a2;
my $tempdir;
my $raw;
my $mean;
my $sd;
my $z;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;
eval { $schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password}); };
ok(!$@, 'connected to schema');

eval { $contacthit = $schema->resultset('ContactHit')->new_result({}); };
ok(!$@, 'construct contacthit object');

$contacthit = $schema->resultset('ContactHit')->search({id => 1})->first;
ok($contacthit, 'got contacthit 1 from db');

$tempdir = File::Temp->newdir(CLEANUP => 0);

$contacthit->cleanup(1);
$contacthit->tempdir($tempdir);

$frag_a2 = $contacthit->contact->frag_inst1->frag;
ok(defined($frag_a2), 'got frag_a2');
$seq_a2 = $frag_a2->run_interprets_fasta;
$seq_a2 = $seq_a2->{$frag_a2->id};
ok(defined($seq_a2), 'got interprets sequence');
#ok(ref $seq_a2 eq 'Fist::NonDB::

($raw, $mean, $sd, $z) = $contacthit->run_interprets(mode => 4, rand => 200);
ok(defined($raw), 'ran interprets');

done_testing();
