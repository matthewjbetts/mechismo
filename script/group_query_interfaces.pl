#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use Dir::Self;
use Config::General;
use Fist::Schema;

# options
my $help;
my $sources = [];
my $taxa = [];
my $min_j_default = 0.3;
my $min_j = $min_j_default;
my $min_n_resres_default = 10;
my $min_n_resres = $min_n_resres_default;

# other variables
my $conf;
my $config;
my $schema;
my $ids_queries;
my $fn;
my $fh;
my $id_query_p;
my $id_query;
my $id_contact_hit1;
my $component1;
my $id_contact_hit2;
my $component2;
my $j;
my $j_ss;
my $links;
my $id1;
my $id2;
my $id_group;

# parse command line
GetOptions(
	   'help'      => \$help,
           'source=s'  => $sources,
           'taxon=i'   => $taxa,
           'jaccard=f' => \$min_j,
           'resres=i'  => \$min_n_resres,
          );

defined($help) and usage();
(@ARGV == 0) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] QueryInterfaceJaccard1.tsv QueryInterfaceJaccard2.tsv ...

option     parameter  description                                       default
---------  ---------  ------------------------------------------------  -------
--help     [none]     print this usage info and exit
--source   string     source of query sequences                         [all sources]
--taxa     integer    taxon id of query sequences                       [all taxa]
--jaccard  integer    min jaccard at which interfaces should be linked  $min_j_default
--resres   integer    min number of resres contacts in a contact        $min_n_resres_default

END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

$ids_queries = get_query_ids($schema, $sources, $taxa);

$id_query_p = -1;
$links = {};
$id_group = 0;
foreach $fn (@ARGV) {
    if(!open($fh, $fn)) {
        warn "Error: cannot open '$fn' file for reading.";
        next;
    }

    while(<$fh>) {
        (/^#/ or /\A\s*\Z/) and next;

        ($id_query, $id_contact_hit1, $component1, $id_contact_hit2, $component2, $j, $j_ss) = split;

        if($id_query != $id_query_p) {
            (keys(%{$links}) > 0) and group($schema, \$id_group, $ids_queries, $id_query_p, $min_n_resres, $links);
            $links = {};
        }

        $id1 = join "\t", $id_contact_hit1, $component1;
        $id2 = join "\t", $id_contact_hit2, $component2;

        if($j >= $min_j) {
            $links->{$id1}->{$id2}++;
            $links->{$id2}->{$id1}++;
        }

        $id_query_p = $id_query;
    }
    close($fh);
}
(keys(%{$links}) > 0) and group($schema, \$id_group, $ids_queries, $id_query_p, $min_n_resres, $links);
$links = {};

foreach $id_query (keys %{$ids_queries}) {
    ($ids_queries->{$id_query} == 0) and group($schema, \$id_group, $ids_queries, $id_query, $min_n_resres, {});
}

sub group {
    my($schema, $id_group, $ids_queries, $id_query, $min_n_resres, $links) = @_;

    my $row;
    my %visited;
    my @queue;
    my @members;
    my $id1;
    my $id2;
    my $interfaces;

    $interfaces = get_interfaces($schema, $id_query, $min_n_resres);

    %visited = ();
    @queue = ();
    foreach $id1 (keys %{$interfaces}) {
        if(!$visited{$id1}) {
            $visited{$id1} = 1;

            @members = ();
            while(defined($id1)) {
                push @members, $id1;

                if(defined($links->{$id1})) {
                    foreach $id2 (keys %{$links->{$id1}}) {
                        if(!$visited{$id2}) {
                            $visited{$id2} = 1;
                            push @queue, $id2;
                        }
                    }
                }

                $visited{$id1} = 2;
                $id1 = shift @queue;
            }

            if(@members > 0) {
                ++${$id_group};
                foreach $id1 (@members) {
                    print join("\t", $id_query, $id1, ${$id_group}), "\n";
                }
            }
        }
    }

    $ids_queries->{$id_query}++;
}

sub get_query_ids {
    my($schema, $sources, $taxa) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $ids_queries;

    $dbh = $schema->storage->dbh;

    if(@{$sources} > 0) {
        if(@{$taxa} > 0) {
            $query = sprintf(
                             "SELECT id FROM Seq AS a, SeqToTaxon AS b WHERE a.source IN ('%s') and b.id_seq = a.id AND b.id_taxon IN (%s)",
                             join("','", @{$sources}),
                             join(',', @{$taxa}),
                            );
        }
        else {
            $query = sprintf "SELECT id FROM Seq AS WHERE source IN ('%s')", join("','", @{$sources});
        }
    }
    elsif(@{$taxa} > 0) {
        $query = sprintf "SELECT id FROM Seq AS a, SeqToTaxon AS b WHERE b.id_seq = a.id AND b.id_taxon IN (%s)", join(',', @{$taxa});
    }
    else {
        $query = 'SELECT id FROM Seq';
    }

    $sth = $dbh->prepare($query);
    $sth->{mysql_use_result} = 1;
    $sth->execute();
    $ids_queries = {};
    while($row = $sth->fetchrow_arrayref) {
        $ids_queries->{$row->[0]} = 0;
    }

    return $ids_queries;
}

sub get_interfaces {
    my($schema, $id_query, $min_n_resres) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $interfaces;
    my $id_interface;

    $dbh = $schema->storage->dbh;

    $interfaces = {};

    # with the query as the first sequence
    $query = "SELECT id, 'a1' FROM ContactHit WHERE id_seq_a1 = ? AND n_resres_a1b1 >= $min_n_resres";
    $sth = $dbh->prepare($query);
    $sth->{mysql_use_result} = 1;
    $sth->execute($id_query);
    while($row = $sth->fetchrow_arrayref) {
        $id_interface = join "\t", @{$row};
        $interfaces->{$id_interface}++;
    }

    # with the query as the second sequence
    $query = "SELECT id, 'b1' FROM ContactHit WHERE id_seq_b1 = ? AND n_resres_a1b1 >= $min_n_resres";
    $sth = $dbh->prepare($query);
    $sth->{mysql_use_result} = 1;
    $sth->execute($id_query);
    while($row = $sth->fetchrow_arrayref) {
        $id_interface = join "\t", @{$row};
        $interfaces->{$id_interface}++;
    }

    return($interfaces);
}
