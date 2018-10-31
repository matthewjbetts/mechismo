package Fist::NonDB::ContactHitInterprets;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::ContactHitInterprets

=cut

=head1 ACCESSORS

=cut

has 'id_contact_hit' => (is => 'ro', isa => 'Int');
has 'mode'           => (is => 'ro', isa => 'Int');
has 'rand'           => (is => 'ro', isa => 'Int');
has 'raw'            => (is => 'ro', isa => 'Num');
has 'mean'           => (is => 'ro', isa => 'Num');
has 'sd'             => (is => 'ro', isa => 'Num');
has 'z'              => (is => 'ro', isa => 'Num');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::ContactHitInterprets';

=cut

with 'Fist::Interface::ContactHitInterprets';

__PACKAGE__->meta->make_immutable;
1;
