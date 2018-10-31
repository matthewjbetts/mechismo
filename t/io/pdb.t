use strict;
use warnings;
use Test::More;
use Fist::IO::Pdb;
use Bio::AlignIO;
use Fist::IO::Alignment;
use File::Temp;

my $cleanup = 1;
my $pdbio;
my $tempdir;
my $pdb;
my $alignmentio;
my $frags;
my $frag;
my $seqgroup;
my $bioaln;
my $aln;
my @aligned_seqs;
my @alns;
my @res_mappings;
my $expdta;
my $seq;
my $taxon;
my $chain_position;
my $pdbfile;
my $dssp_residues;
my @taxa;

eval { $pdbio = Fist::IO::Pdb->new(fn => 't/files/pdb4hhb.ent.gz'); };

$tempdir = File::Temp->newdir(CLEANUP => $cleanup);

$pdb = $pdbio->parse($tempdir, $cleanup);
ok($pdb, 'pdb file parsed');

ok($pdb->fn eq $pdbio->fn, 'file name set');
ok((-e $pdb->fn), 'file exists');
ok($pdb->idcode eq '4hhb', 'idcode parsed');
ok(ref $pdb->depdate eq 'DateTime', 'depdate set');
ok(ref $pdb->updated eq 'DateTime', 'updated set');
($expdta) = $pdb->expdtas;
ok($expdta->expdta eq 'X-RAY DIFFRACTION', 'expdta set');
ok($pdb->title eq 'THE CRYSTAL STRUCTURE OF HUMAN DEOXYHAEMOGLOBIN AT 1.74 ANGSTROMS RESOLUTION', 'title set');

$frags = {};
foreach $frag ($pdb->frags) {
    defined($frags->{$frag->chemical_type}) or ($frags->{$frag->chemical_type} = []);
    push @{$frags->{$frag->chemical_type}}, $frag;
}
ok((@{$frags->{peptide}} == 4), "four peptide fragments created");
ok((@{$frags->{HEM}} == 4), "four HEM fragments created");
ok((@{$frags->{PO4}} == 2), "two PO4 fragments created");

foreach $frag ($pdb->frags) {
    if($frag->chemical_type eq 'peptide') {
        ($seqgroup) = $frag->seq_groups;
        ok($seqgroup, 'seqgroup for frag');
        #ok((@{$seqgroup->seqs} == 4), "four sequences in seqgroup for frag " . $frag->id);
        ok((@{$seqgroup->seqs} == 2), "two sequences in seqgroup for frag " . $frag->id); # no longer generating pdbseq and interprets sequences
        ok((@{$frag->chain_segments} == 1), "one chain segment for frag " . $frag->id);

        # align all sequences for each fragment
        $seqgroup->tempdir($pdb->tempdir);
        $seqgroup->cleanup($pdb->cleanup);
        $bioaln = $seqgroup->run_muscle;

        foreach $seq ($seqgroup->seqs) {
            @taxa = $seq->taxa;
            ok(@taxa == 1, 'one taxon found');
            foreach $taxon ($seq->taxa) {
                ok($taxon->id == 9606, 'taxon id = 9606');
            }
        }

        eval { $alignmentio = Fist::IO::Alignment->new(); };
        ok(!$@, 'Fist::IO::Alignment object created');

        $aln = $alignmentio->parse('muscle', $bioaln);
        ok($aln, "alignment parsed from Frag");

        @aligned_seqs = $aln->aligned_seqs;
        #ok(@aligned_seqs == 4, 'four aligned sequences parsed from alignment');
        ok(@aligned_seqs == 2, 'four aligned sequences parsed from alignment'); # no longer generating pdbseq and interprets sequences

        # add alignment to seqgroup
        $seqgroup->add_to_alignments($aln);
        @alns = $seqgroup->alignments;
        ok(@alns == 1, 'alignment added to seqgroup');
    }

    # write pdbfile for frag
    $pdbfile = $frag->write_pdbfile;
    ok($pdbfile, 'pdb file written');

    # run dssp
    $dssp_residues = $frag->run_dssp;
    ok($dssp_residues, 'dssp ran');
}

