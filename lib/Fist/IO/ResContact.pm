package Fist::IO::ResContact;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::ResContact

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
    my @F;
    my $id_contact_new;
    my $id_contact_p;

    $fh = $self->fh;
    $id_contact_p = -1;
    while(<$fh>) {
        chomp;
        @F = split /\t/;
        ($F[0] != $id_contact_p) and ($id_contact_new = $id_mapping->id_new($id_to_space->{id_contact}, 'Contact', $F[0]));
        print $fh_out join("\t", $id_contact_new, @F[1..$#F]), "\n";
        $id_contact_p = $F[0];
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
    return 'ResContact';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id_contact bond_type chain1 resseq1 icode1 chain2 resseq2 icode2/);
}

__PACKAGE__->meta->make_immutable;
1;
