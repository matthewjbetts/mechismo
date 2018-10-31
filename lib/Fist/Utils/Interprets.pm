package Fist::Utils::Interprets;

use Moose::Role;
use Carp ();
use File::Temp ();
use Bio::SeqIO ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Interprets - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head1 ROLES

 with 'Fist::Utils::System';

=cut

with 'Fist::Utils::System';

=head1 METHODS

=cut

=head2 run_interprets

 usage   : runs interprets
 function:
 args    :
 returns :

=cut

sub run_interprets {
    my($self, %args) = @_;

    my $mode;
    my $rand;
    my $tmpfile_dom;
    my $seq_a1;
    my $seq_a2;
    my $tmpfile_aln_a;
    my $seq_b1;
    my $seq_b2;
    my $tmpfile_aln_b;
    my $fh;
    my $tmpfile_interprets;
    my $tmpfile_err;
    my $cmd;
    my $stat;
    my $timeout = 300; # five minutes should be plenty
    my @errs;
    my $id1;
    my $pcid1;
    my $id2;
    my $pcid2;
    my $raw;
    my $mean;
    my $sd;
    my $z;

    $mode = $args{mode} ? $args{mode} : 4;
    $rand = $args{rand} ? $args{rand} : 200;

    # output a2b2 dom file
    $tmpfile_dom = $self->write_domfile;

    # output a1a2 alignment

    # FIXME - ideally would use the hsp alignment, but this is for (a subsection of)
    # the fist sequence, not the (whole of the) interprets sequence, and so will not
    # work directly with interprets. Would need to merge the hsp alignment and the
    # alignment for the seq group of the fragment

    # FIXME - no longer storing the interprets sequence, so will have to generate it

    $seq_a1 = $self->seq_a1;
    $seq_a2 = $self->frag_inst_a2->frag->interprets_seq;
    $tmpfile_aln_a = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);

    $cmd = "muscle -clwstrict -quiet > $tmpfile_aln_a 2> /dev/null";
    if(!open($fh, "| $cmd")) {
	warn "Error: aln_muscle: cannot open pipe to '$cmd'.";
	return undef;
    }
    printf $fh ">%s\n%s\n>%s\n%s\n", $seq_a1->id, $seq_a1->seq, $self->frag_inst_a2->id, $seq_a2->seq;
    close($fh);

    # output b1b2 alignment
    $seq_b1 = $self->seq_b1;
    $seq_b2 = $self->frag_inst_b2->frag->interprets_seq;
    $tmpfile_aln_b = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);

    $cmd = "muscle -clwstrict -quiet > $tmpfile_aln_b 2> /dev/null";
    if(!open($fh, "| $cmd")) {
	warn "Error: aln_muscle: cannot open pipe to '$cmd'.";
	return undef;
    }
    printf $fh ">%s\n%s\n>%s\n%s\n", $seq_b1->id, $seq_b1->seq, $self->frag_inst_b2->id, $seq_b2->seq;
    close($fh);

    # run interprets
    $tmpfile_interprets = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $tmpfile_err = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $cmd = "interprets -mode $mode -rand $rand -a $tmpfile_aln_a $tmpfile_aln_b -d $tmpfile_dom 1> $tmpfile_interprets 2> $tmpfile_err";

    # some input makes interprets hang
    eval {
	local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
	alarm $timeout;
	$stat = system("$cmd");

	# FIXME - the process will still be running in the background, as a zombie...
	# Need to use an explicit fork and kill it myself.

	alarm 0;
    };

    if($@) {
        if($@ eq "alarm\n") {
            Carp::cluck("'$cmd' timed out after $timeout seconds.");
            return undef;
        }
    }

    $stat >>= 8;
    if($stat != 0) {
        if(open($fh, $tmpfile_err)) {
            @errs = ();
            while(<$fh>) {
                (/^#/ or /\A\s*\Z/) and next;
                push @errs, $_;
            }
            close($fh);
            Carp::cluck("'$cmd' failed: @_");
        }
        else {
            Carp::cluck("cannot open '$tmpfile_interprets' for reading");
        }
	Carp::cluck("'$cmd' failed");
    }
    else {
        if(open($fh, $tmpfile_interprets)) {
            $id1 = undef;
            while(<$fh>) {
                # FIXME - parse interprets output
                # SUM  825264                93.50 825264                93.90    4.100  rand   -3.052    3.734    1.915 0.02500 4.10000 1.91529
                # SUM  825264                93.50 45789                100.00    4.100  rand   -3.563    3.988    1.921 0.02000 4.10000 1.92137
                # SUM  45786                100.00 825264                93.90    4.100  rand   -3.120    3.807    1.896 0.01000 4.10000 1.89644
                # SUM* 45786                100.00 45789                100.00    4.100  rand   -3.627    3.549    2.177 0.01500 4.10000 2.17706

                if(/^SUM\*{0,1}\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+rand\s+(\S+)\s+(\S+)\s+(\S+)/) {
                    ($id1, $pcid1, $id2, $pcid2, $raw, $mean, $sd, $z) = ($1, $2, $3, $4, $5, $6, $7, $8);
                    ($id1 eq $self->seq_a1->id) and ($id2 eq $self->seq_b1->id) and last;
                }

                # if random scores are included in interprets output:
                #
                # if(/Random\s+(\S+)\s+(\S+)/) {
                #     print join("\t", 'RAND', $self->id, $1, $2), "\n";
                # }
                #
                # if(/^SUM\*{0,1}\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+/) {
                #     ($id1, $pcid1, $id2, $pcid2, $raw) = ($1, $2, $3, $4, $5);
                # }
                #
                # if(defined($id1) and /rand\s+(\S+)\s+(\S+)\s+(\S+)/) {
                #     # 'rand' can be split from SUM info if scores for Random are printed
                #     ($mean, $sd, $z) = ($1, $2, $3);
                #     ($id1 eq $self->seq_a1->id) and ($id2 eq $self->seq_b1->id);
                #     $id1 = undef;
                # }
                #
                # print "ORIG: $_";
            }
            close($fh);
        }
        else {
            Carp::cluck("cannot open '$tmpfile_interprets' for reading");
        }
    }

    return($raw, $mean, $sd, $z);
}

1;
