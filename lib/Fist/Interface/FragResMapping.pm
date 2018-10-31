package Fist::Interface::FragResMapping;

use Moose::Role;

=head1 NAME

 Fist::Interface::FragResMapping

=cut

=head1 ACCESSORS

=cut

=head2 id_frag

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_frag';

=head2 fist

 usage   :
 function:
 args    :
 returns :

=cut

requires 'fist';

=head2 chain

 usage   :
 function:
 args    :
 returns :

=cut

requires 'chain';

=head2 resseq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'resseq';

=head2 icode

 usage   :
 function:
 args    :
 returns :

=cut

requires 'icode';

=head2 res3

 usage   :
 function:
 args    :
 returns :

=cut

requires 'res3';

=head2 res1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'res1';

=head1 ROLES

=cut

=head1 METHODS

=cut

=head2 output_tsv

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print $fh join("\t", $self->id_frag, $self->fist, $self->chain, $self->resseq, $self->icode, $self->res3, $self->res1), "\n";
}

1;
