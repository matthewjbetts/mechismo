package Fist::IO::FragDssp;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::FragDssp

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
    my $id_p;
    my $id_frag_new;

    $fh = $self->fh;
    $id_p = -1;
    while(<$fh>) {
        chomp;
        @F = split /\t/;
        if($F[0] != $id_p) {
            if(!defined($id_frag_new = $id_mapping->id_new($id_to_space->{id_frag}, 'Frag', $F[0]))) {
                Carp::confess("no new id for fragment $F[0]");
                return 0;
            }
        }
        print $fh_out join("\t", $id_frag_new, @F[1..$#F]), "\n";
        $id_p = $F[0];
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
    return 'FragDssp';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id_frag chain resseq icode ss phi psi/);
}

__PACKAGE__->meta->make_immutable;
1;
