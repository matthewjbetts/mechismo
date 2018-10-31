package Fist::NonDB::GoTerm;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::GoTerm

=cut

=head1 ACCESSORS

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'namespace' => (is => 'ro', isa => 'Str');
has 'name' => (is => 'ro', isa => 'Str');
has 'def' => (is => 'ro', isa => 'Str');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::GoTerm';

=cut

with 'Fist::Interface::GoTerm';

__PACKAGE__->meta->make_immutable;
1;
