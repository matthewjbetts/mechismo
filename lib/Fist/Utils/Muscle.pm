package Fist::Utils::Muscle;

use Moose::Role;
use Carp ();
use File::Temp ();
use Bio::AlignIO ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Muscle - a Moose::Role

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

=head2 run_muscle

 usage   :
 function: align sequences with 'muscle -maxhours 1'
 args    :
 returns : a Bio::Align::AlignI compliant object, or undef on error

=cut

sub run_muscle {
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
        ($seq->len >= 10000) and Carp::cluck('muscle may fail for id_seq = ', $seq->id, ' length = ', $seq->len);
        print $tmpfile_seq '>', $seq->id, "\n", $seq->seq, "\n"; # FIXME - use bioperl / have a seq io module
    }

    $tmpfile_aln = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    #$cmd = "muscle -maxhours 1 -quiet -clwstrict < $tmpfile_seq > $tmpfile_aln";
    $cmd = "muscle -quiet -clwstrict < $tmpfile_seq > $tmpfile_aln"; # -maxhours can mean the alignment is output in clustalw format...
    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    if($stat != 0) {
        Carp::cluck("'$cmd' failed with status $stat: '$!'");
        return undef;
    }

    eval { $in = Bio::AlignIO->new(-file => $tmpfile_aln, -format => 'clustalw'); };

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
