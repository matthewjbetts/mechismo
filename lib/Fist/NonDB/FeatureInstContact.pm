package Fist::NonDB::FeatureInstContact;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::FeatureInstContact

=cut

=head1 ACCESSORS

=cut

has 'id'         => (is => 'rw', isa => 'Int');
has 'frag_inst1' => (is => 'ro', isa => 'Any');
has 'frag_inst2' => (is => 'ro', isa => 'Any');
has 'feat_inst1' => (is => 'ro', isa => 'Any');
has 'feat_inst2' => (is => 'ro', isa => 'Any');
has 'n_resres'   => (is => 'ro', isa => 'Num', default => 0);

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

=head1 ROLES

 with 'Fist::Interface::FeatureInstContact';

=cut

with 'Fist::Interface::FeatureInstContact';

__PACKAGE__->meta->make_immutable;
1;
