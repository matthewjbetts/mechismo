package Fist::NonDB::Ecod;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Ecod

=cut

=head1 ACCESSORS

=cut

has 'id'   => (is => 'rw', isa => 'Int');
has 'x'    => (is => 'ro', isa => 'Int');
has 'h'    => (is => 'ro', isa => 'Int');
has 't'    => (is => 'ro', isa => 'Int');
has 'f'    => (is => 'ro', isa => 'Int');
has 'name' => (is => 'ro', isa => 'Str');

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

=head1 ROLES

 with 'Fist::Interface::Ecod';

=cut

with 'Fist::Interface::Ecod';

__PACKAGE__->meta->make_immutable;
1;
