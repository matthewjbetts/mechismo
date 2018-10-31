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
my $high_default = 100;
my $high = $high_default;
my $medium_default = 20;
my $medium = $medium_default;

# other variables
my $conf;
my $config;
my $schema;
my $dbh;
my $query;
my $sth;
my $table;
my $row;
my $pmid;
my $n_seqs;
my $throughput;

# parse command line
GetOptions(
	   'help'     => \$help,
           'high=i'   => \$high,
           'medium=i' => \$medium,
	  );

defined($help) and usage();
($medium >= $high) and usage('--medium value should be less than --high value');
($medium <= 0) and usage('--medium value should be greater than zero');

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option    parameter  description                                                          default
--------  ---------  -------------------------------------------------------------------  -------
--help    [none]     print this usage info and exit
--high    integer    min number of sequences per PMID to be considered high throughput    $high_default
--medium  integer    min number of sequences per PMID to be considered medium throughput  $medium_default
                     (all other PMIDs considered to be low throughput, except PMIDs with
                      one sequence which will be given 'single' throughput)
END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$dbh = $schema->storage->dbh;

$query = <<END;
SELECT a.pmid,
       COUNT(DISTINCT(b.id_seq)) n_seqs
FROM   PmidToSite AS a,
       Site       AS b
WHERE  b.id = a.id_site
GROUP BY a.pmid
END
$sth = $dbh->prepare($query);
$sth->execute();
$table = $sth->fetchall_arrayref();

$sth = $dbh->prepare('SET sql_log_bin = 0');
$sth->execute();

$sth = $dbh->prepare("UPDATE Pmid SET throughput = 'none'");
$sth->execute;
$sth->finish;

$sth = $dbh->prepare('UPDATE Pmid SET throughput = ? WHERE pmid = ?');
foreach $row (@{$table}) {
    ($pmid, $n_seqs) = @{$row};

    if($n_seqs >= $high) {
        $throughput = 'high';
    }
    elsif($n_seqs >= $medium) {
        $throughput = 'medium';
    }
    elsif($n_seqs == 1) {
        $throughput = 'single';
    }
    else {
        $throughput = 'low';
    }
    $sth->execute($throughput, $pmid);
}
