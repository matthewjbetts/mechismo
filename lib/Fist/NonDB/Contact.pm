package Fist::NonDB::Contact;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Contact

=cut

=head1 ACCESSORS

=cut

# FIXME - frag_inst1 and frag_inst2 should be Fist::Interface::FragInst, but for some
# reason this isn't picked up if a Fist::Schema::Result::FragInst object is used

has 'id'           => (is => 'rw', isa => 'Int');
has 'schema'       => (is => 'ro', isa => 'Fist::Schema');
has 'frag_inst1'   => (is => 'ro', isa => 'Any');
has 'frag_inst2'   => (is => 'ro', isa => 'Any');
has 'crystal'      => (is => 'rw', isa => 'Bool', default => 0);
has 'n_res1'       => (is => 'ro', isa => 'Int', default => 0);
has 'n_res2'       => (is => 'ro', isa => 'Int', default => 0);
has 'n_clash'      => (is => 'ro', isa => 'Int', default => 0);
has 'n_resres'     => (is => 'ro', isa => 'Int', default => 0);
has 'homo'         => (is => 'ro', isa => 'Bool', default => 0);

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

=head2 _calc_fist_contacts

 usage   :
 function: not implemented
 args    :
 returns :

=cut

sub _calc_fist_contacts {
    my($self) = @_;

    Carp::cluck('not implemented');
}

=head1 ROLES

 with 'Fist::Interface::Contact';

=cut

with 'Fist::Interface::Contact';

__PACKAGE__->meta->make_immutable;
1;
