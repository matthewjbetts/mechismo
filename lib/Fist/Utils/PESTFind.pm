package Fist::Utils::PESTFind;

use Moose::Role;
use Carp ();
use File::Temp ();
use Fist::NonDB::FeatureInst;
use namespace::autoclean;

=head1 NAME

 Fist::Utils::PESTFind - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head2 seq

 usage   : $self->seq
 function: method required of classes that consume this role
 args    : none
 returns :

=cut

requires 'seq';

=head1 ROLES

 with 'Fist::Utils::System';

=cut

with 'Fist::Utils::System';

=head1 METHODS

=cut

=head2 run_pestfind

 usage   :

 function: run pestfind on sequence to predict potential PEST sequences

 returns : a list of Fist::NonDB::FeatureInst objects
           NOTE: these are not added to the sequence object

=cut

sub run_pestfind {
    my($self, %args) = @_;

    my $tmpfile_seq;
    my $tmpfile_pestfind;
    my $cmd;
    my $stat;
    my $fh;
    my $type;
    my $n_aa;
    my $start;
    my $end;
    my $score;
    my @feature_insts;
    my $feature_inst;

    $tmpfile_seq = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    print $tmpfile_seq '>', $self->id, "\n", $self->seq, "\n"; # FIXME - use bioperl / have a seq io module

    $tmpfile_pestfind = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $cmd = "epestfind -sequence $tmpfile_seq -window 10 -order score -outfile $tmpfile_pestfind -graph text &> /dev/null";
    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    if($stat != 0) {
        Carp::cluck("'$cmd' failed with status $stat: '$!'");
        return undef;
    }

    if(!open($fh, $tmpfile_pestfind)) {
        Carp::cluck("cannot open '$tmpfile_pestfind' for reading.");
        return undef;
    }

    @feature_insts = ();
    while(<$fh>) {
        if(/\A(\S+) PEST motif with (\d+) amino acids between position (\d+) and (\d+)\./) {
            $type = $1;
            $n_aa = $2;
            $start = $3;
            $end = $4;
        }
        elsif(defined($type)) {
            if(/\A\s+(\d+)\s+(\S+)\s+(\d+)/) {
            }
            elsif(/\A\s+PEST score:\s+([-+\d\.]+)/) {
                $score = $1;
                if($type eq 'Potential') { # can also be 'Poor' and 'Invalid', but not interested in those
                    $feature_inst = Fist::NonDB::FeatureInst->new(seq => $self, feature => $args{feature}, start_seq => $start,  end_seq => $end, score => $score);
                    push @feature_insts, $feature_inst;
                }
                else {
                    $feature_inst = undef;
                }
            }
            elsif(/\A\s*\Z/) {
                $type = undef;
                $feature_inst = undef;
            }
        }
    }
    close($fh);

    return @feature_insts;
}

1;
