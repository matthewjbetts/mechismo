package Fist::Interface::FeatureInstContact;

use Moose::Role;

=head1 NAME

 Fist::Interface::FeatureInstContact

=cut

=head1 ACCESSORS

=cut

=head2 id

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id';

=head2 frag_inst1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag_inst1';

=head2 frag_inst2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag_inst2';

=head2 feat_inst1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'feat_inst1';

=head2 feat_inst2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'feat_inst2';

=head2 n_resres

 usage   :
 function:
 args    :
 returns :

=cut

requires 'n_resres';

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';

=cut

with 'Fist::Utils::UniqueIdentifier';

=head1 METHODS

=cut

=head2 output_tsv

 usage   :
 function:
 args    :
 returns :

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print($fh
          join(
               "\t",
               $self->id,
               $self->frag_inst1->id,
               $self->frag_inst2->id,
               $self->feat_inst1->id,
               $self->feat_inst2->id,
               $self->n_resres,
              ),
          "\n",
         );
}

1;
