#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Carp ();
use Dir::Self;
use Config::General;
use Fist::Schema;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $taxa = [];
my $fnStringAliases;
my $fnStringLinks;

# other variables
my $conf;
my $config;
my $schema;
my $dbh;
my $sth;
my $table;
my $row;
my $idSeq1;
my $idSeq2;
my $taxaHash;
my $acUniprotToIdString;
my $idTaxon1;
my $idTaxon2;
my $idString1;
my $idString2;
my $score;
my $acUniprot;
my $source;
my $fhStringAliases; # for input
my $fhStringLinks; # for input
my $fnAlias; # for output
my $fhAlias;
my $fnString; # for output
my $fhString;
my $idStringToIdSeq;

# parse command line
GetOptions(
	   'help'      => \$help,
           'outdir=s'  => \$dn_out,
           'taxon=i'   => $taxa,
           'aliases=s' => \$fnStringAliases,
           'links=s'   => \$fnStringLinks,
	  );

defined($help) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option     parameter  description                     default
---------  ---------  ------------------------------  -------
--help     [none]     print this usage info and exit
--outdir   string     directory for output files      $dn_out_default
--taxon    integer    NCBI taxon ID of sequences      [all taxa]
--aliases  string     String aliases file             [none]
--links    string     String links file               [none]

END

    die $usage;
}

defined($fnStringAliases) or usage('--aliases required');
defined($fnStringLinks) or usage('--links required');

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$dbh = $schema->storage->dbh;
$sth = $dbh->prepare("SELECT a.id_seq FROM Alias AS a, SeqToTaxon AS b WHERE a.alias = ? AND a.type = 'UniProtKB accession' AND b.id_seq = a.id_seq AND b.id_taxon = ?");

$taxaHash = {};
@{$taxaHash}{@{$taxa}} = (1) x @{$taxa};

if($fnStringAliases =~ /\.gz\Z/) {
    open($fhStringAliases, "zcat $fnStringAliases |") or die "Error: cannot open pipe from 'zcat $fnStringAliases'.";
}
else {
    open($fhStringAliases, $fnStringAliases) or die "Error: cannot open '$fnStringAliases' file for reading.";
}

$fnAlias = "${dn_out}Alias.tsv";
open($fhAlias, ">$fnAlias") or die "Error: cannot open '$fnAlias' file for writing.";

if($fnStringLinks =~ /\.gz\Z/) {
    open($fhStringLinks, "zcat $fnStringLinks |") or die "Error: cannot open pipe from 'zcat $fnStringLinks'.";
}
else {
    open($fhStringLinks, $fnStringLinks) or die "Error: cannot open '$fnStringLinks' file for reading.";
}

$fnString = "${dn_out}StringInt.tsv";
open($fhString, ">$fnString") or die "Error: cannot open '$fnString' file for writing.";

# link string ids to database seq ids via uniprot accessions.
# output to Alias.tsv file so this info is available in the db.
$acUniprotToIdString = {};
while(<$fhStringAliases>) {
    /^#/ and next;
    chomp;

    ($idString1, $acUniprot, $source) = split /\t/;
    ($source =~ /UniProt_AC/) or next;

    ($idTaxon1, $idString1) = idStringToTaxon($idString1);
    defined($idTaxon1) or next;

    (@{$taxa} == 0) or defined($taxaHash->{$idTaxon1}) or next;

    $acUniprotToIdString->{$acUniprot}->{$idTaxon1}->{$idString1}++;
}
close($fhStringAliases);

$idStringToIdSeq = {};
foreach $acUniprot (keys %{$acUniprotToIdString}) {
    foreach $idTaxon1 (sort {$a <=> $b} keys %{$acUniprotToIdString->{$acUniprot}}) {
        foreach $idString1 (sort keys %{$acUniprotToIdString->{$acUniprot}->{$idTaxon1}}) {
            $sth->execute($acUniprot, $idTaxon1);
            $table = $sth->fetchall_arrayref;
            foreach $row (@{$table}) {
                $idSeq1 = $row->[0];
                $idStringToIdSeq->{$idTaxon1}->{$idString1}->{$idSeq1}++;
                print $fhAlias join("\t", $idSeq1, "${idTaxon1}.${idString1}", 'String ID'), "\n";
            }
        }
    }
}
close($fhAlias);

# extract string interactions involving the above proteins
while(<$fhStringLinks>) {
    /^protein1/ and next;
    ($idString1, $idString2, $score) = split;

    ($idTaxon1, $idString1) = idStringToTaxon($idString1);
    defined($idTaxon1) or next;

    ($idTaxon2, $idString2) = idStringToTaxon($idString2);
    defined($idTaxon2) or next;

    if(defined($idStringToIdSeq->{$idTaxon1}->{$idString1}) and defined($idStringToIdSeq->{$idTaxon2}->{$idString2})) {
        foreach $idSeq1 (sort {$a <=> $b} keys %{$idStringToIdSeq->{$idTaxon1}->{$idString1}}) {
            foreach $idSeq2 (sort {$a <=> $b} keys %{$idStringToIdSeq->{$idTaxon2}->{$idString2}}) {
                # uniprot to string matching is not one-to-one, so need to save the string ids
                # here too to ensure that we can link to the correct interaction in string
                print $fhString join("\t", $idSeq1, $idSeq2, "${idTaxon1}.${idString1}", "${idTaxon2}.${idString2}", $score), "\n";
            }
        }
    }
}
close($fhStringLinks);
close($fhString);

sub idStringToTaxon {
    my($idString) = @_;

    my $idTaxon;

    if($idString =~ /\A(\d+)\.(\S+)/) {
        ($idTaxon, $idString) = ($1, $2);
    }
    else {
        warn "Error: idStringToTaxon: cannot parse idTaxon from '$idString'.";
        return(undef, undef);
    }

    return($idTaxon, $idString);
}
