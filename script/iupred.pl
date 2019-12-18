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
use File::Temp;

# options
my $help;
my $ids = [];
my $fn_ids;
my $sources = [];
my $taxa = [];
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $pbs_name;
my $fork_name;
my $max_n_jobs_default = 6
my $max_n_jobs = $max_n_jobs_default;
my $q_max_default = 200;
my $q_max = $q_max_default;

# other variables
my $tempdir;
my $cleanup = 1;
my $conf;
my $config;
my $schema;
my $name;
my $processes;
my $id;
my @seqs;
my $seq;
my $feature;
my $fn_feature_inst;
my $fh_feature_inst;
my @feature_insts;
my $feature_inst;
my $fh_ids;
my $my_ids;
my $split;
my $query;
my $attr;
my $rs_seqs;

# parse command line
GetOptions(
	   'help'     => \$help,
           'id=s'     => $ids,
           'fn_ids=s' => \$fn_ids,
           'source=s' => $sources,
           'taxon=i'  => $taxa,
           'outdir=s' => \$dn_out,
           'pbs=s'    => \$pbs_name,
           'fork=s'   => \$fork_name,
           'n_jobs=i' => \$max_n_jobs,
           'q_max=i'  => \$q_max,
	  );

defined($help) and usage();
(@{$ids} > 0) or defined(@{$sources} > 0) or usage('either --id or --source is required');

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option        parameter  description                                  default
------------  ---------  -------------------------------------------  -------
--help        [none]     print this usage info and exit
--id [1]      integer    Seq.id                                       [all Seqs with the given sources]
--fn_ids      string     file of Seq.ids                              [all Seqs with the given sources]
--source [1]  string     Seq.source (ignored if --id given)           [none]
--taxon [1]   integer    NCBI taxon ID of sequences                   [all taxa]
--outdir      string     directory for output files                   $dn_out_default
--fork        string     run via fork with given string as name       [run locally]
--pbs         string     run via PBS with given string as name        [run locally]
--n_jobs      integer    maximum number of PBS jobs                   $max_n_jobs_default
--q_max       integer    max number of jobs on the scheduler at once  $q_max_default

1 - these options can be used more than once

END

    die $usage;
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

$tempdir = File::Temp->newdir(CLEANUP => $cleanup);

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

$feature = $schema->resultset('Feature')->search({source => 'iupred', ac_src => 'long'})->first();
defined($feature) or die "Error: could not get feature with source = iupred, ac_src = long from db.";

if(defined($fn_ids)) {
    open($fh_ids, $fn_ids) or die "Error: cannot open '$fn_ids' file for reading.";
    $my_ids = {};
    foreach $id (@{$ids}) {
        $my_ids->{$id}++;
    }
    while(<$fh_ids>) {
        while(/(\S+)/g) {
            $my_ids->{$1}++;
        }
    }
    $ids = [sort {$a <=> $b} keys %{$my_ids}];
}

if(@{$ids} == 0) {
    $query = {source => $sources};
    $attr = {select => ['id']}; # only need identifiers
    if(@{$taxa} > 0) {
        defined($attr->{join}) or ($attr->{join} = []);
        push @{$attr->{join}}, 'seq_to_taxons';

        $query->{'seq_to_taxons.id_taxon'} = $taxa;
    }

    $rs_seqs = $schema->resultset('Seq')->search($query, $attr);
    $ids = [];
    foreach $seq ($rs_seqs->all()) {
        push @{$ids}, $seq->id;
    }
}

$name = defined($fork_name) ? $fork_name : $pbs_name;
if($name) {
    if($fork_name) {
        require Fist::Utils::Fork;

        eval { $processes = Fist::Utils::Fork->new(); };
        $@ and die "$@";
    }
    else {
        require Fist::Utils::PBS;

        eval { $processes = Fist::Utils::PBS->new(host => $config->{pbshost}); };
        $@ and die "$@";

        $processes->connect();
        $processes->ssh or die;
    }

    $split = sub {
        my($ids, $max_n_jobs) = @_;

        my $n_ids;
        my $fn;
        my $fh;
        my $n_per_job;
        my $n;
        my $id_input;
        my $fn_out;
        my $fh_out;
        my $n_digits;
        my @inputs;
        my $i;
        my $j;

        @inputs = ();

        $n_ids = scalar @{$ids};

        # now split the ids in to max_n_jobs id files
        $n_per_job = sprintf "%.0f", 1 + $n_ids / $max_n_jobs;
        $n_digits = length($max_n_jobs);
        $n = 0;
        for($i = 0, $j = $n_per_job - 1, $id_input = 1; $i < $n_ids; $i += $n_per_job, $j += $n_per_job, ++$id_input) {
            ($j >= $n_ids) and ($j = $n_ids - 1);
            $fn_out = sprintf "%s%s/%0${n_digits}d.ids", $dn_out, $name, $id_input;
            push @inputs, [$fn_out];
            open($fh_out, ">$fn_out") or die "Error: cannot open '$fn_out' for writing.";
            print $fh_out join("\n", @{$ids}[$i..$j]), "\n";
            close($fh_out);
        }
        return @inputs;
    };

    $processes->create_jobs(
                            name       => $name,
                            input      => $ids,
                            split      => $split,
                            max_n_jobs => $max_n_jobs,
                            dn_out     => $dn_out,
                            switch     => '--fn_ids',
                            out_switch => '--outdir',

                            # FIXME - won't need to do this when FIST is properly installed
                            prog       => 'perl -I${MECHISMO}lib ' . abs_path(__FILE__),
                           );
    $processes->submit;
    $processes->monitor;
}
else {
    $fn_feature_inst = "${dn_out}FeatureInst.tsv";
    open($fh_feature_inst, ">$fn_feature_inst") or die "Error: cannot open '$fn_feature_inst' file for reading.";

    foreach $id (@{$ids}) {
        $seq = $schema->resultset('Seq')->find({id => $id});
        @feature_insts = $seq->run_iupred(feature => $feature);
        foreach $feature_inst (@feature_insts) {
            $feature_inst->output_tsv($fh_feature_inst);
        }
    }

    close($fh_feature_inst);
}
