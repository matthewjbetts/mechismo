package Fist::Interface::GoAnnotation;

use Moose::Role;

=head1 NAME

 Fist::Interface::GoAnnotation

=cut

=head1 ACCESSORS

=cut

=head2 seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq';

=head2 term

 usage   :
 function:
 args    :
 returns :

=cut

requires 'term';

=head2 subset

 usage   :
 function:
 args    :
 returns :

=cut

requires 'subset';

=head2 evidence_code

 usage   :
 function:
 args    :
 returns :

=cut

requires 'evidence_code';

=head1 ROLES

=cut

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
               $self->seq->id,
               $self->term->id,
               $self->subset,
               $self->evidence_code,
              ),
          "\n",
         );
}

1;
