#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use Dir::Self;
use Config::General;
use Fist::Schema;
use Fist::IO::Site;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;

# other variables
my $conf;
my $config;
my $schema;
my $fn;
my $io;
my $seq;
my $fn_site;
my $fh_site;
my $fn_pmid;
my $fh_pmid;
my $fn_pmid_to_site;
my $fh_pmid_to_site;

# parse command line
GetOptions(
	   'help'     => \$help,
           'outdir=s' => \$dn_out,
	  );

defined($help) and usage();
(@ARGV == 0) and usage();

sub usage {
    my($msg) = @_;

    my $prog;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    die(
	"\nUsage: $prog [options] ptms1.txt ptms2.txt ...\n\n",
	"option    parameter  description                              default\n",
	"--------  ---------  ---------------------------------------  -------\n",
	"--help    [none]     print this usage info and exit\n",
        "--outdir  string     directory for output files               $dn_out_default\n",
        "\n",
       );
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

$fn_site = join '', $dn_out, 'Site', '.tsv';
open($fh_site, ">$fn_site") or die "Error: cannot open '$fn_site' file for writing.";

$fn_pmid = join '', $dn_out, 'Pmid', '.tsv';
open($fh_pmid, ">$fn_pmid") or die "Error: cannot open '$fn_pmid' file for writing.";

$fn_pmid_to_site = join '', $dn_out, 'PmidToSite', '.tsv';
open($fh_pmid_to_site, ">$fn_pmid_to_site") or die "Error: cannot open '$fn_pmid_to_site' file for writing.";

foreach $fn (@ARGV) {
    $io = Fist::IO::Site->new(fn => $fn);
    $io->parse_ptms_pablo($schema, $fh_site, $fh_pmid, $fh_pmid_to_site);
}

close($fh_site);
close($fh_pmid_to_site);
