package Fist::Interface::FeatureInst;

use Moose::Role;

=head1 NAME

 Fist::Interface::FeatureInst

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

=head2 seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq';

=head2 feature

 usage   :
 function:
 args    :
 returns :

=cut

requires 'feature';

=head2 ac

 usage   :
 function:
 args    :
 returns :

=cut

requires 'ac';

=head2 start_seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'start_seq';

=head2 end_seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'end_seq';

=head2 start_feature

 usage   :
 function:
 args    :
 returns :

=cut

requires 'start_feature';

=head2 end_feature

 usage   :
 function:
 args    :
 returns :

=cut

requires 'end_feature';

=head2 wt

 usage   :
 function:
 args    :
 returns :

=cut

requires 'wt';

=head2 mt

 usage   :
 function:
 args    :
 returns :

=cut

requires 'mt';

=head2 e_value

 usage   :
 function:
 args    :
 returns :

=cut

requires 'e_value';

=head2 score

 usage   :
 function:
 args    :
 returns :

=cut

requires 'score';

=head2 true_positive

 usage   :
 function:
 args    :
 returns :

=cut

requires 'true_positive';

=head2 description

 usage   :
 function:
 args    :
 returns :

=cut

requires 'description';

=head2 enzymes

 usage   :
 function:
 args    :
 returns :

=cut

requires 'enzymes';

=head2 pmids

 usage   :
 function:
 args    :
 returns :

=cut

requires 'pmids';

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';

=cut

with 'Fist::Utils::UniqueIdentifier';

=head1 METHODS

=cut

=head2 add_to_pmids

 usage   :
 function:
 args    :
 returns :

=cut

requires 'add_to_pmids';

=head2 TO_JSON

 usage   :
 function:
 args    :
 returns :

=cut

sub TO_JSON {
    my($self) = @_;

    my $json;

    $json = {
             id            => $self->id,
             feature       => $self->feature->TO_JSON,
             ac            => $self->ac,
             start_seq     => $self->start_seq,
             end_seq       => $self->end_seq,
             start_feature => $self->start_feature,
             end_feature   => $self->end_feature,
             e_value       => $self->e_value,
             score         => $self->score,
             true_positive => $self->true_positive,
            };

    return $json;
}

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
               $self->seq->id,
               $self->feature->id,
               $self->ac,
               $self->start_seq,
               $self->end_seq,
               $self->start_feature,
               $self->end_feature,
               $self->wt,
               $self->mt,
               $self->e_value,
               $self->score,
               $self->true_positive,
               $self->description,
              ),
          "\n",
         );
}

1;
