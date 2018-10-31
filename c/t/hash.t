#!/usr/bin/perl -w

use strict;

use Test::More;

my $cleanup = 1;

my @inputs = (
              [0..99],
              [0..99],
              [0..99],
              [0..99],
              ['A'..'Z', 'a'..'z'],
              ['A'..'Z', 'a'..'z'],
              ['A'..'Z', 'a'..'z'],
              ['A'..'Z', 'a'..'z'],
              [qw(huey louie dewey dewey)], # four keys but two are identical
              [0..99, 0..99, 0..99],
             );
my $input;
my $i;
my $cmd;
my $stat;
my $qx;
my %hash;
my $nUniqueKeys;

$i = 0;
foreach $input (@inputs) {
    ++$i;

    $cmd = join ' ', './testHash', @{$input};
    #print "$cmd\n";

    #$stat = system($cmd);
    #$stat >>= 8;
    #ok(($stat == 0), "running input $i");

    %hash = ();
    @hash{@{$input}} = @{$input};
    $nUniqueKeys = scalar keys %hash;
    $qx = qx($cmd);
    ok($qx, "running input $i");
    ok(($qx =~ /nUniqueKeys = (\d+)/ and ($1 == $nUniqueKeys)), "correct number of unique keys");
}

done_testing();
