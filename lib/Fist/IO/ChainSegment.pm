package Fist::IO::ChainSegment;

use Moose;
use Carp ();
use Fist::Utils::IdMapping;
use namespace::autoclean;

=head1 NAME

 Fist::IO::ChainSegment

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
    my $id_new;
    my $id_frag_old;
    my $id_frag_new;
    my $chain;
    my $resseq_start;
    my $icode_start;
    my $resseq_end;
    my $icode_end;

    $fh = $self->fh;
    while(<$fh>) {
        chomp;
        ($id_old, $id_frag_old, $chain, $resseq_start, $icode_start, $resseq_end, $icode_end) = split /\t/;
        $id_new = $id_mapping->id_new($id_to_space->{id}, 'ChainSegment', $id_old);
        $id_frag_new = $id_mapping->id_new($id_to_space->{id_frag}, 'Frag', $id_frag_old);
        print $fh_out join("\t", $id_new, $id_frag_new, $chain, $resseq_start, $icode_start, $resseq_end, $icode_end), "\n";
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
    return 'ChainSegment';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id id_frag chain resseq_start icode_start resseq_end icode_end/);
}

__PACKAGE__->meta->make_immutable;
1;
