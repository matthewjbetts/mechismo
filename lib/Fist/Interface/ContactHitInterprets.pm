package Fist::Interface::ContactHitInterprets;

use Moose::Role;

=head1 NAME

 Fist::Interface::ContactHitInterprets

=cut

=head1 ACCESSORS

=cut

=head2 id_contact_hit

=cut

requires 'id_contact_hit';

=head2 mode

=cut

requires 'mode';

=head2 rand

=cut

requires 'rand';

=head2 raw

=cut

requires 'raw';

=head2 mean

=cut

requires 'mean';

=head2 sd

=cut

requires 'sd';

=head2 z

=cut

requires 'z';

=head1 METHODS

=cut

=head2 output_tsv

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print(
          $fh
          join(
               "\t",
               $self->id_contact_hit,
               $self->mode,
               $self->rand,
               $self->raw,
               $self->mean,
               $self->sd,
               $self->z,
              ),
          "\n",
         );
}

1;
