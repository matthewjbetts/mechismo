#!/usr/bin/perl -w

use strict;

my $rc;
my $ids;
my @F;
my $pos1;

$rc = {};
$ids = [(-1) x 8];
while(<>) {
    @F = split;
    ($F[2] eq $F[1]) and next;
    if($F[0] != $ids->[0]) {
        (keys(%{$rc}) > 0) and output($ids, $rc);
        $rc = {};
    }
    $ids = [@F[0..8]];
    $rc->{$F[9]}->{$F[10]}++;
}
(keys(%{$rc}) > 0) and output($ids, $rc);

sub output {
    my($ids, $rc) = @_;

    print join("\t", @{$ids});
    foreach $pos1 (sort {$a <=> $b} keys %{$rc}) {
        print "\t", join(',', $pos1, sort {$a <=> $b} keys %{$rc->{$pos1}});
    }
    print "\n";
}
