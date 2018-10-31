package Fist::Utils::FragHitJSmolSSContacts;

use Moose::Role;
use File::Temp ();
use Fist::Utils::JSmol;

=head1 NAME

 Fist::Utils::FragHitJSmolSSContacts - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head2 seq1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq1';

=head2 seq2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq2';

=head2 aln

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aln';

=head1 METHODS

=cut

=head2 jsmol_ss_str

 usage   : $self->jsmol_ss_str($posns, $sites);
 function: returns various jsmol selection strings for sidechain-sidechain
           contact residues involving the sites at the given positions
 args    : - a reference to an array of integers representing
             positions in the query sequence
           - a reference to a hash of sites information keyed by
             sequence position
 returns : - a string containing jsmol/pdb residue identifiers of the site residues
           - a string containing jsmol/pdb identifiers of the atoms in site residues
             that differ from the corresponding residues in the query
           - a string containing jsmol/pdb identifiers of the last common atoms of
             the site residues and the corresponding residues in the query
           - a reference to a hash keyed by positions in the query with values as
             the corresponding jsmol/pdb residue identifiers from the fragment
           - a reference to a hash keyed by jsmol/pdb residue identifiers with values
             as the corresponding site labels

=cut

sub jsmol_ss_str {
    my($self, $posns_a1, $sites_a1) = @_;

    my $seq_a1;
    my $id_seq_a1;
    my $aa_a1;
    my $seq_a2;
    my $id_seq_a2;
    my $aa_a2;
    my $frag;
    my $fist_to_pdb;
    my $aln;

    my $pos_a1;
    my $res_a1;
    my $apos;
    my $pos_a2;
    my $res_a2;
    my $pdbres_a2;
    my $atomdiffs_a2;
    my $atomdiff_a2;
    my $site_resns_a2;
    my $lcas_a2;
    my $lca_a2;
    my $a1_to_pdbres;
    my $labels_by_pdbres;
    my $site;

    $seq_a1 = $self->seq1;
    $id_seq_a1 = $seq_a1->id;
    $aa_a1 = $seq_a1->seq;
    $seq_a2 = $self->seq2;
    $id_seq_a2 = $seq_a2->id;
    $aa_a2 = $seq_a2->seq;
    $frag = $seq_a2->frag;
    ($fist_to_pdb) = $frag->fist_to_pdb;
    $aln = $self->aln;

    $site_resns_a2 = {};
    $atomdiffs_a2 = {};
    $lcas_a2 = {};
    $a1_to_pdbres = {};
    $labels_by_pdbres = {};
    if($posns_a1) {
        foreach $pos_a1 (@{$posns_a1}) {
            $res_a1 = substr($aa_a1, $pos_a1 - 1, 1);
            $apos = $aln->apos_from_pos($id_seq_a1, $pos_a1);
            if($apos) {
                $pos_a2 = $aln->pos_from_apos($id_seq_a2, $apos);
                if($pos_a2) {
                    $res_a2 = substr($aa_a2, $pos_a2 - 1, 1);
                    $pdbres_a2 = join ':', $fist_to_pdb->{$pos_a2}->[1], $fist_to_pdb->{$pos_a2}->[0];
                    ($atomdiff_a2 = Fist::Utils::JSmol::pdbres_atomdiff($pdbres_a2, $res_a1, $res_a2)) and $atomdiffs_a2->{$atomdiff_a2}++;
                    ($lca_a2 = Fist::Utils::JSmol::pdbres_lca($pdbres_a2, $res_a1, $res_a2)) and $lcas_a2->{$lca_a2}++;
                    $site_resns_a2->{$pdbres_a2}++;
                    $a1_to_pdbres->{$pos_a1} = $pdbres_a2;

                    $labels_by_pdbres->{$pdbres_a2} = [];
                    foreach $site (@{$sites_a1->{$pos_a1}->{sites}}) {
                        push @{$labels_by_pdbres->{$pdbres_a2}}, $site->{label};
                    }
                    $labels_by_pdbres->{$pdbres_a2} = join('', '"', join(', ', @{$labels_by_pdbres->{$pdbres_a2}}), '"');
                }
            }
        }
    }
    $site_resns_a2 = join(', ', sort keys %{$site_resns_a2});
    $atomdiffs_a2 = join(', ', sort keys %{$atomdiffs_a2});
    $lcas_a2 = join(', ', sort keys %{$lcas_a2});

    return($site_resns_a2, $atomdiffs_a2, $lcas_a2, $a1_to_pdbres, $labels_by_pdbres);
}

1;
