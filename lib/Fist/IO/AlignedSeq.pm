package Fist::IO::AlignedSeq;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::IO::AlignedSeq

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
    my $id_aln_old;
    my $id_seq_old;
    my $start;
    my $end;
    my $edits;
    my $id_aln_new;
    my $id_seq_new;

    $fh = $self->fh;
    while(<$fh>) {
        chomp;
        ($id_aln_old, $id_seq_old, $start, $end, $edits) = split /\t/;

        if(!defined($id_aln_new = $id_mapping->id_new($id_to_space->{id_aln}, 'Alignment', $id_aln_old))) {
            Carp::confess("no new id for alignment $id_aln_old");
            return 0;
        }

        if(!defined($id_seq_new = $id_mapping->id_new($id_to_space->{id_seq}, 'Seq', $id_seq_old))) {
            Carp::confess("no new id for sequence $id_seq_old");
            return 0;
        }

        print $fh_out join("\t", $id_aln_new, $id_seq_new, $start, $end, $edits), "\n";
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
    return 'AlignedSeq';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id_aln id_seq start end _edit_str/);
}

__PACKAGE__->meta->make_immutable;
1;
