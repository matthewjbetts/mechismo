package Fist::Utils::JSmol;

use Moose;
use Carp ();
use namespace::autoclean;

use Dir::Self;

=head1 NAME

 Fist::Utils::JSmol

=cut

=head1 ACCESSORS

=cut

=head1 ROLES

=cut

=head1 METHODS

=cut

sub pdbres_atomdiff {
    my($pdbres, $aa, $aa_pdb) = @_;

    my $atomdiff;

    if($aa_pdb ne $aa) {
        if(($aa_pdb eq 'G') or ($aa eq 'G')) {
            $atomdiff = "(${pdbres} and !(atomname = 'N' or atomname='CA' or atomname='O' or atomname='C'))";
        }
        elsif(($aa_pdb eq 'A') or ($aa eq 'A')) {
            $atomdiff = "(${pdbres} and !(atomname = 'N' or atomname='CA' or atomname='O' or atomname='C' or atomname='CB'))";
        }
        else {
            $atomdiff = "(${pdbres} and !(atomname = 'N' or atomname='CA' or atomname='O' or atomname='C' or atomname='CB' or atomname='CG' or atomname='CG1' or atomname='SG' or atomname='OG' or atomname='OG1'))";
        }
    }

    if($aa_pdb ne $aa) {
        # FIXME - mark up to the last common atom
        $atomdiff = "(${pdbres} and !(atomname = 'N' or atomname='CA' or atomname='O' or atomname='C' or atomname='CB'))";
    }

    return $atomdiff;
};

sub pdbres_lca { # Last Common Atom
    my($pdbres, $aa, $aa_pdb) = @_;

    my $lca;

    if($aa_pdb ne $aa) {
        if(($aa_pdb eq 'G') or ($aa eq 'G')) {
            $lca = "(${pdbres} and (atomname='CA'))";
        }
        elsif(($aa_pdb eq 'A') or ($aa eq 'A')) {
            $lca = "(${pdbres} and (atomname='CB'))";
        }
        else {
            $lca = "(${pdbres} and (atomname='CG' or atomname='CG1' or atomname='SG' or atomname='OG' or atomname='OG1'))";
        }
    }

    return $lca;
};

__PACKAGE__->meta->make_immutable;
1;
