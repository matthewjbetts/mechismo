package Fist::NonDB::FeatureContact;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::FeatureContact

=cut

=head1 ACCESSORS

=cut

has 'feature1' => (is => 'ro', isa => 'Any');
has 'feature2' => (is => 'ro', isa => 'Any');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::FeatureContact';

=cut

with 'Fist::Interface::FeatureContact';

__PACKAGE__->meta->make_immutable;
1;
