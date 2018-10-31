package Fist::NonDB::FragResMapping;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::ResMapping

=cut

=head1 ACCESSORS

=cut

has 'id_frag' => (is => 'ro', isa => 'Int');
has 'fist'    => (is => 'ro', isa => 'Int');
has 'chain'   => (is => 'ro', isa => 'Str');
has 'resseq'  => (is => 'ro', isa => 'Int');
has 'icode'   => (is => 'rw', isa => 'Str');
has 'res3'    => (is => 'ro', isa => 'Str');
has 'res1'    => (is => 'ro', isa => 'Str');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::FragResMapping';

=cut

with 'Fist::Interface::FragResMapping';

__PACKAGE__->meta->make_immutable;
1;
