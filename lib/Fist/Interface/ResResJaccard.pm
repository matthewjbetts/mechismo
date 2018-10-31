package Fist::Interface::ResResJaccard;

use Moose::Role;

=head1 NAME

 Fist::Interface::ResResJaccard

=cut

=head1 ACCESSORS

=cut

=head2 frag_inst_a1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag_inst_a1';

=head2 frag_inst_b1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag_inst_b1';

=head2 frag_inst_a2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag_inst_a2';

=head2 frag_inst_b2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag_inst_b2';

=head2 intersection

 usage   :
 function:
 args    :
 returns :

=cut

requires 'intersection';

=head2 aln_union

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aln_union';

=head2 aln_jaccard

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aln_jaccard';

=head2 full_union

 usage   :
 function:
 args    :
 returns :

=cut

requires 'full_union';

=head2 full_jaccard

 usage   :
 function:
 args    :
 returns :

=cut

requires 'full_jaccard';

=head1 ROLES

=cut

=head1 METHODS

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print(
          $fh
          join(
               "\t",
               $self->frag_inst_a1->id,
               $self->frag_inst_b1->id,
               $self->frag_inst_a2->id,
               $self->frag_inst_b2->id,
               $self->intersection,
               $self->aln_n_resres1,
               $self->aln_n_resres2,
               $self->aln_union,
               $self->aln_jaccard,
               $self->orig_union,
               $self->orig_jaccard,
              ),
          "\n",
         );
}

1;
