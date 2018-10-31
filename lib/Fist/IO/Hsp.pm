package Fist::IO::Hsp;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::Hsp

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
    my $id_old;
    my $id_seq1_old;
    my $id_seq2_old;
    my $pcid;
    my $a_len;
    my $n_gaps;
    my $start1;
    my $end1;
    my $start2;
    my $end2;
    my $e_value;
    my $score;
    my $id_aln_old;

    my $id_new;
    my $id_seq1_new;
    my $id_seq2_new;
    my $id_aln_new;

    $fh = $self->fh;
    while(<$fh>) {
        chomp;
        (
         $id_old,
         $id_seq1_old,
         $id_seq2_old,
         $pcid,
         $a_len,
         $n_gaps,
         $start1,
         $end1,
         $start2,
         $end2,
         $e_value,
         $score,
         $id_aln_old,
        ) = split /\t/;

        $id_new = $id_mapping->id_new($id_to_space->{id}, 'Hsp', $id_old);
        $id_seq1_new = $id_mapping->id_new($id_to_space->{id_seq}, 'Seq', $id_seq1_old);
        $id_seq2_new = $id_mapping->id_new($id_to_space->{id_seq}, 'Seq', $id_seq2_old);
        $id_aln_new = $id_mapping->id_new($id_to_space->{id_aln}, 'Alignment', $id_aln_old);

        print(
              $fh_out
              join(
                   "\t",
                   $id_new,
                   $id_seq1_new,
                   $id_seq2_new,
                   $pcid,
                   $a_len,
                   $n_gaps,
                   $start1,
                   $end1,
                   $start2,
                   $end2,
                   $e_value,
                   $score,
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
    return 'Hsp';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id id_seq1 id_seq2 pcid a_len n_gaps start1 end1 start2 end2 e_value score id_aln/);
}

__PACKAGE__->meta->make_immutable;
1;
