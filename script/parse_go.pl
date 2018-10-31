#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;

# options
my $help;

# other variables
my $type;
my $term;

# parse command line
GetOptions(
	   'help' => \$help,
	  );

defined($help) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] ontology

option    parameter  description                       default
--------  ---------  --------------------------------  -------
--help    [none]     print this usage info and exit

END
}

# FIXME - this should be an object method

$term = undef;
while(<STDIN>) {
    if(/^\[(.+?)\]/) {
        $type = $1;
        defined($term) and print(join("\t", $term->{id}, $term->{namespace}, $term->{name}, $term->{def}), "\n");
        $term = ($type eq 'Term') ? {} : undef;
    }
    elsif(defined($term) and /^id:\s+(\S+)/) {
        $term->{id} = $1;
    }
    elsif(defined($term) and /^name:\s+(.*?)\s*\Z/) {
        $term->{name} = $1;
    }
    elsif(defined($term) and /^namespace:\s+(.*?)\s*\Z/) {
        $term->{namespace} = $1;
    }
    elsif(defined($term) and /^def:\s+"(.*)"/) {
        $term->{def} = $1;
    }
}
defined($term) and print(join("\t", $term->{id}, $term->{namespace}, $term->{name}, $term->{def}), "\n");
