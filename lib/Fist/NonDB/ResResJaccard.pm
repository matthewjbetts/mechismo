package Fist::NonDB::ResResJaccard;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::ResResJaccard

=cut

=head1 ACCESSORS

=cut

# FIXME - frag_inst1 and frag_inst2 should be Fist::Interface::FragInst, but for some
# reason this isn't picked up if a Fist::Schema::Result::FragInst object is used

has 'frag_inst_a1'  => (is => 'ro', isa => 'Any');
has 'frag_inst_b1'  => (is => 'ro', isa => 'Any');
has 'frag_inst_a2'  => (is => 'ro', isa => 'Any');
has 'frag_inst_b2'  => (is => 'ro', isa => 'Any');
has 'intersection'  => (is => 'ro', isa => 'Int', default => 0);
has 'aln_n_resres1' => (is => 'ro', isa => 'Int', default => 0);
has 'aln_n_resres2' => (is => 'ro', isa => 'Int', default => 0);
has 'aln_union'     => (is => 'ro', isa => 'Int', default => 0);
has 'aln_jaccard'   => (is => 'ro', isa => 'Num', default => 0);
has 'full_union'    => (is => 'ro', isa => 'Int', default => 0);
has 'full_jaccard'  => (is => 'ro', isa => 'Num', default => 0);

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::ResResJaccard';

=cut

with 'Fist::Interface::ResResJaccard';

__PACKAGE__->meta->make_immutable;
1;
