package Fist::IO::TaxonNodes;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::TaxonNodes

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 parse_ncbi_nodes

 usage   : $self->parse_ncbi_nodes();
 function: parse NCBI taxonomy 'nodes.dmp' file
 args    : none
 returns : a hash of id => id_parent pairs

=cut

sub parse_ncbi_nodes {
    my($self) = @_;

    my $fh;
    my @F;
    my $parents;

    $fh = $self->fh;

    $parents = {};
    while(<$fh>) {
        @F = split /\s*\|\s*/;
        $parents->{$F[0]} = ($F[1] eq 'root') ? 0 : $F[1];
    }

    return $parents;
}

=head2 resultset_name

 usage   :
 function: used internally to provide the result set name
 args    : none
 returns : the name of the result set

=cut

sub resultset_name {
    Carp::cluck('not implemented');
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    Carp::cluck('not implemented');
}

__PACKAGE__->meta->make_immutable;
1;
