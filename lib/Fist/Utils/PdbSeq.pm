package Fist::Utils::PdbSeq;

use Moose::Role;
use Carp ();
use File::Temp ();
use Bio::SeqIO ();

=head1 NAME

 Fist::Utils::PdbSeq - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head2 doms

 usage   : $self->doms
 function: method required of classes that consume this role
 args    : none
 returns : a list of Fist::Interface::Dom objects

=cut

requires 'doms';

=head2 write_domfile

 usage   : $self->write_domfile
 function: method required of classes that consume this role
 args    : none
 returns : a File::Temp object

=cut

requires 'write_domfile';

=head1 ROLES

 with 'Fist::Utils::System';

=cut

with 'Fist::Utils::System';

=head1 METHODS

=cut

=head2 run_pdbseq

 usage   :
 function: runs the STAMP program 'pdbseq' on all frags
 args    :
 returns : a hash with key = frag->id and value = sequence, or undef on error

=cut

sub run_pdbseq {
    my($self) = @_;

    my $tmpfile_dom;
    my $tmpfile_seq;
    my $tmpfile_err;
    my $fn;
    my $fh;
    my $frag;
    my $cmd;
    my $in;
    my $bioseqs;
    my $bioseq;
    my $stat;
    my @errors = ();
    my $dom;

    defined($tmpfile_dom = $self->write_domfile) or return(undef);

    # run pdbseq
    $tmpfile_seq = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $tmpfile_err = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $cmd = "pdbseq -f $tmpfile_dom -tl 50 1> $tmpfile_seq 2> $tmpfile_err";
    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    ($stat != 0) and push(@errors, "'$cmd' failed with status $stat: '$!'");

    # pdbseq returns 0 even when there are errors.
    # some are reported on STDOUT, some on STDERR
    foreach $fn ($tmpfile_seq, $tmpfile_err) {
        if(!open($fh, $fn)) {
            push @errors, "could not open '$fn' file for reading";
            next;
        }
        while(<$fh>) {
            /^error:\s*(.*)/ and push(@errors, $1);
        }
        close($fh);
    }

    if(@errors > 0) {
        Carp::cluck(sprintf("idcode: %s\n", $self->idcode), @errors);
        return undef;
    }

    eval {
        $in = Bio::SeqIO->new(-file => $tmpfile_seq, -format => 'fasta');
    };

    if($@) {
        warn $@;
        return undef;
    }
    else {
        $bioseqs = {};
        while($bioseq = $in->next_seq) {
            $bioseqs->{$bioseq->id} = $bioseq->seq;
        }
        return $bioseqs;
    }
}

1;
