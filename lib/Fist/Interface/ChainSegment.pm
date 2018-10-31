package Fist::Interface::ChainSegment;

use Moose::Role;
use Fist::Utils::Overlap;

=head1 NAME

 Fist::Interface::ChainSegment

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

=head2 frag

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag';

=head2 chain

 usage   :
 function:
 args    :
 returns :

=cut

requires 'chain';

=head2 resseq_start

 usage   :
 function:
 args    :
 returns :

=cut

requires 'resseq_start';

=head2 resseq_end

 usage   :
 function:
 args    :
 returns :

=cut

requires 'resseq_end';

=head2 icode_start

 usage   :
 function:
 args    :
 returns :

=cut

requires 'icode_start';

=head2 icode_end

 usage   :
 function:
 args    :
 returns :

=cut

requires 'icode_end';

=head2 schema

 usage   :
 function:
 args    :
 returns :

=cut

requires 'schema';

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

    print(
          $fh
          join(
               "\t",
               $self->id,
               $self->frag->id,
               $self->chain,
               $self->resseq_start,
               $self->icode_start ? $self->icode_start : '',
               $self->resseq_end,
               $self->icode_end ? $self->icode_end : '',
              ),
          "\n",
         );
}

1;
