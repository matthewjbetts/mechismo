#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Fist::Schema;
use Dir::Self;
use Config::General;

# options
my $help;
my $subset_default = 'none';
my $subset = $subset_default;

# other variables
my $conf;
my $config;
my $schema;
my $dbh;
my $sth;
my $row;
my $aliases;
my $alias;
my $id_seq;
my @F;
my $id_term;
my $evidence_code;

# parse command line
GetOptions(
	   'help'     => \$help,
           'subset=s' => \$subset,
	  );

defined($help) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] goa

option    parameter  description                       default
--------  ---------  --------------------------------  -------
--help    [none]     print this usage info and exit
--subset  [string]   GO subset (eg. 'goslim_generic')  $subset_default

END
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

$dbh = $schema->storage->dbh;
$sth = $dbh->prepare('SELECT alias, id_seq FROM Alias WHERE type = "UniProtKB accession"');
$sth->execute;
$aliases = {};
while($row = $sth->fetchrow_arrayref) {
    ($alias, $id_seq) = @{$row};
    $aliases->{$alias}->{$id_seq}++;
}

while(<STDIN>) {
    /^!/ and next;

    chomp;
    @F = split /\t/;
    $alias = $F[1];
    $id_term = $F[4];
    $evidence_code = $F[6];

    # NOTE - this list may contain duplicates, when different GO terms have
    # been mapped back to the same GO slim term, but will take memory to
    # remove them and anyway are ignored by the database schema.

    if(defined($aliases->{$alias})) {
        foreach $id_seq (keys %{$aliases->{$alias}}) {
            print join("\t", $id_seq, $id_term, $subset, $evidence_code), "\n";
        }
    }
}
