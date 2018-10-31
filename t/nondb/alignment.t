use strict;
use warnings;
use Test::More;

use Fist::NonDB::Alignment;
use Fist::NonDB::Seq;
use Fist::NonDB::AlignedSeq;
use Config::General;

my $aln;
my $seq;
my $aseq;
my $apos;
my $pos;

eval { $aln = Fist::NonDB::Alignment->new(); };
ok(!$@, 'construct alignment object');

eval { $seq = Fist::NonDB::Seq->new(id => 1); };
ok(!$@, 'construct seq object');

eval { $aseq = Fist::NonDB::AlignedSeq->new(id_seq => $seq->id, start => 10, _aseq => 'DNPQVANLKSGYIKSLGLGGAMWWDSSSDKTGSDSLITTVVNALGGTGVFEQSQNELDYPVSQYDNLRNGMQ'); };
ok(!$@, 'construct aligned seq object');

$aln->add_to_aligned_seqs($aseq);

for($apos = 1; $apos <= length $aseq->aseq; ++$apos) {
    $pos = $aln->pos_from_apos(1, $apos);
    defined($pos) and last;
}
ok(($pos == $aseq->start), 'mapping correct');

done_testing();
