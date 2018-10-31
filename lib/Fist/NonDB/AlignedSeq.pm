package Fist::NonDB::AlignedSeq;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::AlignedSeq

=cut

=head1 ACCESSORS

=cut

has 'id_aln' => (is => 'rw', isa => 'Any');
has 'id_seq' => (is => 'rw', isa => 'Any');
has 'start' => (is => 'rw', isa => 'Int', default => 1);
has 'end' => (is => 'rw', isa => 'Int', default => 0);
has '_edit_str' => (is => 'rw', isa => 'Str');

=head1 METHODS

=cut

sub seq {
    Carp::cluck('not implemented');
}

=head1 ROLES

 with 'Fist::Interface::AlignedSeq';

=cut

with 'Fist::Interface::AlignedSeq';

__PACKAGE__->meta->make_immutable;
1;
