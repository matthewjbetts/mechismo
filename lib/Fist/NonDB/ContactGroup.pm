package Fist::NonDB::ContactGroup;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::ContactGroup

=cut

=head1 ACCESSORS

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'id_parent' => (is => 'rw', isa => 'Int');
has 'type' => (is => 'rw', isa => 'Str');
has 'contacts' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Contact]', default => sub {return []}, auto_deref => 1);

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

sub add_to_contacts {
    my($self, @contacts) = @_;

    my $contact;

    if(@contacts > 0) {
        push(@{$self->contacts}, @contacts);
    }
}

=head1 ROLES

 with 'Fist::Interface::ContactGroup';

=cut

with 'Fist::Interface::ContactGroup';

__PACKAGE__->meta->make_immutable;
1;
