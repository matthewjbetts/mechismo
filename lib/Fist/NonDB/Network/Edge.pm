package Fist::NonDB::Network::Edge;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Network::Edge

=cut

=head1 ACCESSORS

=cut

has 'idx'     => (is => 'rw', isa => 'Int', default => 0);
has 'source'  => (is => 'rw', isa => 'Int', default => 0);
has 'target'  => (is => 'rw', isa => 'Int', default => 0);
has 'n_sites' => (is => 'rw', isa => 'Int', default => 0);
has 'bi'      => (is => 'rw', isa => 'Int', default => 0);
has 'ies'     => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub {return []});
has 'url'     => (is => 'rw', isa => 'Str | Undef', default => '');

=head1 METHODS

=cut

sub TO_JSON {
    my($self) = @_;

    my $json;

    $json = {
             idx     => $self->idx,
             source  => $self->source,
             target  => $self->target,
             n_sites => $self->n_sites,
             bi      => $self->bi,
             ies     => $self->ies,
             url     => $self->url,
            };

    return $json;
}

=head1 ROLES

=cut

__PACKAGE__->meta->make_immutable;
1;
