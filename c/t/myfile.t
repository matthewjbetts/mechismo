#!/usr/bin/perl -w

use strict;

use Test::More;

my $cleanup = 1;

my @fns = (
           ['testMyFile.c'],
           ['- < testMyFile.c', 'testMyFile.c'], # testing stdin
          );
my $fn;
my $fnIn;
my $fnResults;
my $fnOut;
my $cmd;
my $stat;
my $diff;

foreach $fn (@fns) {
    ($fnIn, $fnResults) = @{$fn};
    defined($fnResults) or ($fnResults = $fnIn);
    $fnOut = './t/tmp/' . $fnResults;

    # check that program runs
    $cmd = "./testMyFile $fnIn > $fnOut";
    print "$cmd\n";
    $stat = system($cmd);
    $stat >>= 8;
    ok(($stat == 0), "running '$cmd'");

    # compare to expected output
    $cmd = "diff --brief $fnResults $fnOut";
    $stat = system($cmd);
    $stat >>= 8;
    ok(($stat == 0), "expected output");

    # clean-up output files
    if($cleanup) {
        unlink $fnOut;
    }
}


done_testing();
