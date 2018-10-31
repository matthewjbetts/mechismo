package Fist::NonDB::SeqGroup;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::SeqGroup

=cut

=head1 ACCESSORS

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'type' => (is => 'rw', isa => 'Str');
has 'ac' => (is => 'rw', isa => 'Str');
has 'seqs' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Seq]', default => sub {return []}, auto_deref => 1);
has '_seqs_by_source' => (is => 'rw', isa => 'HashRef', default => sub {return {}});
has 'alignments' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Alignment]', default => sub {return []}, auto_deref => 1);

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

sub add_to_seqs {
    my($self, @seqs) = @_;

    my $seq;

    if(@seqs > 0) {
        push(@{$self->seqs}, @seqs);
        foreach $seq (@seqs) {
            defined($self->_seqs_by_source->{$seq->source}) or ($self->_seqs_by_source->{$seq->source} = []);
            push @{$self->_seqs_by_source->{$seq->source}}, $seq;
        }
    }
}

sub seqs_by_source {
    my($self, $source) = @_;

    my @seqs;

    @seqs = defined($self->_seqs_by_source->{$source}) ? @{$self->_seqs_by_source->{$source}} : ();

    return @seqs;
}

sub add_to_alignments {
    my($self, @alignments) = @_;

    (@alignments > 0) and push(@{$self->alignments}, @alignments);
}

=head1 ROLES

 with 'Fist::Interface::SeqGroup';

=cut

with 'Fist::Interface::SeqGroup';

__PACKAGE__->meta->make_immutable;
1;
