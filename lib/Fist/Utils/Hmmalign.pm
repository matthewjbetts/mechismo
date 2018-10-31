package Fist::Utils::Hmmalign;

use Moose::Role;
use Carp ();
use File::Temp ();
use Fist::NonDB::FeatureInst;
use Bio::AlignIO;
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Hmmalign - a Moose::Role

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

=head2 run_hmmalign

 usage   : $self->run_hmmalign($fn_hmm);
 function: runs hmmalign
 args    : file name of HMM
 returns : undef on error

=cut

sub run_hmmalign {
    my($self, $fn_hmm) = @_;

    my $bioaln;
    my $tmpfile_seq;
    my $tmpfile_aln;
    my $seqs_hash;
    my $seq;
    my $cmd;
    my $stat;
    my $fh;
    my @lines;
    my $id;
    my $space;
    my $i;
    my $in;

    if(!defined($fn_hmm)) {
        Carp::cluck('no hmm file specified');
        return undef;
    }

    $tmpfile_seq = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $seqs_hash = {};
    foreach $seq ($self->seqs) {
        $seq->output_fasta($tmpfile_seq);
        $seqs_hash->{$seq->id} = $seq;
    }

    $tmpfile_aln = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);

    $cmd = "hmmalign --outformat PSIBLAST $fn_hmm $tmpfile_seq 1> $tmpfile_aln";
    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    if($stat != 0) {
        Carp::cluck("'$cmd' failed with status $stat: '$!'");
        return undef;
    }

    eval { $in = Bio::AlignIO->new(-file => $tmpfile_aln, -format => 'psi'); };
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
        else {
            return $bioaln;
        }
    }

    return $bioaln;
}

1;
