package Fist::NonDB::GoAnnotation;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::GoAnnotation

=cut

=head1 ACCESSORS

=cut

has 'seq' => (is => 'ro', isa => 'Fist::Interface::Seq');
has 'term' => (is => 'ro', isa => 'Fist::Interface::Term');
has 'subset' => (is => 'ro', isa => 'Str', default => 'none');
has 'evidence_code' => (is => 'ro', isa => 'Str');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::GoAnnotation';

=cut

with 'Fist::Interface::GoAnnotation';

__PACKAGE__->meta->make_immutable;
1;
