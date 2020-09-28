#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Carp ();
use Dir::Self;
use Config::General;
use File::Temp;
use Fist::Schema;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $pbs_name;
my $fork_name;
my $max_n_jobs_default = 6;
my $max_n_jobs = $max_n_jobs_default;
my $q_max_default = 200;
my $q_max = $q_max_default;
my $feat_source_default = 'Pfam';
my $feat_source = $feat_source_default;
my $hmmdb_default = $ENV{DS} . '/Pfam/Pfam-A.hmm';
my $hmmdb = $hmmdb_default;
my $ids = [];
my $fn_ids;
my $sources = [];
my $taxa = [];
my $e_value;

# other variables
my $tempdir;
my $cleanup = 1;
my $output;
my $conf;
my $config;
my $name;
my $processes;
my $schema;
my $rs_seqs;
my $seq;
my @hsps;
my $hsp;
my $fn_feat_inst;
my $fh_feat_inst;
my @feat_insts;
my $feat_inst;
my $fh_ids;
my $my_ids;
my $split;
my $options;
my $id;

# parse command line
GetOptions(
	   'help'          => \$help,
           'outdir=s'      => \$dn_out,
           'pbs=s'         => \$pbs_name,
           'fork=s'        => \$fork_name,
           'n_jobs=i'      => \$max_n_jobs,
           'q_max=i'       => \$q_max,
           'db=s'          => \$hmmdb,
           'feat_source=s' => \$feat_source,
           'e=f'           => \$e_value,
           'id=i'          => $ids,
           'fn_ids=s'      => \$fn_ids,
           'source=s'      => $sources,
           'taxon=i'       => $taxa,
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

option          parameter  description                                       default
--------------  ---------  ---------------- -------------------------------  -------
--help          [none]     print this usage info and exit
--outdir        string     directory for output files                        $dn_out_default
--fork          string     run via fork with given string as name            [run locally]
--pbs           string     run via PBS with given string as name             [run locally]
--n_jobs        integer    maximum number of PBS jobs                        $max_n_jobs_default
--q_max         integer    max number of jobs on the scheduler at once       $q_max_default
--db            string     hmm database                                      $hmmdb_default
--feat_source   string     source of features                                $feat_source_default
--e             float      maximum E-value                                   [use pfam gathering threshold]
--id [1]        integer    fist db sequence identifier                       [all sequences with chemical_type = peptide]
--fn_ids        string     file of Seq.ids                                   [all Seqs with the given sources]
--source [1,2]  string     source of sequences                               [all sources]
--taxon [1,2]   integer    NCBI taxon ID of sequences                        [all taxa]

1 - these options can be used more than once
2 - ignored if --id used

END

    die $usage;
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

if(!(-e $hmmdb)) {
    die "Error: cannot find '$hmmdb'.";
}
else {
    $hmmdb = abs_path($hmmdb);
}

$tempdir = File::Temp->newdir(CLEANUP => $cleanup);
$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

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

if(@{$ids} > 0) {
    $rs_seqs = $schema->resultset('Seq')->search({id => $ids});
}
else {
    if(@{$sources} > 0) {
        if(@{$taxa} > 0) {
            $rs_seqs = $schema->resultset('Seq')->search(
                                                         {
                                                          chemical_type            => 'peptide',
                                                          source                   => $sources,
                                                          len                      => {'>' => 0},
                                                          'seq_to_taxons.id_taxon' => $taxa,
                                                         },
                                                         {
                                                          join => 'seq_to_taxons',
                                                         }
                                                        );
        }
        else {
            $rs_seqs = $schema->resultset('Seq')->search(
                                                         {
                                                          chemical_type => 'peptide',
                                                          source        => $sources,
                                                          len           => {'>' => 0},
                                                         }
                                                        );
        }
    }
    else {
        if(@{$taxa} > 0) {
            $rs_seqs = $schema->resultset('Seq')->search(
                                                         {
                                                          chemical_type            => 'peptide',
                                                          len                      => {'>' => 0},
                                                          'seq_to_taxons.id_taxon' => $taxa,
                                                         },
                                                         {
                                                          join => 'seq_to_taxons',
                                                         }
                                                        );
        }
        else {
            $rs_seqs = $schema->resultset('Seq')->search(
                                                         {
                                                          chemical_type => 'peptide',
                                                          len           => {'>' => 0},
                                                         }
                                                        );
        }
    }

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

        eval { $processes = Fist::Utils::PBS->new(host => $config->{pbshost}, q_max => $q_max); };
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

    $options = "--db $hmmdb";
    defined($e_value) and ($options .= " --e $e_value");

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

                            # FIXME - might be better if options are passed through automatically
                            options    => $options,
                           );
    $processes->submit;
    $processes->monitor;
}
else {
    $rs_seqs->tempdir($tempdir);
    $rs_seqs->cleanup($cleanup);

    $fn_feat_inst = "${dn_out}FeatureInst.tsv";
    open($fh_feat_inst, ">$fn_feat_inst") or die "Error: cannot open '$fn_feat_inst' file for reading.";

    #@feat_insts = $rs_seqs->run_hmmscan(schema => $schema, source => $feat_source, db => $hmmdb, e => $e_value);
    foreach $id (@{$ids}) {
        $seq = $schema->resultset('Seq')->find({id => $id});
        @feat_insts = $seq->run_hmmscan(schema => $schema, source => $feat_source, db => $hmmdb, e => $e_value);
        foreach $feat_inst (@feat_insts) {
            $feat_inst->output_tsv($fh_feat_inst);
        }
    }

    close($fh_feat_inst);
}

