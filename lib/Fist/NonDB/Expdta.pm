package Fist::NonDB::Expdta;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Expdta

=cut

=head1 ACCESSORS

=cut

has 'idcode' => (is => 'ro', isa => 'Str');
has 'expdta' => (is => 'rw', isa => 'Str');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::Expdta';

=cut

with 'Fist::Interface::Expdta';

__PACKAGE__->meta->make_immutable;
1;
