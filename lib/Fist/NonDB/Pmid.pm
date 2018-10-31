package Fist::NonDB::Pmid;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Pmid

=cut

=head1 ACCESSORS

=cut

has 'pmid' => (is => 'rw', isa => 'Int');
has 'throughput' => (is => 'rw', isa => 'Str');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::Pmid';

=cut

with 'Fist::Interface::Pmid';

__PACKAGE__->meta->make_immutable;
1;
