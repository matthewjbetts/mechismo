package Fist::NonDB::Alias;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Seq

=cut

=head1 ACCESSORS

=cut

has 'seq' => (is => 'rw', isa => 'Fist::Interface::Seq');
has 'alias' => (is => 'ro', isa => 'Str');
has 'type' => (is => 'ro', isa => 'Str');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::Alias';

=cut

with 'Fist::Interface::Alias';

__PACKAGE__->meta->make_immutable;
1;
