#!/usr/bin/perl -w

use strict;

use Test::More;

my $cleanup = 1;

my @inputs = (
              ['fasta', '1434750.fasta'], # CHAIN A from 1m4x
             );
my $input;
my $format;
my $fnIn;
my $fnOut;
my $cmd;
my $stat;
my $diff;

foreach $input (@inputs) {
    ($format, $fnIn) = @{$input};
    $fnIn = './t/' . $fnIn;
    $fnOut = './t/tmp/' . $input->[1];

    # check that program runs
    $cmd = "./testAlignment --in $format --fn $fnIn > $fnOut";
    print "$cmd\n";
    $stat = system($cmd);
    $stat >>= 8;
    ok(($stat == 0), "running '$cmd'");

    # compare to expected output
    # FIXME - the order in which the sequences are output is not
    # guaranteed to be the same as the input order, so just
    # doing a diff on the input and output might fail
    $cmd = "diff --brief $fnIn $fnOut";
    $stat = system($cmd);
    $stat >>= 8;
    ok(($stat == 0), "expected output");

    # clean-up output files
    if($cleanup) {
        unlink $fnOut;
    }
}


done_testing();
