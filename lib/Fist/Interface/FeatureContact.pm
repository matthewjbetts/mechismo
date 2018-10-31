package Fist::Interface::FeatureContact;

use Moose::Role;

=head1 NAME

 Fist::Interface::FeatureContact

=cut

=head1 ACCESSORS

=cut

=head2 feature1

 usage   :
 function:
 args    :
 returns :

=cut

requires 'feature1';

=head2 feature2

 usage   :
 function:
 args    :
 returns :

=cut

requires 'feature2';

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
               $self->feature1->id,
               $self->feature2->id,
              ),
          "\n",
         );
}

1;
