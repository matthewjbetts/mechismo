package Fist::NonDB::ResContact;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::ResContact

=cut

=head1 ACCESSORS

=cut

# FIXME - frag_inst1 and frag_inst2 should be Fist::Interface::FragInst, but for some
# reason this isn't picked up if a Fist::Schema::Result::FragInst object is used

has 'id_contact' => (is => 'ro', isa => 'Any');
has 'bond_type'  => (is => 'ro', isa => 'Int', default => 0);
has 'chain1'     => (is => 'ro', isa => 'Str');
has 'resseq1'    => (is => 'ro', isa => 'Int');
has 'icode1'     => (is => 'ro', isa => 'Str');
has 'chain2'     => (is => 'ro', isa => 'Str');
has 'resseq2'    => (is => 'ro', isa => 'Int');
has 'icode2'     => (is => 'ro', isa => 'Str');

=head1 METHODS

=cut

=head1 ROLES

 with 'Fist::Interface::ResContact';

=cut

with 'Fist::Interface::ResContact';

__PACKAGE__->meta->make_immutable;
1;
