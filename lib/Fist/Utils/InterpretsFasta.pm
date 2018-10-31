package Fist::Utils::InterpretsFasta;

use Moose::Role;
use Carp ();
use File::Temp ();
use Bio::SeqIO ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::InterpretsFasta - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head2 doms

 usage   : $self->doms
 function: method required of classes that consume this role
 args    : none
 returns : a list of Fist::Interface::Frag compliant objects

=cut

requires 'doms';

=head1 ROLES

 with 'Fist::Utils::System';

=cut

with 'Fist::Utils::System';

=head1 METHODS

=cut

=head2 run_interprets_fasta

 usage   : runs interprets -fasta on all frags
 function:
 args    :
 returns : a hash with key = frag->id and value = sequence, or undef on error

=cut

sub run_interprets_fasta {
    my($self) = @_;

    my $tmpfile_dom;
    my $tmpfile_seq;
    my $tmpfile_err;
    my $dom;
    my $cmd;
    my $in;
    my $bioseqs;
    my $bioseq;
    my $stat;
    my $fh;
    my @errors;

    # run interprets -fasta
    # interprets only looks at the first two doms in the file, so have to run separately on each dom
    $bioseqs = {};

    foreach $dom ($self->doms) {
        $tmpfile_dom = $dom->write_domfile;

        $tmpfile_seq = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
        $tmpfile_err = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
        $cmd = "interprets -fasta -d $tmpfile_dom 1> $tmpfile_seq 2> $tmpfile_err";
        $stat = $self->mysystem($cmd);
        $stat >>= 8;
        @errors = ();
        if($stat != 0) {
            push @errors, "'$cmd' failed with status $stat: '$!'";
            if(-s $tmpfile_err) {
                if(open($fh, $tmpfile_err)) {
                    while(<$fh>) {
                        /^# WARNING: strange atom type/ and next;
                        push @errors, $_;
                    }
                    close($fh);
                }
                else {
                    push @errors, "cannot open '$tmpfile_err' for reading.";
                }
            }
        }

        if(@errors > 0) {
            Carp::cluck(@errors);
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
            while($bioseq = $in->next_seq) {
                $bioseqs->{$bioseq->id} = $bioseq->seq;
            }
        }
    }

    return $bioseqs;
}

1;
