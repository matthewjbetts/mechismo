package Fist::IO::Alignment;

use Moose;
use Carp ();
use Fist::Utils::IdMapping;
use Bio::AlignIO;
use Fist::NonDB::Seq;
use Fist::NonDB::Alignment;
use Fist::NonDB::AlignedSeq;
use namespace::autoclean;

=head1 NAME

 Fist::IO::Alignment

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 parse

 usage   : $self->parse($method, [$bioaln]);
 function: parse filename, or Bio::Align::AlignI compliant object if given.
           Assumes the sequence identitifiers are for sequences already present.
 args    : name of alignment method ('muscle', 'blastp'), and an optional Bio::Align::AlignI compliant object
 returns : a Fist::NonDB::Alignment object, or undef on error

=cut

sub parse {
    my($self, $method, $bioaln) = @_;

    my $in;
    my $bioseq;
    my $aln;
    my $seq;
    my $alnseq;

    if(!$bioaln) {
        if(!defined($self->fn)) {
            Carp::cluck('no filename and no Bio::Align::AlignI compliant object given');
            return undef;
        }

        eval { $in = Bio::AlignIO->new(-file => $self->fn); };

        if($@) {
            Carp::cluck($@);
            return undef;
        }
        else {
            eval { $bioaln = $in->next_aln; };
            if($@) {
                Carp::cluck($@);
                return undef;
            }
        }
    }

    $aln = Fist::NonDB::Alignment->new(method => $method, len => $bioaln->length);
    foreach $bioseq ($bioaln->each_seq) {
        $alnseq = Fist::NonDB::AlignedSeq->new(id_seq => $bioseq->id, start => $bioseq->start, end => $bioseq->end, _aseq => $bioseq->seq);
        $aln->add_to_aligned_seqs($alnseq);
    }

    return $aln;
}

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
    my $method;
    my $len;
    my $id_new;

    $fh = $self->fh;
    while(<$fh>) {
        chomp;
        ($id_old, $method, $len) = split /\t/;
        $id_new = $id_mapping->id_new($id_to_space->{id}, 'Alignment', $id_old);
        print $fh_out join("\t", $id_new, $method, $len), "\n";
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
    return 'Alignment';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/id method len/);
}

__PACKAGE__->meta->make_immutable;
1;
