package Fist::NonDB::Alignment;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Alignment

=cut

=head1 ACCESSORS

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'method' => (is => 'ro', isa => 'Str');
has 'len' => (is => 'ro', isa => 'Int');
has 'aligned_seqs' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::AlignedSeq]', default => sub {return []}, auto_deref => 1);
has '_aligned_seqs_by_id' => (is => 'rw', isa => 'HashRef[Fist::Interface::AlignedSeq]', default => sub {return {}}, auto_deref => 1);

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

sub add_to_aligned_seqs {
    my($self, @aligned_seqs) = @_;

    my $aligned_seq;

    if(@aligned_seqs > 0) {
        push(@{$self->aligned_seqs}, @aligned_seqs);
        foreach $aligned_seq (@aligned_seqs) {
            $self->_aligned_seqs_by_id->{$aligned_seq->id_seq} = $aligned_seq;
        }
    }
}

=head2 aseq

 usage   :
 function:
 args    :
 returns :

=cut

sub aseq {
    my($self, $id_seq) = @_;

    return $self->_aligned_seqs_by_id->{$id_seq};
}

=head2 aseqs

 usage   :
 function:
 args    :
 returns :

=cut

sub aseqs {
    my($self) = @_;

    return $self->_aligned_seqs_by_id;
}

=head1 ROLES

 with 'Fist::Interface::Alignment';

=cut

with 'Fist::Interface::Alignment';

__PACKAGE__->meta->make_immutable;
1;
