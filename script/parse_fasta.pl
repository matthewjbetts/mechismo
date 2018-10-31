#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Fist::IO::Seq;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $source;
my $id_taxon;

# other variables
my $fn;
my $io;
my $seq;
my $alias;
my $taxon;
my $fn_seq;
my $fh_seq;
my $fn_alias;
my $fh_alias;
my $fn_seq_to_taxon;
my $fh_seq_to_taxon;

# parse command line
GetOptions(
	   'help'     => \$help,
           'outdir=s' => \$dn_out,
           'source=s' => \$source,
           'taxon=i'  => \$id_taxon,
	  );

defined($help) and usage();
defined($source) or usage('--source is required');
(@ARGV == 0) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] seqs1.fasta seqs2.fasta...

option    parameter  description                     default
--------  ---------  ------------------------------  -------
--help    [none]     print this usage info and exit
--outdir  string     directory for output files      $dn_out_default
--source  string     source of sequences             [none]
--taxon   integer    NCBI taxon id of sequences      [none]

END

    die $usage;
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

$fn_seq = join '', $dn_out, 'Seq', '.tsv';
open($fh_seq, ">$fn_seq") or die "Error: cannot open '$fn_seq' file for writing.";

$fn_alias = join '', $dn_out, 'Alias', '.tsv';
open($fh_alias, ">$fn_alias") or die "Error: cannot open '$fn_alias' file for writing.";

if(defined($id_taxon)) {
    $fn_seq_to_taxon = join '', $dn_out, 'SeqToTaxon', '.tsv';
    open($fh_seq_to_taxon, ">$fn_seq_to_taxon") or die "Error: cannot open '$fn_seq_to_taxon' file for writing.";
}

foreach $fn (@ARGV) {
    $io = Fist::IO::Seq->new(fn => $fn);
    while($seq = $io->parse_fasta($source, $id_taxon)) {
        $seq->output_tsv($fh_seq);
        foreach $alias ($seq->aliases) {
            $alias->output_tsv($fh_alias);
        }

        foreach $taxon ($seq->taxa) {
            print $fh_seq_to_taxon join("\t", $seq->id, $taxon->id), "\n";
        }
    }
}

defined($id_taxon) and close($fh_seq_to_taxon);
close($fh_alias);
close($fh_seq);
