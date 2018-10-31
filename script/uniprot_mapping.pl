#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Dir::Self;
use Config::General;
use Carp;
use Fist::Schema;

# options
my $help;

# other variables
my $types_to_ignore = {
                       'HSSP' => 1, # HSSP has weird mappings, eg. P25054 = APC2, Ccdc88a, AMOTL1, Apc2
                      };
my $conf;
my $config;
my $schema;
my $dbh;
my $query;
my $sth;
my $table;
my $row;
my $uniprot_acs;
my $uniprot_ac;
my $id_seq;
my $type;
my $alias;

# parse command line
GetOptions(
	   'help'  => \$help,
	  );

defined($help) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] < idmapping.dat

option    parameter  description                     default
--------  ---------  ------------------------------  -------
--help    [none]     print this usage info and exit
END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$dbh = $schema->storage->dbh;

$query = 'SELECT alias, id_seq FROM Alias WHERE type = "UniProtKB accession"';
$sth = $dbh->prepare($query);
$sth->execute;
$table = $sth->fetchall_arrayref;
$uniprot_acs = {};
foreach $row (@{$table}) {
    ($uniprot_ac, $id_seq) = @{$row};
    $uniprot_acs->{$uniprot_ac}->{$id_seq}++;
}

while(<STDIN>) {
    chomp;
    ($uniprot_ac, $type, $alias) = split /\t/;

    if($types_to_ignore->{$type}) {
        next;
    }
    elsif($type eq 'UniProtKB-ID') {
        $type = 'UniProtKB ID';
    }
    elsif($type eq 'UniProtKB-AC') {
        $type = 'UniProtKB accession';
    }

    if(defined($uniprot_acs->{$uniprot_ac})) {
        foreach $id_seq (keys %{$uniprot_acs->{$uniprot_ac}}) {
            print join("\t", $id_seq, $alias, $type), "\n";
        }
    }
}
