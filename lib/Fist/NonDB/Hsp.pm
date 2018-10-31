package Fist::NonDB::Hsp;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Hsp

=cut

=head1 ACCESSORS

=cut

has 'id'      => (is => 'rw', isa => 'Int');
has 'seq1'    => (is => 'ro', isa => 'Any');
has 'id_seq1' => (is => 'rw', isa => 'Any');
has 'seq2'    => (is => 'ro', isa => 'Any');
has 'id_seq2' => (is => 'rw', isa => 'Any');
has 'pcid'    => (is => 'ro', isa => 'Num');
has 'a_len'   => (is => 'ro', isa => 'Int');
has 'n_gaps'  => (is => 'ro', isa => 'Int');
has 'start1'  => (is => 'ro', isa => 'Int');
has 'end1'    => (is => 'ro', isa => 'Int');
has 'start2'  => (is => 'ro', isa => 'Int');
has 'end2'    => (is => 'ro', isa => 'Int');
has 'e_value' => (is => 'ro', isa => 'Num');
has 'score'   => (is => 'ro', isa => 'Num');
has 'aln'     => (is => 'ro', isa => 'Any'); # FIXME - should be Fist::Interface::Alignment but this is not picked up if using Fist::NonDB::Alignment object

=head1 METHODS

=cut

around 'id_seq1' => sub {
    my($orig, $self, $id_seq1) = @_;

    $id_seq1 = defined($id_seq1) ? $self->$orig($id_seq1) : $self->$orig($self->seq1->id);

    return $id_seq1;
};

around 'id_seq2' => sub {
    my($orig, $self, $id_seq2) = @_;

    $id_seq2 = defined($id_seq2) ? $self->$orig($id_seq2) : $self->$orig($self->seq2->id);

    return $id_seq2;
};

=head1 ROLES

 with 'Fist::Interface::Hsp';

=cut

with 'Fist::Interface::Hsp';

__PACKAGE__->meta->make_immutable;
1;
