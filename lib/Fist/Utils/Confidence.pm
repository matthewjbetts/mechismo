package Fist::Utils::Confidence;

use Moose;
use Carp ();
use namespace::autoclean;

=head1 NAME

 Fist::Utils::Confidence

=cut

=head1 ACCESSORS

=cut

=head2 fn

 usage   : name of file containing the thresholds
 function:
 args    :
 returns :

=cut

has 'fn' => (is  => 'ro', isa => 'Str', required => 1);

=head2 _thresholds

 usage   : the thresholds, assigned when the object is built. Set them yourself at your own peril.
 function:
 args    :
 returns :

=cut

has '_thresholds' => (is  => 'rw', isa => 'HashRef[Any]');

=head1 ROLES

=cut

=head1 METHODS

=cut

sub BUILD {
    my($self) = @_;

    my $fn = $self->fn;
    my $fh;
    my $thresholds = {};
    my $fpr;
    my $conf;
    my @F;
    my $i;
    my $j;
    my $type;
    my $pcid;

    if(!open($fh, $fn)) {
        Carp::cluck("cannot open '$fn' file for reading");
        return undef;
    }

    while(<$fh>) {
        if(s/^FPR\s+(\S+)\s+(\S+)\s+//) {
            ($fpr, $conf) = ($1, $2);
            @F = split;
            for($i = 0, $j = 1; $j < @F; $i += 2, $j += 2) {
                $type = $F[$i];
                $pcid = $F[$j];
                defined($thresholds->{$type}) or ($thresholds->{$type} = []);
                push @{$thresholds->{$type}}, {pcid => $pcid, fpr => $fpr, conf => $conf};
            }
        }
    }
    close($fh);
    foreach $type (keys %{$thresholds}) {
        $thresholds->{$type} = [sort {$a->{pcid} <=> $b->{pcid}} @{$thresholds->{$type}}];
    }
    $self->_thresholds($thresholds);

    return $self;
}

sub confidence {
    my($self, $type, $pcid) = @_;

    my $threshold_p;
    my $threshold;
    my $conf;
    my $idx;

    $threshold_p = {conf => 'low'};
    $conf = undef;
    $idx = $#{$self->_thresholds->{$type}};
    if($pcid >= $self->_thresholds->{$type}->[$idx]->{pcid}) {
        $conf = $self->_thresholds->{$type}->[$idx]->{conf};
    }
    else {
        foreach $threshold (@{$self->_thresholds->{$type}}) {
            if($pcid < $threshold->{pcid}) {
                $conf = $threshold_p->{conf};
                last;
            }
            $threshold_p = $threshold;
        }
    }

    return $conf;
};

sub symbol {
    my($self, $conf) = @_;

    my $symbol;

    $symbol = uc substr($conf, 0, 1);

    return $symbol;
}

sub ie_class {
    my($self, $itps) = @_;

    # thresholds for calling a positive or negative interaction effect
    # FIXME - put these somewhere central, eg. in config file
    my $ie_pos = 0.5;
    my $ie_neg = -0.5;

    my $class;
    my $symbol;

    if(!defined($itps)) {
        $class = 'unknown';
    }
    elsif($itps >= $ie_pos) {
        $class = 'enabling';
    }
    elsif($itps <= $ie_neg) {
        $class = 'disabling';
    }
    elsif($itps > 0) {
        $class = 'enablingWeak';
    }
    elsif($itps < 0) {
        $class = 'disablingWeak';
    }
    else {
        $class = 'neutral';
    }

    return $class;
}

__PACKAGE__->meta->make_immutable;
1;
