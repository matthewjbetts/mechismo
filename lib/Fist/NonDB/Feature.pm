package Fist::NonDB::Feature;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Feature

=cut

=head1 ACCESSORS

=cut

has 'id'          => (is => 'rw', isa => 'Int');
has 'source'      => (is => 'ro', isa => 'Str', default => '');
has 'ac_src'      => (is => 'ro', isa => 'Str', default => '');
has 'id_src'      => (is => 'ro', isa => 'Str', default => '');
has 'type'        => (is => 'ro', isa => 'Str', default => '');
has 'regex'       => (is => 'ro', isa => 'Str', default => '');
has 'description' => (is => 'ro', isa => 'Str', default => '');

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

=head1 ROLES

 with 'Fist::Interface::Feature';

=cut

with 'Fist::Interface::Feature';

__PACKAGE__->meta->make_immutable;
1;
