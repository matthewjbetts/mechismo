package Fist::NonDB::Network::Node;

use strict;
use warnings;
use Moose;

=head1 NAME

 Fist::NonDB::Network::Node

=cut

=head1 ACCESSORS

=cut

has 'id'             => (is => 'rw', isa => 'Str');
has 'idx'            => (is => 'rw', isa => 'Int', default => 0);
has 'name'           => (is => 'rw', isa => 'Str', default => 0);
has 'type'           => (is => 'rw', isa => 'Str');
has 'url'            => (is => 'rw', isa => 'Str | Undef', default => '');
has 'n_sites_on'     => (is => 'rw', isa => 'Int', default => 0); # number of sites on this protein
has 'n_sites_out'    => (is => 'rw', isa => 'Int', default => 0); # number of sites on this protein that are in interfaces with other proteins
has 'n_sites_in'     => (is => 'rw', isa => 'Int', default => 0); # number of sites on other proteins that are in interfaces with this protein
has 'n_sites_degree' => (is => 'rw', isa => 'Int', default => 0); # n_sites_out + n_sites_in
has 'out'            => (is => 'rw', isa => 'Int', default => 0); # number of edges from this node
has 'in'             => (is => 'rw', isa => 'Int', default => 0); # number of edges to this node
has 'degree'         => (is => 'rw', isa => 'Int', default => 0); # out + in

=head1 METHODS

=cut

sub TO_JSON {
    my($self) = @_;

    my $json;

    $json = {
             id             => $self->id,
             idx            => $self->idx,
             name           => $self->name,
             type           => $self->type,
             url            => $self->url,
             n_sites_on     => $self->n_sites_on,
             n_sites_out    => $self->n_sites_out,
             n_sites_in     => $self->n_sites_in,
             n_sites_degree => $self->n_sites_degree,
             out            => $self->out,
             in             => $self->in,
             degree         => $self->degree,
            };

    return $json;
}

=head1 ROLES

=cut

__PACKAGE__->meta->make_immutable;
1;
