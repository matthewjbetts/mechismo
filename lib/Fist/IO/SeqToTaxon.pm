package Fist::IO::SeqToTaxon;

use Moose;
use Carp ();
use Fist::Utils::IdMapping;
use namespace::autoclean;

=head1 NAME

 Fist::IO::SeqToTaxon

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 tsv_id_map

 usage   : $self->tsv_id_map($id_mapping, $id_to_space, \*STDOUT);
 function: parse tsv file, assign new unique identifiers,
           store mapping of new to old in id mapping hash.
 args    : Fist::Utils::IdMapping object, string, file handle GLOB
 returns : 1 on success, 0 on failure

=cut

sub tsv_id_map {
    my($self, $id_mapping, $id_to_space, $fh_out) = @_;

    my $rs;
    my $fh;
    my $id_seq_old;
    my $id_seq_new;
    my $id_taxon;
    my $taxon;

    $rs = $id_mapping->schema->resultset('Taxon');
    $fh = $self->fh;
    while(<$fh>) {
        ($id_seq_old, $id_taxon) = split;

        if(!defined($id_seq_new = $id_mapping->id_new($id_to_space->{id_seq}, 'Seq', $id_seq_old))) {
            Carp::confess("no new id for fragment $id_seq_old");
            return 0;
        }

        # Taxon IDs used by the PDB are sometimes not in the NCBI Taxonomy anymore.
        # FIXME - could insert them here
        #($taxon) = $rs->search({ id => $id_taxon });
        #if(!defined($taxon)) {
        #    Carp::cluck("no taxon with id = '$id_taxon' in file ", $self->fn);
        #    next;
        #}
        print $fh_out join("\t", $id_seq_new, $id_taxon), "\n";
    }

    return 1;
}

=head2 resultset_name

 usage   :
 function: used internally to provide the result set name
 args    : none
 returns : the name of the result set

=cut

sub resultset_name {
    return 'SeqToTaxon';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id_seq id_taxon/);
}

__PACKAGE__->meta->make_immutable;
1;
