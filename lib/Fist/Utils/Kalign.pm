package Fist::Utils::Kalign;

use Moose::Role;
use Carp ();
use File::Temp ();
use Bio::AlignIO ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Kalign - a Moose::Role

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

=head2 run_kalign

 usage   :
 function: align sequences with kalign
 args    :
 returns : a Bio::Align::AlignI compliant object, or undef on error

=cut

sub run_kalign {
    my($self) = @_;

    my $tmpfile_seq;
    my $tmpfile_aln;
    my $frag;
    my $cmd;
    my $in;
    my $seq;
    my $aln;
    my $stat;

    $tmpfile_seq = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    foreach $seq ($self->seqs) {
        print $tmpfile_seq '>', $seq->id, "\n", $seq->seq, "\n"; # FIXME - use bioperl / have a seq io module
    }

    $tmpfile_aln = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $cmd = "kalign -format fasta < $tmpfile_seq 1> $tmpfile_aln 2> /dev/null";
    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    if($stat != 0) {
        Carp::cluck("'$cmd' failed with status $stat: '$!'");
        return undef;
    }

    eval { $in = Bio::AlignIO->new(-file => $tmpfile_aln, -format => 'fasta'); };

    if($@) {
        Carp::cluck($@);
        return undef;
    }
    else {
        eval { $aln = $in->next_aln; };
        if($@) {
            Carp::cluck($@);
            return undef;
        }
        else {
            return $aln;
        }
    }
}

1;
