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
use Fist::NonDB::Seqs;

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
my $blastdb_default = './data/blast/fist';
my $blastdb = $blastdb_default;
my $ids = [];
my $sources = [];
my $taxa = [];
my $type_group;
my $blast_program_default = 'blastp';
my $blast_program = $blast_program_default;
my $e_value_default = 1e-4;
my $e_value = $e_value_default;
my $fns_fasta = [];
my $no_self;

# other variables
my $tempdir;
my $cleanup = 1;
my $output;
my $conf;
my $config;
my $processes;
my $schema;
my $rs_seqs;
my $seq;
my $fn_hsp;
my $fh_hsp;
my $fn_aln;
my $fh_aln;
my $fn_aln_seq;
my $fh_aln_seq;
my $query;
my $attr;
my $name;
my $split;
my $input;
my $switch;
my $options;

# parse command line
GetOptions(
	   'help'      => \$help,
           'outdir=s'  => \$dn_out,
           'pbs=s'     => \$pbs_name,
           'fork=s'    => \$fork_name,
           'n_jobs=i'  => \$max_n_jobs,
           'q_max=i'   => \$q_max,
           'db=s'      => \$blastdb,
           'e=f'       => \$e_value,
           'program=s' => \$blast_program,
           'id=i'      => $ids,
           'source=s'  => $sources,
           'taxon=i'   => $taxa,
           'group=s'   => \$type_group,
           'fasta=s'   => $fns_fasta,
           'no_self'   => \$no_self,
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

option          parameter  description                                                default
--------------  ---------  ---------------- ----------------------------------------  -------
--help          [none]     print this usage info and exit
--program       string     blast program to run                                       $blast_program_default
--outdir        string     directory for output files                                 $dn_out_default
--fork          string     run via fork with given string as name  [run locally]
--pbs           string     run via PBS with given string as name                      [run locally]
--n_jobs        integer    maximum number of PBS jobs                                 $max_n_jobs_default
--q_max         integer    max number of jobs on the scheduler at once                $q_max_default
--db            string     blast database                                             $blastdb_default
--e             float      maximum E-value                                            $e_value_default
--id [1]        integer    fist db sequence identifier                                [all sequences with chemical_type = peptide]
--source [1,2]  string     source of sequences                                        [all sources]
--taxon [1,2]   integer    NCBI taxon ID of sequences                                 [all taxa]
--group [2]     string     use only representatives of sequence groups of this type   [all sequences]
--fasta [1]     string     file of input sequences in fasta format. This option
                           means --id, --source, --taxon and --group are ignored.
                           (--pbs, --n_jobs and --q_max are all ignored too for now)
--no_self       [none]     do not report matches where query and hit id are the
                           same (this assumes that query and hit ids come from the
                           same space)

1 - these options can be used more than once
2 - ignored if --id used

END

    die $usage;
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

if(-e "${blastdb}.pin") {
    ($blastdb = abs_path("${blastdb}.pin")) =~ s/\.pin\Z//;
}
elsif(-e "${blastdb}.nin") {
    ($blastdb = abs_path("${blastdb}.nin")) =~ s/\.nin\Z//;
}
else {
    die "Error: cannot find '$blastdb'.";
}

$tempdir = File::Temp->newdir(CLEANUP => $cleanup);
$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;

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

    if(@{$fns_fasta} > 0) {
        # split fastas

        $input = $fns_fasta;
        $switch = '--fasta';
        $split = sub {
            my($fns, $max_n_jobs) = @_;

            my $n_seqs;
            my $fn;
            my $fh;
            my $n_per_job;
            my $n;
            my $id_input;
            my $fn_out;
            my $fh_out;
            my $n_digits;
            my @inputs;

            @inputs = ();

            # first count the number of sequences
            $n_seqs = 0;
            foreach $fn (@{$fns}) {
                open($fh, $fn) or die "Error: cannot open '$fn' file for reading.";
                while(<$fh>) {
                    /^>/ and ++$n_seqs;
                }
                close($fh);
            }

            # now split the fasta files in to max_n_jobs fasta files
            $n_per_job = sprintf "%.0f", 1 + $n_seqs / $max_n_jobs;
            $n_digits = length($max_n_jobs);
            $n = 0;
            $id_input = 1;
            $fn_out = sprintf "%s%s/%0${n_digits}d.fasta", $dn_out, $name, $id_input;
            push @inputs, [$fn_out];
            open($fh_out, ">$fn_out") or die "Error: cannot open '$fn_out' for writing.";
            foreach $fn (@{$fns}) {
                if(!open($fh, $fn)) {
                    warn "Error: cannot open '$fn' file for reading.";
                    next;
                }
                while(<$fh>) {
                    if(/^>/) {
                        $n++;
                        if($n > $n_per_job) {
                            close($fh_out);
                            ++$id_input;
                            $fn_out = sprintf "%s%s/%0${n_digits}d.fasta", $dn_out, $name, $id_input;
                            open($fh_out, ">$fn_out") or die "Error: cannot open '$fn_out' for writing.";
                            $n = 1;
                            push @inputs, [$fn_out];
                        }
                    }

                    print $fh_out $_;
                }
                close($fh);
            }
            close($fh_out);

            return @inputs;
        }
    }
    else {
        # split ids
        $input = $ids;
        $switch = '--id';
        $split = undef;
    }

    $options = "--db $blastdb --e $e_value --program $blast_program";
    defined($no_self) and ($options .= ' --no_self');

    $processes->create_jobs(
                            name       => $name,
                            input      => $input,
                            split      => $split,
                            max_n_jobs => $max_n_jobs,
                            dn_out     => $dn_out,
                            switch     => $switch,
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
    if(@{$fns_fasta} == 0) {
        $schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
        if(@{$ids} > 0) {
            $rs_seqs = $schema->resultset('Seq')->search({id => $ids});
        }
        else {
            $query = {chemical_type => 'peptide', len => {'>' => 0}};
            $attr = {};

            (@{$sources} > 0) and ($query->{source} = $sources);

            if(@{$taxa} > 0) {
                defined($attr->{join}) or ($attr->{join} = []);
                push @{$attr->{join}}, 'seq_to_taxons';

                $query->{'seq_to_taxons.id_taxon'} = $taxa;
            }

            if(defined($type_group)) {
                defined($attr->{join}) or ($attr->{join} = []);
                push @{$attr->{join}}, {seq_to_groups => 'id_group'};

                $query->{'id_group.type'} = $type_group;
                $query->{'seq_to_groups.rep'} = 1;
            }

            $rs_seqs = $schema->resultset('Seq')->search($query, $attr);
            foreach $seq ($rs_seqs->all()) {
                push @{$ids}, $seq->id;
            }
        }
    }
    else {
        $rs_seqs = Fist::NonDB::Seqs->new();
    }

    $rs_seqs->tempdir($tempdir);
    $rs_seqs->cleanup($cleanup);

    $fn_hsp = "${dn_out}Hsp.tsv";
    open($fh_hsp, ">$fn_hsp") or die "Error: cannot open '$fn_hsp' file for reading.";

    $fn_aln = "${dn_out}Alignment.tsv";
    open($fh_aln, ">$fn_aln") or die "Error: cannot open '$fn_aln' file for reading.";

    $fn_aln_seq = "${dn_out}AlignedSeq.tsv";
    open($fh_aln_seq, ">$fn_aln_seq") or die "Error: cannot open '$fn_aln_seq' file for reading.";

    $rs_seqs->run_blast(
                        db         => $blastdb,
                        program    => $blast_program,
                        e          => $e_value,
                        fasta      => $fns_fasta,
                        fh_hsp     => $fh_hsp,
                        fh_aln     => $fh_aln,
                        fh_aln_seq => $fh_aln_seq,
                        dont_save  => 1,
                        no_self    => $no_self,
                       );

    close($fh_aln_seq);
    close($fh_aln);
    close($fh_hsp);
}
