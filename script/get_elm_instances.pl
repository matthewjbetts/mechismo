#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Dir::Self;
use Config::General;
use Fist::Schema;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $tolerance = 0.000001;
my $ids = [];
my $taxa = [];
my $child_taxa;
my $types = [];
my $sources = [];
my $pbs_name;
my $max_n_jobs_default = 30;
my $max_n_jobs = $max_n_jobs_default;
my $q_max_default = 200;
my $q_max = $q_max_default;

# other variables
my $fn_elm;
my $fh_elm;
my $conf;
my $config;
my $schema;
my $dbh;
my $query;
my $sth;
my $elms;
my $elm;
my $regex;
my $table;
my $row;
my $len;
my $start;
my $end;
my $children;
my $taxon;
my $id_child;
my $id_inst;
my @F;
my @headings;
my %hash;
my $id_elm;
my $aliases;
my $feature;
my @seqs;
my $seq;
my $tps;
my $tp;
my $id_seq;
my $aas;

# parse command line
GetOptions(
	   'help'       => \$help,
           'outdir=s'   => \$dn_out,
           'id=i'       => $ids,
           'taxon=i'    => $taxa,
           'child_taxa' => \$child_taxa,
           'type=s'     => $types,
           'source=s'   => $sources,
           'pbs=s'      => \$pbs_name,
           'n_jobs=i'   => \$max_n_jobs,
           'q_max=i'    => \$q_max,
	  );

defined($help) and usage();
defined($fn_elm = shift @ARGV) or usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] elm_instances.tsv

option          parameter  description                                      default
--------------  ---------  -----------------------------------------------  -------
--help          [none]     print this usage info and exit
--outdir        string     directory for output files                       $dn_out_default
--taxon [1,2]   integer    taxon                                            [none]
--child_taxa    [none]     also get sequences from children of given taxon
--source [1,2]  string     source of sequences                              [none]

1 - these options can be used more than once
2 - use to get first query sequences if --id is not given

END

    die $usage;
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$dbh = $schema->storage->dbh;

if($child_taxa) {
    $children = {};
    foreach $taxon ($schema->resultset('Taxon')->search({id => {in => $taxa}})) {
        $children->{$taxon->id}++;
        foreach $id_child ($taxon->child_ids) {
            $children->{$id_child}++;
        }
    }
    $taxa = [sort {$a <=> $b} keys %{$children}];
}

# parse true positive instances given by ELM db
open($fh_elm, $fn_elm) or die "Error: cannot open '$fn_elm' for reading.";
$tps = {};
while(<$fh_elm>) {
    /^#/ and next;
    chomp;
    @F = split /\t/;

    if(/^Accession/) {
        @headings = @F;
        next;
    }

    @hash{@headings} = @F;
    $id_elm = $hash{ELMIdentifier};
    $aliases = [split /\s+/, $hash{Accessions}];
    $start = $hash{Start};
    $end = $hash{End};
    $tp = $hash{InstanceLogic};
    ($tp eq 'true positive') or next;

    if(!defined($feature = $schema->resultset('Feature')->search({source => 'elm', id_src => $id_elm}, {columns => ['id']})->first)) {
        warn "Warning: no feature with source = 'elm' and id_src = '$id_elm'.";
        next;
    }

    @seqs = $schema->resultset('Seq')->search(
                                              {
                                               'aliases.alias' => $aliases,
                                               'aliases.type' => ['UniProtKB ID', 'UniProtKB accession'],
                                              },
                                              {
                                               join     => 'aliases',
                                               group_by => ['me.id'],
                                               columns  => ['me.id'],
                                              }
                                             );

    if(@seqs == 0) {
        warn "Warning: no sequence with aliases '", join("','", @{$aliases}), "'.";
        next;
    }
    elsif(@seqs > 1) {
        warn "Warning: more than one sequence with aliases '", join("','", @{$aliases}), "'.";
    }

    foreach $seq (@seqs) {
        $tps->{$seq->id}->{$feature->id}->{$start}->{$end}++;
        #print join("\t", 'TP', $seq->id, $feature->id, $start, $end), "\n";
    }
}
close($fh_elm);

# get ELM regex
$query = "SELECT id, regex FROM Feature WHERE source = 'elm'";
$sth = $dbh->prepare($query);
$sth->execute;
$table = $sth->fetchall_arrayref;
$elms = [];
foreach $row (@{$table}) {
    push @{$elms}, {id => $row->[0], regex => $row->[1]};
}

# get sequences
$query = <<END;
SELECT a.id,
       a.seq
FROM   Seq        AS a,
       SeqToTaxon AS b
WHERE  b.id_seq = a.id
END
(@{$sources} > 0) and ($query .= join('', "AND    a.source IN ('", join("', '", @{$sources}), "')\n"));
(@{$taxa} > 0) and ($query .= join('', 'AND    b.id_taxon IN (', join(', ', @{$taxa}), ")\n"));

$sth = $dbh->prepare($query);
$sth->{mysql_use_result} = 1;
$sth->execute;
$id_inst = 0;
while($row = $sth->fetchrow_arrayref) {
    ($id_seq, $aas) = @{$row};
    foreach $elm (@{$elms}) {
        $regex = $elm->{regex};
        while($aas =~ /($regex)/g) {
            $len = length($1);
            $end = pos $aas;
            $start = $end - $len + 1;
            $tp = defined($tps->{$id_seq}->{$elm->{id}}->{$start}->{$end}) ? 1 : 0;

            # FIXME - move this to something like Fist::Utils::Elm and use FeatureInst object
            print(
                  join(
                       "\t",
                       ++$id_inst,
                       $id_seq,
                       $elm->{id},
                       '', # AC
                       $start,
                       $end,
                       1,
                       $len,
                       '', # WT - wild type
                       '', # MT - mutated type
                       0,  # e-value
                       0,  # score
                       $tp,
                       '', # description
                      ),
                  "\n",
                 );
        }
    }
}
