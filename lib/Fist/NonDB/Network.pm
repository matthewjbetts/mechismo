package Fist::NonDB::Network;

use strict;
use warnings;
use Moose;
use Fist::NonDB::Network::Node;
use Fist::NonDB::Network::Edge;

=head1 NAME

 Fist::NonDB::Network

=cut

=head1 ACCESSORS

=cut

has 'n_ids' => (is => 'rw', isa => 'Int', default => 0);
has 'n_ids_max' => (is => 'rw', isa => 'Int', default => 2000);
has 'node_idxs' => (is => 'rw', isa => 'HashRef[Any]', default => sub {return {}});
has 'nodes' => (is => 'rw', isa => 'ArrayRef[Any]', default => sub {return []});
has 'nodes_to_edges' => (is => 'rw', isa => 'HashRef[Any]', default => sub {return {}});
has 'links' => (is => 'rw', isa => 'ArrayRef[Any]', default => sub {return []});

=head1 METHODS

=cut

=head2 get_node

 usage   :
 function:
 args    :
 returns :

=cut

sub get_node {
    my($self, $id) = @_;

    my $node_idx;
    my $node;

    if(defined($node_idx = $self->node_idxs->{$id})) {
        $node = $self->nodes->[$node_idx];
    }

    return $node;
}

=head2 add_node

 usage   :
 function:
 args    :
 returns :

=cut

sub add_node {
    my($self, $id, $name, $type, $n_sites_on, $n_sites_out, $n_sites_in, $url) = @_;

    my $node;

    if(defined($node = $self->get_node($id))) {
        if($type eq 'query') {
            # might have been found earlier as a friend, such that
            # $node->{n_sites} is currently the number of sites
            # interacting with this protein rather than the number
            # of sites on this protein
            # FIXME - record both numbers
            $node->type($type);
            defined($n_sites_on) and $node->n_sites_on($n_sites_on);
        }
        defined($n_sites_out) and $node->n_sites_out($node->n_sites_out + $n_sites_out);
        defined($n_sites_in) and $node->n_sites_in($node->n_sites_in + $n_sites_in);
    }
    else {
        $node = Fist::NonDB::Network::Node->new(
                                                id          => $id,
                                                idx         => scalar @{$self->{nodes}},
                                                name        => $name,
                                                n_sites_on  => defined($n_sites_on) ? $n_sites_on : 0,
                                                n_sites_out => defined($n_sites_out) ? $n_sites_out : 0,
                                                n_sites_in  => defined($n_sites_in) ? $n_sites_in : 0,
                                                type        => $type,
                                                url         => $url,
                                               );
        push @{$self->nodes}, $node;
        $self->node_idxs->{$id} = $node->idx;
    }

    return $node;
}

=head2 get_edge

 usage   :
 function:
 args    :
 returns :

=cut

sub get_edge {
    my($self, $node_a1, $node_b1) = @_;

    my $edge_idx;
    my $edge;

    if(defined($edge_idx = $self->nodes_to_edges->{$node_a1->idx}->{$node_b1->idx})) {
        $edge = $self->links->[$edge_idx];
    }

    return $edge;
}

=head2 add_edge

 usage   :
 function:
 args    :
 returns :

=cut

sub add_edge {
    my($self, $node_a1, $node_b1, $n_sites, $ies, $url) = @_;

    my $edge;

    if(defined($edge = $self->get_edge($node_a1, $node_b1))) {
    }
    else {
        $edge = Fist::NonDB::Network::Edge->new(
                                                idx     => scalar @{$self->{links}},
                                                source  => $node_a1->idx + 0,  # '+ 0' to ensure that it's unquoted (i.e. treated as a number) when converted to JSON
                                                target  => $node_b1->idx + 0,
                                                n_sites => $n_sites,
                                                bi      => 0, # FIXME
                                                ies     => $ies,
                                                url     => $url,
                                               );
        push @{$self->links}, $edge;
        $self->nodes_to_edges->{$node_a1->idx}->{$node_b1->idx} = $edge->idx;
    }

    return $edge;
}

=head2 finalise

 usage   :
 function:
 args    :
 returns :

=cut

sub finalise {
    my($self) = @_;

    my $idx_node_a1;
    my $idx_node_b1;
    my $node_a1;
    my $idx_edge;

    # count degrees
    foreach $idx_node_a1 (keys %{$self->{nodes_to_edges}}) {
        $self->nodes->[$idx_node_a1]->out((scalar keys %{$self->nodes_to_edges->{$idx_node_a1}}));
        foreach $idx_node_b1 (keys %{$self->{nodes_to_edges}->{$idx_node_a1}}) {
            $self->nodes->[$idx_node_b1]->in($self->nodes->[$idx_node_b1]->in + 1);
        }
    }

    foreach $node_a1 (@{$self->nodes}) {
        $node_a1->degree($node_a1->out + $node_a1->in);
        $node_a1->n_sites_degree($node_a1->n_sites_out + $node_a1->n_sites_in);
    }

    # mark edges that occur in both directions
    foreach $idx_node_a1 (keys %{$self->nodes_to_edges}) {
        foreach $idx_node_b1 (keys %{$self->nodes_to_edges->{$idx_node_a1}}) {
            if(defined($self->nodes_to_edges->{$idx_node_b1}) and defined($self->nodes_to_edges->{$idx_node_b1}->{$idx_node_a1})) {
                foreach $idx_edge ($self->nodes_to_edges->{$idx_node_a1}->{$idx_node_b1}, $self->nodes_to_edges->{$idx_node_b1}->{$idx_node_a1}) {
                    $self->links->[$idx_edge]->bi(1);
                }
            }
        }
    }
}

=head2 TO_JSON

 usage   :
 function:
 args    :
 returns :

=cut

sub TO_JSON {
    my($self) = @_;

    my $json;

    $json = {
             n_ids          => $self->n_ids,
             n_ids_max      => $self->n_ids_max,
             node_idxs      => $self->node_idxs,
             nodes          => $self->nodes,
             nodes_to_edges => $self->nodes_to_edges,
             links          => $self->links,
            };

    return $json;
}


=head1 ROLES

=cut

__PACKAGE__->meta->make_immutable;
1;
