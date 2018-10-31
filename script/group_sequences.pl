#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use Dir::Self;
use Config::General;
use Carp;
use Fist::Schema;
use Fist::NonDB::SeqGroup;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $chemical_type_default = 'peptide';
my $chemical_type = $chemical_type_default;
my $sources = [];
my $taxa = [];
my $min_len_frac_default = 0.9;
my $min_len_frac = $min_len_frac_default;
my $min_pcid_default = 90;
my $min_pcid = $min_pcid_default;
my $type;

# other variables
my $conf;
my $config;
my $schema;
my $seq_group;
my $rep;
my $fn_seq_group;
my $fh_seq_group;
my $fn_seq_to_group;
my $fh_seq_to_group;
my %seqs;
my %visited;
my @queue;
my @members;
my $dbh;
my $query;
my $sth;
my $row;
my $links;
my $id_seq1;
my $id_seq2;

# parse command line
GetOptions(
	   'help'      => \$help,
           'outdir=s'  => \$dn_out,
           'source=s'  => $sources,
           'taxon=i'   => $taxa,
           'chem=s'    => \$chemical_type,
           'lf=f'      => \$min_len_frac,
           'pcid=f'    => \$min_pcid,
           'type=s'    => \$type,
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

option        parameter  description                                                 default
------------  ---------  ----------------------------------------------------------  -------
--help        [none]     print this usage info and exit
--outdir      string     directory for output files                                  $dn_out_default
--source [1]  string     source of sequences                                         [all sources]
--taxon [1]   integer    NCBI taxon ID of sequences                                  [all taxa]
--chem        string     chemical type of sequences                                  $chemical_type_default
--lf          float      minimum fraction of length of each sequence covered by hsp  $min_len_frac_default
--pcid        float      minimum percent identity                                    $min_pcid_default
--type        string     type name for resultant groups                              sprintf("%s lf=%.1f pcid=%.1f", \$source, \$min_len_frac, \$min_pcid)

1 - these options can be used more than once

END

    die $usage;
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

defined($type) or ($type = sprintf("%s lf=%.1f pcid=%.1f", (@{$sources} > 0) ? join(',', @{$sources}) : 'all', $min_len_frac, $min_pcid));

$fn_seq_group = "${dn_out}SeqGroup.tsv";
open($fh_seq_group, ">$fn_seq_group") or die "Error: cannot open '$fn_seq_group' file for writing.";

$fn_seq_to_group = "${dn_out}SeqToGroup.tsv";
open($fh_seq_to_group, ">$fn_seq_to_group") or die "Error: cannot open '$fn_seq_to_group' file for writing.";

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

# too slow and takes too much memory to do the following through DBIx::Class
$dbh = $schema->storage->dbh;

# get all the links
if(@{$taxa} > 0) {
    $query = <<END;
SELECT sA.id,
       sB.id
FROM   Hsp,
       Seq        AS sA,
       SeqToTaxon AS sA_to_t,
       Seq        AS sB,
       SeqToTaxon AS sB_to_t
WHERE  sA.id = Hsp.id_seq1
AND    sB.id = Hsp.id_seq2
AND    sB.id != sA.id
AND    sA_to_t.id_seq = sA.id
AND    sB_to_t.id_seq = sB.id
END
    $query .= sprintf("AND    sA_to_t.id_taxon IN (%s)\nAND    sB_to_t.id_taxon IN (%s)\n", join(',', @{$taxa}), join(',', @{$taxa}));
}
else {
    $query = <<END;
SELECT sA.id,
       sB.id
FROM   Hsp,
       Seq AS sA,
       Seq AS sB
WHERE  sA.id = Hsp.id_seq1
AND    sB.id = Hsp.id_seq2
END
}

($min_pcid > 0) and ($query .= "AND    pcid >= $min_pcid\n");
($min_len_frac > 0) and ($query .= "AND    ((Hsp.end1 - Hsp.start1 + 1) / sA.len) >= $min_len_frac\nAND    ((Hsp.end2 - Hsp.start2 + 1) / sB.len) >= $min_len_frac\n");
(@{$sources} > 0) and ($query .= sprintf("AND    sA.source IN ('%s')\nAND    sB.source IN ('%s')\n", join("','", @{$sources}), join("','", @{$sources})));

$sth = $dbh->prepare($query);
$sth->{mysql_use_result} = 1;
$sth->execute();
$links = {};
while($row = $sth->fetchrow_arrayref) {
    $links->{$row->[0]}->{$row->[1]}++;
}


# get all the sequences (because some may not be linked to any others)
if(@{$taxa} > 0) {
    $query = <<END;
SELECT s.id,
       s.len
FROM   Seq AS s,
       SeqToTaxon AS s_to_t
WHERE  s_to_t.id_seq = s.id
AND    s.chemical_type = '$chemical_type'
END
    $query .= sprintf("AND    s_to_t.id_taxon IN (%s)\n", join(',', @{$taxa}));
}
else {
    $query = <<END;
SELECT s.id,
       s.len
FROM   Seq AS s
WHERE  s.chemical_type = '$chemical_type'
END
}
(@{$sources} > 0) and ($query .= sprintf("AND    s.source IN ('%s')\n", join("','", @{$sources})));

$sth = $dbh->prepare($query);
$sth->{mysql_use_result} = 1;
$sth->execute();
%seqs = ();
while($row = $sth->fetchrow_arrayref) {
    $seqs{$row->[0]} = $row->[1];
}

# breadth-first search to group sequences by single-linkage
%visited = ();
@queue = ();
foreach $id_seq1 (keys %seqs) {
    if(!$visited{$id_seq1}) {
        $visited{$id_seq1} = 1;

        @members = ();
        while(defined($id_seq1)) {
            push @members, $id_seq1;

            foreach $id_seq2 (keys %{$links->{$id_seq1}}) {
                if(!$visited{$id_seq2}) {
                    $visited{$id_seq2} = 1;
                    push @queue, $id_seq2;
                }
            }

            $visited{$id_seq1} = 2;
            $id_seq1 = shift @queue;
        }

        if(@members > 0) {
            $seq_group = Fist::NonDB::SeqGroup->new(type => $type);
            $seq_group->output_tsv($fh_seq_group);
            $rep = 1;
            foreach $id_seq1 (sort {$seqs{$b} <=> $seqs{$a}} @members) { # longest sequence is the representative
                print $fh_seq_to_group join("\t", $id_seq1, $seq_group->id, $rep), "\n";
                $rep = 0;
            }
        }
    }
}

close($fh_seq_to_group);
close($fh_seq_group);

