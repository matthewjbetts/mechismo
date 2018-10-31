package Fist::Utils::IUPred;

use Moose::Role;
use Carp ();
use File::Temp ();
use Fist::NonDB::FeatureInst;
use namespace::autoclean;

=head1 NAME

 Fist::Utils::IUPred - a Moose::Role

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

=head2 run_iupred

 usage   :

 function: run iupred on sequence to predict long disorder. The mean disorder
           tendency over a sliding window of 11 residues (five either side of
           the current position) is calculated and disorder is called when
           this mean is >= 0.5

 returns : a list of Fist::NonDB::FeatureInst objects
           NOTE: these are not added to the sequence object

=cut

sub run_iupred {
    my($self, %args) = @_;

    my $tmpfile_seq;
    my $tmpfile_iupred;
    my $type;
    my $min;
    my $cmd;
    my $stat;
    my $fh;
    my @values;
    my $pos;
    my $res;
    my $disorder_tendency;
    my $d = 5; # this many positions either side of the current position
    my $window_len = $d * 2 + 1;
    my $i;
    my $start;
    my $end;
    my @window;
    my $window_value;
    my $window_mean;
    my $removed_value;
    my $state_p;
    my $state;
    my $regions;
    my $region;
    my @feature_insts;
    my $feature_inst;

    $type = 'long';
    $min = 0.5;

    $tmpfile_seq = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    print $tmpfile_seq '>', $self->id, "\n", $self->seq, "\n"; # FIXME - use bioperl / have a seq io module

    $tmpfile_iupred = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $cmd = "iupred $tmpfile_seq long > $tmpfile_iupred";
    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    if($stat != 0) {
        Carp::cluck("'$cmd' failed with status $stat: '$!'");
        return undef;
    }

    if(!open($fh, $tmpfile_iupred)) {
        Carp::cluck("cannot open '$tmpfile_iupred' for reading.");
        return undef;
    }

    @values = (-1);
    while(<$fh>) {
        /^#/ and next;
        s/^\s+//;
        ($pos, $res, $disorder_tendency) = split;
        defined($disorder_tendency) and push(@values, $disorder_tendency);
    }

    $state_p = 'ordered';
    $regions = [];

    @window = ();
    $window_value = 0;
    $pos = 1;
    for($i = $pos; ($i <= $window_len) and ($i <= $#values); $i++) {
        push @window, $values[$i];
        $window_value += $values[$i];
    }
    $window_mean = $window_value / scalar(@window);
    $state = ($window_mean >= $min) ? 'disordered' : 'ordered';
    if($state eq 'disordered') {
        $region = {start => $pos};
    }
    $state_p = $state;

    for($pos = 2, $start = 1 - $window_len, $end = 1 + $window_len; $pos <= $#values; ++$pos, ++$start, ++$end) {
        if($start >= 1) {
            $removed_value = shift @window;
            $window_value -= $removed_value;
        }

        if($end <= $#values) {
            push @window, $values[$end];
            $window_value += $values[$end];
        }

        $window_mean = $window_value / scalar(@window);

        $state = ($window_mean >= $min) ? 'disordered' : 'ordered';
        if($state ne $state_p) {
            if($state eq 'disordered') {
                $region = {start => $pos};
            }
            else {
                $region->{end} = $pos - 1;
                push @{$regions}, $region;
            }
        }
        $state_p = $state;
    }
    close($fh);

    if($state eq 'disordered') {
        $region->{end} = $pos - 1;
        push @{$regions}, $region;
    }

    # create FeatureInst objects
    @feature_insts = ();
    foreach $region (@{$regions}) {
        $feature_inst = Fist::NonDB::FeatureInst->new(seq => $self, feature => $args{feature}, start_seq => $region->{start},  end_seq => $region->{end});
        push @feature_insts, $feature_inst;
    }

    return @feature_insts;
}

1;
