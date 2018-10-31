package Fist::Utils::Web;

use Moose;
use Carp ();
use namespace::autoclean;

use Dir::Self;

=head1 NAME

 Fist::Utils::Web

=cut

=head1 ACCESSORS

=cut

=head1 ROLES

=cut

=head1 METHODS

=cut

my $confidence_thresholds;

BEGIN {
    my $fn;
    my $fh;
    my $fpr;
    my $conf;
    my @F;
    my $i;
    my $j;
    my $type;
    my $pcid;

    # FIXME - better way of given path to static files? in config file maybe?
    $fn = __DIR__ . '/../../../root/static/data/matrices/fpr.txt';
    if(open($fh, $fn)) {
        $confidence_thresholds = {};
        while(<$fh>) {
            if(s/^FPR\s+(\S+)\s+(\S+)\s+//) {
                ($fpr, $conf) = ($1, $2);
                @F = split;
                for($i = 0, $j = 1; $j < @F; $i += 2, $j += 2) {
                    $type = $F[$i];
                    $pcid = $F[$j];
                    defined($confidence_thresholds->{$type}) or ($confidence_thresholds->{$type} = []);
                    push @{$confidence_thresholds->{$type}}, {pcid => $pcid, fpr => $fpr, conf => $conf};
                }
            }
        }
        close($fh);
        foreach $type (keys %{$confidence_thresholds}) {
            $confidence_thresholds->{$type} = [sort {$a->{pcid} <=> $b->{pcid}} @{$confidence_thresholds->{$type}}];
        }
    }
    else {
        warn "Error: cannot open '$fn' file for reading.";
    }
}

sub hours_mins_secs {
    my($seconds) = @_;

    my $h;
    my $m;
    my $s;
    my $r;
    my $hms;

    $h = sprintf "%02.0f", $seconds / 3600;
    $s = $seconds % 3600;

    $m = sprintf "%02.0f", $s / 60;

    $s = sprintf "%02.0f", $s % 60;

    $hms = join ':', $h, $m, $s;

    return $hms;
}

__PACKAGE__->meta->make_immutable;
1;
