package Fist::Schema::ResultSet::Seq;

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;

extends 'DBIx::Class::ResultSet';

=head1 NAME

 Fist::Schema::ResultSet::Seq;

=cut

=head1 ACCESSORS

=cut

=head1 METHODS

=cut

=head2 seqs

 usage   : @seqs = $self->seqs
 function: get all Seq objects in a result set
 args    : none
 returns : a list of Seq objects

=cut

sub seqs {
    my($self) = @_;

    return $self->all;
}

=head1 ROLES

 with 'Fist::Interface::Seqs';

=cut

with 'Fist::Interface::Seqs';

__PACKAGE__->meta->make_immutable;
1;

