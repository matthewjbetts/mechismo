package Fist::NonDB::ChainSegment;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::ChainSegment

=cut

=head1 ACCESSORS

=cut

has 'id'           => (is => 'rw', isa => 'Int');
has 'schema'       => (is => 'ro', isa => 'Fist::Schema');
has 'frag'         => (is => 'ro', isa => 'Fist::NonDB::Frag', weak_ref => 1);
has 'chain'        => (is => 'rw', isa => 'Str');
has 'resseq_start' => (is => 'ro', isa => 'Int');
has 'resseq_end'   => (is => 'ro', isa => 'Int');
has 'icode_start'  => (is => 'rw', isa => 'Str');
has 'icode_end'    => (is => 'rw', isa => 'Str');

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

=head1 ROLES

 with 'Fist::Interface::ChainSegment';

=cut

with 'Fist::Interface::ChainSegment';

__PACKAGE__->meta->make_immutable;
1;
