package Fist::IO::Frag;

use Moose;
use Carp ();
use Fist::Utils::IdMapping;
use namespace::autoclean;

=head1 NAME

 Fist::IO::Frag

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

    my $fh;
    my $id_old;
    my $idcode;
    my $id_seq_old;
    my $fullchain;
    my $description;
    my $chemical_type;
    my $dom;
    my $id_new;
    my $id_seq_new;

    $fh = $self->fh;
    while(<$fh>) {
        chomp;
        ($id_old, $idcode, $id_seq_old, $fullchain, $description, $chemical_type, $dom) = split /\t/;
        $id_new = $id_mapping->id_new($id_to_space->{id}, 'Frag', $id_old);
        $id_seq_new = $id_mapping->id_new($id_to_space->{id_seq}, 'Seq', $id_seq_old);
        #print join("\t", __PACKAGE__, $id_old, $id_new), "\n";
        print $fh_out join("\t", $id_new, $idcode, $id_seq_new, $fullchain, $description, $chemical_type, $dom), "\n";
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
    return 'Frag';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id idcode id_seq fullchain description chemical_type dom/);
}

__PACKAGE__->meta->make_immutable;
1;
