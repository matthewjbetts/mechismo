package Fist::NonDB::ContactHitResidue;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::ContactHitResidue

=cut

=head1 ACCESSORS

=cut

has 'id_contact_hit' => (is => 'ro', isa => 'Int');
has 'pos_a1'         => (is => 'ro', isa => 'Int');
has 'pos_b1'         => (is => 'ro', isa => 'Int');
has 'pos_a2'         => (is => 'ro', isa => 'Int');
has 'pos_b2'         => (is => 'ro', isa => 'Int');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::ContactHitResidue';

=cut

with 'Fist::Interface::ContactHitResidue';

__PACKAGE__->meta->make_immutable;
1;
