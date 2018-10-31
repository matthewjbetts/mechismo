package Fist::Interface::ResContact;

use Moose::Role;

=head1 NAME

 Fist::Interface::ResContact

=cut

=head1 ACCESSORS

=cut

=head2 id_contact

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_contact';

=head2 bond_type

 usage   :
 function:
 args    :
 returns :

=cut

requires 'bond_type';

=head2 chain1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'chain1';

=head2 resseq1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'resseq1';

=head2 icode1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'icode1';

=head2 chain2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'chain2';

=head2 resseq2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'resseq2';

=head2 icode2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'icode2';

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
               $self->id_contact, # 0
               $self->bond_type,  # 1
               $self->chain1,     # 2
               $self->resseq1,    # 3
               $self->icode1,     # 4
               $self->chain2,     # 5
               $self->resseq2,    # 6
               $self->icode2,     # 7
              ),
          "\n",
         );
}

1;
