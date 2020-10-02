#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use Dir::Self;
use Config::General;
use Carp;
use Bio::AlignIO;
use Fist::Schema;
use Fist::IO::Alignment;
use File::Temp;
use File::Path qw(make_path);

# options
my $help;
my $ids = [];
my $fn_ids;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $pbs_name;
my $fork_name;
my $max_n_jobs_default = 6;
my $max_n_jobs = $max_n_jobs_default;
my $types = [];
my $q_max_default = 200;
my $q_max = $q_max_default;

# other variables
my $name;
my $tempdir;
my $cleanup = 1;
my $conf;
my $config;
my $schema;
my $processes;
my $id;
my @seqgroups;
my $seqgroup;
my $bioaln;
my $method;
my $alignmentio;
my $aln;
my $aseq;
my $fn_aln;
my $fh_aln;
my $fn_aln_to_group;
my $fh_aln_to_group;
my $fn_aln_seq;
my $fh_aln_seq;
my $fh_ids;
my $my_ids;
my $split;

# parse command line
GetOptions(
	   'help'     => \$help,
           'id=s'     => $ids,
           'fn_ids=s' => \$fn_ids,
           'outdir=s' => \$dn_out,
           'pbs=s'    => \$pbs_name,
           'fork=s'   => \$fork_name,
           'n_jobs=i' => \$max_n_jobs,
           'q_max=i'  => \$q_max,
           'type=s'   => $types,
	  );

defined($help) and usage();
(@{$ids} > 0) or defined(@{$types} > 0) or usage('one of --id or --type is required');

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option     parameter  description                                  default
---------  ---------  -------------------------------------------  -------
--help     [none]     print this usage info and exit
--id [1]   integer    SeqGroup.id                                  [all SeqGroups of the given type]
--fn_ids   string     file of SeqGroup.ids                         [all SeqGroups of the given type]
--outdir   string     directory for output files                   $dn_out_default
--fork     string     run via fork with given string as name       [run locally]
--pbs      string     run via PBS with given string as name        [run locally]
--n_jobs   integer    maximum number of PBS jobs                   $max_n_jobs_default
--q_max    integer    max number of jobs on the scheduler at once  $q_max_default
--type [1] string     type of seqgroup to align                    [none]
                     (ignored if --id option is used)

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
    # get all groups of the given type(s) and with more than one sequence
    @seqgroups = $schema->resultset('SeqGroup')->search(
                                                        {
                                                         type => $types,
                                                        },
                                                        {
                                                         join     => [qw(seq_to_groups)],
                                                         select   => ['type', 'id', {count => 'seq_to_groups.id_seq'}],
                                                         group_by => [qw(type id)],
                                                         having   => {'COUNT(seq_to_groups.id_seq)' => {'>' => 1}},
                                                        }
                                                       );
    $ids = [];
    foreach $seqgroup (@seqgroups) {
        push @{$ids}, $seqgroup->id;
    }
}


$name = defined($fork_name) ? $fork_name : $pbs_name;
if($name) {
    if($fork_name) {
        require Fist::Utils::Fork;

        eval { $processes = Fist::Utils::Fork->new(); };
        $@ and die "$@";
    }
    elsif($pbs_name) {
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
    $fn_aln = "${dn_out}Alignment.tsv";
    open($fh_aln, ">$fn_aln") or die "Error: cannot open '$fn_aln' file for reading.";

    $fn_aln_to_group = "${dn_out}AlignmentToGroup.tsv";
    open($fh_aln_to_group, ">$fn_aln_to_group") or die "Error: cannot open '$fn_aln_to_group' file for reading.";

    $fn_aln_seq = "${dn_out}AlignedSeq.tsv";
    open($fh_aln_seq, ">$fn_aln_seq") or die "Error: cannot open '$fn_aln_seq' file for reading.";

    foreach $id (@{$ids}) {
        $seqgroup = $schema->resultset('SeqGroup')->find({id => $id});
        if($seqgroup->seqs > 1) {
            $seqgroup->tempdir($tempdir);
            $seqgroup->cleanup($cleanup);
            if($seqgroup->max_len < 10000) {
                $bioaln = $seqgroup->run_muscle;
                $method = 'muscle';
            }
            else {
                $bioaln = $seqgroup->run_kalign;
                $method = 'kalign';
            }

            eval { $alignmentio = Fist::IO::Alignment->new(); };
            $@ and next;
            if(defined($aln = $alignmentio->parse($method, $bioaln))) {
                $aln->output_tsv($fh_aln);
                print $fh_aln_to_group join("\t", $aln->id, $seqgroup->id), "\n";
                foreach $aseq ($aln->aligned_seqs) {
                    print $fh_aln_seq join("\t", $aln->id, $aseq->id_seq, $aseq->start, $aseq->end, $aseq->edit_str), "\n";
                }
            }
        }
    }

    close($fh_aln);
    close($fh_aln_to_group);
    close($fh_aln_seq);

    ((-s $fn_aln) > 0) or unlink($fn_aln, $fn_aln_to_group, $fn_aln_seq);
}
