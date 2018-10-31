#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Fist::Schema;
use Fist::IO::SeqGroup;
use Dir::Self;
use Config::General;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;

# other variables
my $conf;
my $config;
my $schema;
my $level;
my $fn;
my $io;
my $fn_seqgroup;
my $fh_seqgroup;
my $fn_seq_to_group;
my $fh_seq_to_group;

# parse command line
GetOptions(
	   'help'     => \$help,
           'outdir=s' => \$dn_out,
	  );

defined($help) and usage();
defined($level = shift @ARGV) or usage();
defined($fn = shift @ARGV) or usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] level uniref.xml

option    parameter  description                     default
--------  ---------  ------------------------------  -------
--help    [none]     print this usage info and exit
--outdir  string     directory for output files      $dn_out_default\n",

END
    die($usage);
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

$fn_seqgroup = "${dn_out}SeqGroup.tsv";
open($fh_seqgroup, ">$fn_seqgroup") or die "Error: cannot open '$fn_seqgroup' file for writing.";

$fn_seq_to_group = "${dn_out}SeqToGroup.tsv";
open($fh_seq_to_group, ">$fn_seq_to_group") or die "Error: cannot open '$fn_seq_to_group' file for writing.";

$io = Fist::IO::SeqGroup->new(fn => $fn);
$io->parse_uniref_xml($level, $schema, $fh_seqgroup, $fh_seq_to_group);
