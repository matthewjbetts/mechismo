package Fist::NonDB::Pdb;

use strict;
use warnings;
use Moose;

=head1 NAME

Fist::NonDB::Pdb

=cut

=head1 ACCESSORS

=cut

has 'id' => (is => 'rw', isa => 'Int');
has 'idcode' => (is => 'rw', isa => 'Str');
has 'title' => (is => 'rw', isa => 'Str');
has 'resolution' => (is => 'rw', isa => 'Num', default => 99999);
has 'depdate' => (is => 'rw', isa => 'DateTime');
has 'updated' => (is => 'rw', isa => 'DateTime');
has 'frags' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Frag]', default => sub {return []}, auto_deref => 1);
has 'expdtas' => (is => 'rw', isa => 'ArrayRef[Fist::Interface::Expdta]', default => sub {return []}, auto_deref => 1);

=head1 METHODS

=cut

sub add_to_frags {
    my($self, @frags) = @_;

    (@frags > 0) and push(@{$self->frags}, @frags);
}

sub add_to_res_mappings {
    my($self, @res_mappings) = @_;

    (@res_mappings > 0) and push(@{$self->res_mappings}, @res_mappings);
}

sub add_to_expdtas {
    my($self, @expdtas) = @_;

    (@expdtas > 0) and push(@{$self->expdtas}, @expdtas);
}

=head1 ROLES

 with 'Fist::Interface::Pdb';

=cut

with 'Fist::Interface::Pdb';

__PACKAGE__->meta->make_immutable;
1;
