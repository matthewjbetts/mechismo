#!/usr/bin/perl -w

use strict;
use warnings;
use Carp ();
use Getopt::Long;
use Fist::Schema;
use Dir::Self;
use Config::General;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Temp;
use Fist::IO::Alignment;
use Fist::NonDB::SeqGroup;
use Fist::Utils::PBS;
use Fist::Utils::Fork;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $pbs_name;
my $fork_name;
my $max_n_jobs_default = 6
my $max_n_jobs = $max_n_jobs_default;
my $q_max_default = 200;
my $q_max = $q_max_default;
my $feat_source_default = 'Pfam';
my $feat_source = $feat_source_default;
my $ids = [];
my $fn_ids;

# other variables
my $conf;
my $config;
my $schema;
my $cleanup = 1;
my $tempdir;
my $fh_ids;
my $my_ids;
my $id;
my $rs_features;
my $feature;
my $seqs;
my $feature_instance;
my $start;
my $end;
my $len;
my $seq;
my $id_seq;
my $aas;
my $subseq;
my $ac_src;
my @fns_hmms;
my $fn_hmm;
my $bioaln;
my $alignmentio;
my $aln;
my $aseq;
my $seqgroup;
my $feature_instances;
my $id_feature_instance;
my $output;
my $fn;
my $fh;
my $key;
my $name;
my $split;
my $processes;

# parse command line
GetOptions(
	   'help'          => \$help,
           'outdir=s'      => \$dn_out,
           'pbs=s'         => \$pbs_name,
           'fork=s'        => \$fork_name,
           'n_jobs=i'      => \$max_n_jobs,
           'q_max=i'       => \$q_max,
           'feat_source=s' => \$feat_source,
           'id=i'          => $ids,
           'fn_ids=s'      => \$fn_ids,
	  );

defined($help) and usage();
(@ARGV == 0) or usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option          parameter  description                                  default
--------------  ---------  -------------------------------------------  -------
--help          [none]     print this usage info and exit
--outdir        string     directory for output files                   $dn_out_default
--fork          string     run via fork with given string as name       [run locally]
--pbs           string     run via PBS with given string as name        [run locally]
--n_jobs        integer    maximum number of PBS jobs                   $max_n_jobs_default
--q_max         integer    max number of jobs on the scheduler at once  $q_max_default
--feat_source   string     source of features                           $feat_source_default
--id [1]        integer    fist db Feature identifier                   [all features of the given sources]
--fn_ids        string     file of Feature.ids                          [all features of the given sources]

1 - these options can be used more than once

END

    die $usage;
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

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
    $rs_features = $schema->resultset('Feature')->search({id => $ids});
}
else {
    $rs_features = $schema->resultset('Feature')->search({source => $feat_source});
    $ids = [];
    while($feature = $rs_features->next) {
        push @{$ids}, $feature->id;
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
    $output = {};
    foreach $key (qw(SeqGroup Alignment AlignmentToGroup SeqToGroup AlignedSeq)) {
        $output->{$key}->{fn} = "${dn_out}${key}.tsv";
        $fn = $output->{$key}->{fn};
        open($output->{$key}->{fh}, ">$fn") or die "Error: cannot open '$fn' file for writing.";
    }
    $tempdir = File::Temp->newdir(CLEANUP => $cleanup);

    while($feature = $rs_features->next) {
        $seqs = Fist::NonDB::Seqs->new(tempdir => $tempdir, cleanup => $cleanup);
        $feature_instances = {};
        foreach $feature_instance ($feature->feature_insts) {
            $id_feature_instance = $feature_instance->id;
            $seq = $feature_instance->seq;
            $start = $feature_instance->start_seq;
            $end = $feature_instance->end_seq;
            $feature_instances->{$id_feature_instance} = $feature_instance;
            $len = $end - $start + 1;
            $id_seq = $seq->id;
            $aas = $seq->seq;
            $subseq = Fist::NonDB::Seq->new(id => $id_feature_instance, seq => substr($aas, $start - 1, $len));
            $seqs->add_new($subseq);
        }

        if($seqs->n_seqs > 1) {
            $ac_src = $feature->ac_src;
            $seqgroup = Fist::NonDB::SeqGroup->new(type => "Pfam:$ac_src");
            $seqgroup->output_tsv($output->{SeqGroup}->{fh});

            if($ac_src =~ /\.\d+\Z/) {
                $fn_hmm = sprintf "%s/Pfam/hmms/%s.hmm", $ENV{DS}, $ac_src;
                if(!(-e $fn_hmm)) {
                    warn "Error: hmm file '$fn_hmm' does not exist.";
                    next;
                }
            }
            else {
                $fn_hmm = sprintf "%s/Pfam/hmms/%s.*", $ENV{DS}, $ac_src;
                @fns_hmms = glob $fn_hmm;
                if(@fns_hmms > 0) {
                    # get the one with the highest version number
                    @fns_hmms = sort {
                        my $va;
                        my $vb;
                        ($va = $a) =~ s/.*\.(\d+)\.hmm\Z/$1/;
                        ($vb = $b) =~ s/.*\.(\d+)\.hmm\Z/$1/;
                        return $vb <=> $va;
                    } @fns_hmms;
                    $fn_hmm = $fns_hmms[0];
                }
                else {
                    warn "Error: no hmm file for '$ac_src'.";
                    next;
                }
            }

            $bioaln = $seqs->run_hmmalign($fn_hmm);

            $alignmentio = Fist::IO::Alignment->new();
            if(defined($aln = $alignmentio->parse('hmmalign', $bioaln))) {
                # FIXME - get output file handles
                $aln->output_tsv($output->{Alignment}->{fh});
                $fh = $output->{AlignmentToGroup}->{fh};
                print $fh join("\t", $aln->id, $seqgroup->id), "\n";
                foreach $aseq ($aln->aligned_seqs) {
                    $id_feature_instance = $aseq->id_seq;
                    $id_seq = $feature_instances->{$id_feature_instance}->id_seq;
                    $start = $feature_instances->{$id_feature_instance}->start_seq;
                    $end = $feature_instances->{$id_feature_instance}->end_seq;

                    $fh = $output->{SeqToGroup}->{fh};
                    print $fh join("\t", $id_seq, $seqgroup->id, 0), "\n";
                    $fh = $output->{AlignedSeq}->{fh};
                    print $fh join("\t", $aln->id, $id_seq, $start, $end, $aseq->edit_str), "\n";
                }
            }
        }
    }

    foreach $key (keys %{$output}) {
        close($output->{$key}->{fh});
    }
}
