package Fist::Interface::ContactHitResidue;

use Moose::Role;

=head1 NAME

 Fist::Interface::ContactHitResidue

=cut

=head1 ACCESSORS

=cut

=head2 id_contact_hit

=cut

requires 'id_contact_hit';

=head2 pos_a1

=cut

requires 'pos_a1';

=head2 pos_b1

=cut

requires 'pos_b1';

=head2 pos_a2

=cut

requires 'pos_a2';

=head2 pos_b2

=cut

requires 'pos_b2';

=head1 ROLES

=cut

=head1 METHODS

=cut

=head2 res_a1

=cut

sub res_a1 {
    my($self, $contact_hit) = @_;

    return substr($contact_hit->seq_a1->seq, $self->pos_a1 - 1, 1);
}

=head2 res_b1

=cut

sub res_b1 {
    my($self, $contact_hit) = @_;

    return substr($contact_hit->seq_b1->seq, $self->pos_b1 - 1, 1);
}

=head2 res_a2

=cut

sub res_a2 {
    my($self, $contact_hit) = @_;

    return substr($contact_hit->seq_a2->seq, $self->pos_a2 - 1, 1);
}

=head2 res_b2

=cut

sub res_b2 {
    my($self, $contact_hit) = @_;

    return substr($contact_hit->seq_b2->seq, $self->pos_b2 - 1, 1);
}

=head2 chain_a2

=cut

sub chain_a2 {
    my($self, $contact_hit) = @_;

    my $chain_a2;
    my $resseq_a2;
    my $icode_a2;

    ($chain_a2, $resseq_a2, $icode_a2) = @{$contact_hit->frag_inst_a2->frag->fist_to_pdb->{$self->pos_a2}};

    return $chain_a2;
}

=head2 resseq_a2

=cut

sub resseq_a2 {
    my($self, $contact_hit) = @_;

    my $chain_a2;
    my $resseq_a2;
    my $icode_a2;

    ($chain_a2, $resseq_a2, $icode_a2) = @{$contact_hit->frag_inst_a2->frag->fist_to_pdb->{$self->pos_a2}};

    return $resseq_a2;
}

=head2 icode_a2

=cut

sub icode_a2 {
    my($self, $contact_hit) = @_;

    my $chain_a2;
    my $resseq_a2;
    my $icode_a2;

    ($chain_a2, $resseq_a2, $icode_a2) = @{$contact_hit->frag_inst_a2->frag->fist_to_pdb->{$self->pos_a2}};

    return $icode_a2;
}

=head2 chain_b2

=cut

sub chain_b2 {
    my($self, $contact_hit) = @_;

    my $chain_b2;
    my $resseq_b2;
    my $icode_b2;

    ($chain_b2, $resseq_b2, $icode_b2) = @{$contact_hit->frag_inst_b2->frag->fist_to_pdb->{$self->pos_b2}};

    return $chain_b2;
}

=head2 resseq_b2

=cut

sub resseq_b2 {
    my($self, $contact_hit) = @_;

    my $chain_b2;
    my $resseq_b2;
    my $icode_b2;

    ($chain_b2, $resseq_b2, $icode_b2) = @{$contact_hit->frag_inst_b2->frag->fist_to_pdb->{$self->pos_b2}};

    return $resseq_b2;
}

=head2 icode_b2

=cut

sub icode_b2 {
    my($self, $contact_hit) = @_;

    my $chain_b2;
    my $resseq_b2;
    my $icode_b2;

    ($chain_b2, $resseq_b2, $icode_b2) = @{$contact_hit->frag_inst_b2->frag->fist_to_pdb->{$self->pos_b2}};

    return $icode_b2;
}

=head2 reverse

=cut

sub reverse {
    my($self, $id_contact_hit) = @_;

    my $reverse;

    $reverse = (ref $self)->new(
                                {
                                 id_contact_hit => $id_contact_hit,
                                 pos_a1         => $self->pos_b1,
                                 pos_b1         => $self->pos_a1,
                                 pos_a2         => $self->pos_b2,
                                 pos_b2         => $self->pos_a2,
                                }
                               );

    return $reverse;
}


=head2 output_tsv

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print(
          $fh
          join(
               "\t",
               $self->id_contact_hit,
               $self->pos_a1,
               $self->pos_b1,
               $self->pos_a2,
               $self->pos_b2,
              ),
          "\n",
         );
}

1;
