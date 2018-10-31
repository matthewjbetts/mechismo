use strict;
use warnings;
use Test::More;

use Fist::NonDB::Seq;
use Fist::NonDB::Feature;

my $seq;
my $feature;
my @feature_insts;
my $feature_inst;

eval {
    $feature = Fist::NonDB::Feature->new(
                                         source      => 'iupred',
                                         ac_src      => 'long',
                                         description => 'iupred long disorder over a sliding window of size 11',
                                        );
};
ok(!$@, 'constructed iupred long feature object');

eval {
    # UniProt P04637, Human P53
    $seq = Fist::NonDB::Seq->new(seq => 'MEEPQSDPSVEPPLSQETFSDLWKLLPENNVLSPLPSQAMDDLMLSPDDIEQWFTEDPGPDEAPRMPEAAPPVAPAPAAPTPAAPAPAPSWPLSSSVPSQKTYQGSYGFRLGFLHSGTAKSVTCTYSPALNKMFCQLAKTCPVQLWVDSTPPPGTRVRAMAIYKQSQHMTEVVRRCPHHERCSDSDGLAPPQHLIRVEGNLRVEYLDDRNTFRHSVVVPYEPPEVGSDCTTIHYNYMCNSSCMGGMNRRPILTIITLEDSSGNLLGRNSFEVRVCACPGRDRRTEEENLRKKGEPHHELPPGSTKRALPNNTSSSPQPKKKPLDGEYFTLQIRGRERFEMFRELNEALELKDAQAGKEPGGSRAHSSHLKSKKGQSTSRHKKLMFKTEGPDSD');
};
ok(!$@, 'constructed seq object for P04637');
print $@;

@feature_insts = $seq->run_iupred(feature => $feature);
ok((@feature_insts == 3), 'iupred found three unstructured regions');

eval {
    # UniProt P20810, Calpastatin
    $seq = Fist::NonDB::Seq->new(seq => 'MNPTETKAIPVSQQMEGPHLPNKKKHKKQAVKTEPEKKSQSTKLSVVHEKKSQEGKPKEHTEPKSLPKQASDTGSNDAHNKKAVSRSAEQQPSEKSTEPKTKPQDMISAGGESVAGITAISGKPGDKKKEKKSLTPAVPVESKPDKPSGKSGMDAALDDLIDTLGGPEETEEENTTYTGPEVSDPMSSTYIEELGKREVTIPPKYRELLAKKEGITGPPADSSKPIGPDDAIDALSSDFTCGSPTAAGKKTEKEESTEVLKAQSAGTVRSAAPPQEKKRKVEKDTMSDQALEALSASLGTRQAEPELDLRSIKEVDEAKAKEEKLEKCGEDDETIPSEYRLKPATDKDGKPLLPEPEEKPKPRSESELIDELSEDFDRSECKEKPSKPTEKTEESKAAAPAPVSEAVCRTSMCSIQSAPPEPATLKGTVPDDAVEALADSLGKKEADPEDGKPVMDKVKEKAKEEDREKLGEKEETIPPDYRLEEVKDKDGKPLLPKESKEQLPPMSEDFLLDALSEDFSGPQNASSLKFEDAKLAAAISEVVSQTPASTTQAGAPPRDTSQSDKDLDDALDKLSDSLGQRQPDPDENKPMEDKVKEKAKAEHRDKLGERDDTIPPEYRHLLDDNGQDKPVKPPTKKSEDSKKPADDQDPIDALSGDLDSCPSTTETSQNTAKDKCKKAASSSKAPKNGGKAKDSAKTTEETSKPKDD');
};
ok(!$@, 'constructed seq object for P20810');

@feature_insts = $seq->run_iupred(feature => $feature);
ok((@feature_insts == 1), 'iupred found one unstructured region');

$feature_inst = $feature_insts[0];
ok((($feature_inst->start_seq == 1) and ($feature_inst->end_seq == $seq->len)), 'entire sequence is unstructured');

done_testing();