$pdbio = Fist::IO::Pdb->new(fn => 't/files/pdb11as.ent.gz');
$pdb = $pdbio->parse($tempdir, $cleanup);
$frags = {};
foreach $frag ($pdb->frags) {
    defined($frags->{$frag->chemical_type}) or ($frags->{$frag->chemical_type} = []);
    push @{$frags->{$frag->chemical_type}}, $frag;
    print join("\t", $frag->chemical_type, $frag->pdb->idcode, $frag->dom), "\n";
}
ok((@{$frags->{peptide}} == 2), "two peptide fragments created");
ok((@{$frags->{ASN}} == 2), "two ASN fragments created");

###### taxa for multiple MOL_IDs in one set of SOURCE info
$pdbio = Fist::IO::Pdb->new(fn => 't/files/pdb1a0n.ent.gz');
$pdb = $pdbio->parse($tempdir, $cleanup);
foreach $frag ($pdb->frags) {
    foreach $seq ($seqgroup->seqs) {
        if($seq->source eq 'fist') {
            @taxa = $seq->taxa;
            ok(@taxa == 1, sprintf("one taxon found for %s { %s }", $pdb->idcode, $frag->dom));
            foreach $taxon ($seq->taxa) {
                ok($taxon->id == 9606, sprintf("taxon id = 9606 for %s { %s }", $pdb->idcode, $frag->dom));
            }
        }
    }
}

###### taxa for MOL_IDs covering more than one chain
$pdbio = Fist::IO::Pdb->new(fn => 't/files/pdb1zvf.ent.gz');
$pdb = $pdbio->parse($tempdir, $cleanup);
foreach $frag ($pdb->frags) {
    foreach $seq ($seqgroup->seqs) {
        if($seq->source eq 'fist') {
            @taxa = $seq->taxa;
            ok(@taxa == 1, sprintf("one taxon found for %s { %s }", $pdb->idcode, $frag->dom));
            foreach $taxon ($seq->taxa) {
                ok($taxon->id == 9606, sprintf("taxon id = 9606 for %s { %s }", $pdb->idcode, $frag->dom));
            }
        }
    }
}

###### MODRES
$pdbio = Fist::IO::Pdb->new(fn => 't/files/pdb1atp.ent.gz');
$pdb = $pdbio->parse($tempdir, $cleanup);
foreach $frag (@{$pdb->frags}) {
    if($frag->dom eq 'CHAIN E') {
        foreach $seqgroup ($frag->seq_groups) {
            foreach $seq ($seqgroup->seqs) {
                if($seq->source eq 'fist') {
                    # MODRES 1ATP TPO E  197  THR  PHOSPHOTHREONINE
                    # fist = 183
                    ok((substr($seq->seq, 182, 1) eq 'T'), '1atp CHAIN E residue 183 = T');

                    # MODRES 1ATP SEP E  338  SER  PHOSPHOSERINE
                    # fist = 324
                    ok((substr($seq->seq, 323, 1) eq 'S'), '1atp CHAIN E residue 324 = S');
                }
            }
        }
    }
}

$pdbio = Fist::IO::Pdb->new(fn => 't/files/pdb3akq.ent.gz');
$pdb = $pdbio->parse($tempdir, $cleanup);
foreach $frag (@{$pdb->frags}) {
    if($frag->dom eq 'CHAIN A') {
        foreach $seqgroup ($frag->seq_groups) {
            foreach $seq ($seqgroup->seqs) {
                if($seq->source eq 'fist') {
                    # MODRES 3AKQ PCA A    1  GLU  PYROGLUTAMIC ACID
                    # fist = 1
                    ok((substr($seq->seq, 0, 1) eq 'E'), '3akq CHAIN A residue 1 = E');
                }
            }
        }
    }
}

done_testing();
