package Fist::Utils::Blast;

use Moose::Role;
use Carp ();
use File::Temp ();
use Bio::SearchIO;
use Fist::NonDB::Hsp;
use Fist::NonDB::Alignment;
use Fist::NonDB::AlignedSeq;
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Blast - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head2 seqs

 usage   : $self->seqs
 function: method required of classes that consume this role
 args    : none
 returns : a list of Fist::Interface::Seq objects

=cut

requires 'seqs';

=head1 ROLES

 with 'Fist::Utils::System';

=cut

with 'Fist::Utils::System';

=head1 METHODS

=cut

=head2 run_blastp

 usage   : $self->run_blast(
                            -e       => 1e-6,         # E-value, default = 0.01
                            -db      => 'fist-frags', # database [required]
                            -program => 'blastn',     # blast program to run, default = blastp
                            -fasta   => [$fn_fasta],  # list of names of files of sequences in fasta format (optional, overides seqs in the current object)
                           );
 function: runs blast without filtering low complexity sequences, to give
           accurate percentage identities. Assumes the blast database holds
           sequences identified by their fist Seq.id
 args    : e_value threshold, name of BLAST DB
 returns : undef on error

=cut

sub run_blast {
    my($self, %args) = @_;

    my $db;
    my $e;
    my $program;
    my $e_default = 0.01;
    my $input;
    my $tmpfile_seq;
    my $tmpfile_blast;
    my $cmd;
    my $stat;
    my @hsps;
    my $in;
    my $bioresult;
    my $biohit;
    my $biohsp;
    my $hsp;
    my $aln;
    my $seq;
    my $query_seq;
    my $hit_seq;
    my @aseqs;
    my $aseq;
    my $fh_aln_seq;
    my $fh_blast;

    if(!defined($db = $args{db})) {
        Carp::cluck('no database specified');
        return undef;
    }

    $e = defined($args{e}) ? $args{e} : 0.01;
    $program = defined($args{program}) ? $args{program} : 'blastp';

    if(!defined($args{fasta}) or (@{$args{fasta}} == 0)) {
        $tmpfile_seq = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
        foreach $seq ($self->seqs) {
            $seq->output_fasta($tmpfile_seq);
        }
        $input = "-i $tmpfile_seq";
    }
    else {
        $input = '-i ' . join(' -i ', @{$args{fasta}});
    }

    $tmpfile_blast = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $cmd = "blastall -p $program -d $db $input -v 10000 -b 10000 -e $e -F F 2> /dev/null | gzip > $tmpfile_blast";
    #print "CMD = '$cmd'\n";
    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    if($stat != 0) {
        Carp::cluck("'$cmd' failed with status $stat: '$!'");
        return undef;
    }

    if(!open($fh_blast, "zcat $tmpfile_blast |")) {
        Carp::cluck("cannot open pipe from 'zcat $tmpfile_blast'.");
        return undef;
    }

    eval {
        $in = Bio::SearchIO->new(-fh => $fh_blast, -format => 'blast');
    };

    if($@) {
        warn $@;
        return undef;
    }
    else {
        @hsps = ();
        while($bioresult = $in->next_result()) {
            while($biohit = $bioresult->next_hit()) {
                while($biohsp = $biohit->next_hsp) {
                    ($biohit->name eq $bioresult->query_name) and $args{no_self} and next;

                    $aln = Fist::NonDB::Alignment->new(method => $program, len => $biohsp->length('total'));
                    @aseqs = ();
                    push @aseqs, Fist::NonDB::AlignedSeq->new(
                                                              id_seq => $bioresult->query_name,
                                                              start  => $biohsp->start('query'),
                                                              end    => $biohsp->end('query'),
                                                              _aseq  => $biohsp->query_string,
                                                             );
                    push @aseqs, Fist::NonDB::AlignedSeq->new(
                                                              id_seq => $biohit->name,
                                                              start  => $biohsp->start('subject'),
                                                              end    => $biohsp->end('subject'),
                                                              _aseq  => $biohsp->hit_string,
                                                             );
                    $hsp = Fist::NonDB::Hsp->new(
                                                 id_seq1 => $bioresult->query_name,
                                                 id_seq2 => $biohit->name,
                                                 pcid    => $biohsp->frac_identical * 100,
                                                 a_len   => $biohsp->length('total'), # FIXME - redundant as specified in Alignment object
                                                 n_gaps  => $biohsp->gaps('total'),
                                                 start1  => $biohsp->start('query'),
                                                 end1    => $biohsp->end('query'),
                                                 start2  => $biohsp->start('subject'),
                                                 end2    => $biohsp->end('subject'),
                                                 e_value => $biohsp->evalue,
                                                 score   => $biohsp->score,
                                                 aln     => $aln,
                                                );

                    defined($args{fh_hsp}) and $hsp->output_tsv($args{fh_hsp});
                    defined($args{fh_aln}) and $aln->output_tsv($args{fh_aln});
                    if(defined($args{fh_aln_seq})) {
                        $fh_aln_seq = $args{fh_aln_seq};
                        foreach $aseq (@aseqs) {
                            print $fh_aln_seq join("\t", $aln->id, $aseq->id_seq, $aseq->start, $aseq->end, $aseq->edit_str), "\n";
                        }
                    }

                    if(!$args{dont_save}) {
                        $aln->add_to_aligned_seqs(@aseqs);
                        push @hsps, $hsp;
                    }
                }
            }
        }
        close($fh_blast);
        return @hsps;
    }
}

1;
