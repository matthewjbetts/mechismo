package Fist::NonDB::FragInst;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::FragInst

=cut

=head1 ACCESSORS

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'frag' => (is => 'ro', isa => 'Any', weak_ref => 1); # FIXME - doesn't like Fist::Interface::Frag for some reason
has 'assembly' => (is => 'ro', isa => 'Int');
has 'model' => (is => 'ro', isa => 'Int');

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

=head2 res_contact_table

 usage   :
 function: not implemented
 args    :
 returns :

=cut

sub res_contact_table {
    my($self) = @_;

    Carp::cluck('not implemented');
}

=head2 res_contact_table_list

 usage   :
 function: not implemented
 args    :
 returns :

=cut

sub res_contact_table_list {
    my($self) = @_;

    Carp::cluck('not implemented');
}

=head1 ROLES

 with 'Fist::Interface::FragInst';

=cut

with 'Fist::Interface::FragInst';

__PACKAGE__->meta->make_immutable;
1;
