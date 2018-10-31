package Fist::NonDB::Taxon;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Taxon

=cut

=head1 ACCESSORS

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'id_parent' => (is => 'rw', isa => 'Int');
has 'scientific_name' => (is => 'ro', isa => 'Str');
has 'common_name' => (is => 'ro', isa => 'Str');

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

sub child_ids {
    Carp::cluck('not implemented');
}

=head1 ROLES

 with 'Fist::Interface::Taxon';

=cut

with 'Fist::Interface::Taxon';

__PACKAGE__->meta->make_immutable;
1;
