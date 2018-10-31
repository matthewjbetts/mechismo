#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Carp ();
use Fist::IO::TaxonNodes;
use Fist::IO::Taxon;

# options
my $help;

# other variables
my $output;
my $fn_names;
my $fn_nodes;
my $io;
my $taxon;
my $parents;

# parse command line
GetOptions(
	   'help' => \$help,
	  );

defined($help) and usage();
defined($fn_names = shift @ARGV) or usage();
defined($fn_nodes = shift @ARGV) or usage();

sub usage {
    my($msg) = @_;

    my $prog;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    die(
	"\nUsage: $prog [options] ncbi/names.dmp ncbi/nodes.dmp\n\n",
	"option  parameter  description                     default\n",
	"------  ---------  ---------------- -------------  -------\n",
	"--help  [none]     print this usage info and exit\n",
        "\n",
       );
}

$io = Fist::IO::TaxonNodes->new(fn => $fn_nodes);
$parents = $io->parse_ncbi_nodes;

$io = Fist::IO::Taxon->new(fn => $fn_names);
foreach $taxon ($io->parse_ncbi_names($parents)) {
    $taxon->output_tsv(\*STDOUT);
}
