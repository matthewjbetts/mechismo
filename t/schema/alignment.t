use strict;
use warnings;
use Test::More;

use Fist::Schema;
use Config::General;

my $conf;
my %config;
my $schema;
my $aln;
my $hsp;
my $alnseq;
my $apos;
my $pos;

$conf = Config::General->new('fist.conf');
%config = $conf->getall;
eval { $schema = Fist::Schema->connect($config{"Model::FistDB"}->{connect_info}->{dsn}, $config{"Model::FistDB"}->{connect_info}->{user}, $config{"Model::FistDB"}->{connect_info}->{password}); };
ok(!$@, 'connected to schema');

eval { $aln = $schema->resultset('Alignment')->new_result({}); };
ok(!$@, 'construct alignment object');

eval { $alnseq = $schema->resultset('AlignedSeq')->new_result({}); };
ok(!$@, 'construct aligned seq object');


# hsp that starts at the beginning of the sequence
eval {
    $hsp = $schema->resultset('Hsp')->search({start1 => 1}, {rows => 1})->first;  # FIXME - might not be any hsps in the db when testing
};
ok(!$@, 'extracted hsp from db');

eval { $aln = $hsp->aln; };
ok(!$@, 'extracted alignment from db');

$alnseq = $aln->aseq($hsp->seq1->id);
ok($alnseq, 'got aligned seq');

#print "EDIT_STR = '", $alnseq->edit_str, "'\n";
#print "EDITS    = '", $alnseq->edits, "'\n";
#print "ASEQ     = '", $alnseq->aseq, "'\n";

ok($alnseq->edit_str, 'aligned_seq has edit_str');
ok($alnseq->edits, 'aligned_seq has edits');
ok($alnseq->aseq, 'aligned_seq has aseq');

for($apos = 1; $apos <= length $alnseq->aseq; ++$apos) {
    $pos = $aln->pos_from_apos($alnseq->seq->id, $apos);
    defined($pos) and last;
}
ok(($pos == $hsp->start1), 'mapping correct');



# hsp that doesn't start at the beginning of the sequence
eval {
    $hsp = $schema->resultset('Hsp')->search({start1 => {'>' => 100}}, {rows => 1})->first;  # FIXME - might not be any hsps in the db when testing
};
ok(!$@, 'extracted hsp from db');

eval { $aln = $hsp->aln};
ok(!$@, 'extracted alignment from db');

$alnseq = $aln->aseq($hsp->seq1->id);
ok($alnseq, 'got aligned seq');

for($apos = 1; $apos <= length $alnseq->aseq; ++$apos) {
    $pos = $aln->pos_from_apos($alnseq->seq->id, $apos);
    defined($pos) and last;
}
ok(($pos == $hsp->start1), 'mapping correct');

done_testing();
