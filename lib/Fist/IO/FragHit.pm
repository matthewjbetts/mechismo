package Fist::IO::FragHit;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::FragHit

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 tsv_id_map

 usage   : $self->tsv_id_map($id_mapping, $id_to_space, \*STDOUT);
 function: parse tsv file, gets new unique identifiers for
           alignments and sequences from id mapping hash
 args    : hash, file handle GLOB
 returns : 1 on success, 0 on failure

=cut

sub tsv_id_map {
    my($self, $id_mapping, $id_to_space, $fh_out) = @_;

    my $fh;
    my $id_seq1_old;
    my $id_seq1_new;
    my $start;
    my $end;
    my $start1;
    my $end1;
    my $id_seq2_old;
    my $id_seq2_new;
    my $start2;
    my $end2;
    my $pcid;
    my $e_value;
    my $id_aln_old;
    my $id_aln_new;

    $fh = $self->fh;
    while(<$fh>) {
        chomp;
        (
         $id_seq1_old,
         $start,
         $end,
         $start1,
         $end1,
         $id_seq2_old,
         $start2,
         $end2,
         $pcid,
         $e_value,
         $id_aln_old,
        ) = split /\t/;

        $id_seq1_new = $id_mapping->id_new($id_to_space->{id_seq}, 'Seq', $id_seq1_old);
        $id_seq2_new = $id_mapping->id_new($id_to_space->{id_seq}, 'Seq', $id_seq2_old);
        $id_aln_new = $id_mapping->id_new($id_to_space->{id_aln}, 'Alignment', $id_aln_old);

        print(
              $fh_out
              join(
                   "\t",
                   $id_seq1_new,
                   $start,
                   $end,
                   $start1,
                   $end1,
                   $id_seq2_new,
                   $start2,
                   $end2,
                   $pcid,
                   $e_value,
                   $id_aln_new,
                  ),
              "\n",
             );
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
    return 'FragHit';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id_seq1 start end start1 end1 id_seq2 start2 end2 pcid e_value id_aln/);
}

__PACKAGE__->meta->make_immutable;
1;
