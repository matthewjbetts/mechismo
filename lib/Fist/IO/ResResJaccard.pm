package Fist::IO::ResResJaccard;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::ResResJaccard

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 resultset_name

 usage   :
 function: used internally to provide the result set name
 args    : none
 returns : the name of the result set

=cut

sub resultset_name {
    return 'ResResJaccard';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id_frag_inst_a1 id_frag_inst_b1 id_frag_inst_a2 id_frag_inst_b2 intersection aln_n_resres1 aln_n_resres2 aln_union aln_jaccard full_union full_jaccard/);
}

__PACKAGE__->meta->make_immutable;
1;
