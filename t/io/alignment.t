use strict;
use warnings;
use Test::More;
use Fist::IO::Alignment;

my $fn;
my $alignmentio;
my $aln;
my @aligned_seqs;

foreach $fn ('t/files/4hhbA.aln', 't/files/4hhbB.aln', 't/files/4hhbC.aln', 't/files/4hhbD.aln') {
    eval { $alignmentio = Fist::IO::Alignment->new(fn => $fn); };
    ok(!$@, "Fist::IO::Alignment object created for $fn");

    $aln = $alignmentio->parse('muscle');
    ok($aln, "alignment parsed from $fn");

    @aligned_seqs = $aln->aligned_seqs;
    ok(@aligned_seqs == 3, "three sequences parsed from $fn");
}

$fn = 'laskdkasjdkjljdjksajkla';
eval { $alignmentio = Fist::IO::Alignment->new(fn => $fn); };
ok($@, "Fist::IO::Alignment object creation failed for non existant file '$fn'");

done_testing();
