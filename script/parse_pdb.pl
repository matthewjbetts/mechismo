#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Carp ();
use Fist::IO;
use Fist::IO::Pdb;
use Fist::NonDB::FragInst;
use File::Temp;
use Dir::Self;
use Config::General;
use List::Util qw(shuffle);
use Fist::Utils::UniqueIdentifier;

# options
my $help;
my $nocleanup = 0;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $pbs_name;
my $fork_name;
my $max_n_jobs_default = 6;
my $max_n_jobs = $max_n_jobs_default;
my $q_max_default = 200;
my $q_max = $q_max_default;
my $fn_fofn;
my $fn_ecod;

# other variables
my $cleanup;
my $fh_fofn;
my $output;
my $fn;
my $conf;
my $config;
my $processes;
my @fns1;
my @fns2;
my $dn;
my $dh;
my $tempdir;
my $pdb;
my $frag;
my $cofm;
my $residues;
my $residue;
my $pdbfile;
my $res_mapping;
my $id_contact;
my $ecod;
my $time_start;
my $time_taken;
my $options;
my $prog;
my $name;
my $split;

# parse command line
GetOptions(
	   'help'      => \$help,
           'nocleanup' => \$nocleanup,
           'outdir=s'  => \$dn_out,
           'pbs=s'     => \$pbs_name,
           'fork=s'    => \$fork_name,
           'n_jobs=i'  => \$max_n_jobs,
           'q_max=i'   => \$q_max,
           'fofn=s'    => \$fn_fofn,
           'ecod=s'    => \$fn_ecod,
	  );

$cleanup = $nocleanup ? 0 : 1;
defined($help) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] pdb_file1|pdb_dir1 pdb_file2|pdb_dir2...

option       parameter  description                                  default
---------    ---------  ---------------- --------------------------  -------
--help       [none]     print this usage info and exit
--nocleanup  [none]     do not delete temporary files
--outdir     string     directory for output files                   $dn_out_default
--fork       string     run via fork with given string as name       [run locally]
--pbs        string     run via PBS with given string as name        [run locally]
--n_jobs     integer    maximum number of forked or PBS jobs         $max_n_jobs_default
--q_max      integer    max number of jobs on the scheduler at once  $q_max_default
--fofn       string     file of file names of pdbs
--ecod       string     name of ecod file

END
    die($usage);
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

@fns1 = @ARGV;
if(defined($fn_fofn)) {
    open($fh_fofn, $fn_fofn) or die "Error: cannot open '$fn_fofn' file for reading.";
    while(<$fh_fofn>) {
        while(/(\S+)/g) {
            push @fns1, $1;
        }
    }
    close($fh_fofn);
}
(@fns1 == 0) and usage();

@fns2 = ();
while($fn = shift @fns1) {
    if(-d $fn) {
        $dn = $fn;
        if(!opendir($dh, $dn)) {
            warn "Error: parse: cannot open '$dn' directory.";
        }
        while($fn = readdir $dh) {
            ($fn =~ /\A\./) and next;
            unshift @fns1, "$dn/$fn";
        }
    }
    elsif($fn =~ /\.ent\.gz\Z/) {
        push @fns2, $fn;
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
        my($fns, $max_n_jobs) = @_;

        # split input filenames in to fofns (File(s) Of File Names) so
        # that don't have to give loads of filenames on the command line

        my $n_fns;
        my $n_per_job;
        my $n;
        my $fn;
        my $fn_fofn;
        my $fh_fofn;
        my $id_input;
        my $n_digits;
        my $i;
        my $j;
        my @inputs;

        $n_digits = length($max_n_jobs);
        $n_fns = scalar @{$fns};
        $n_per_job = sprintf "%.0f", 1 + $n_fns / $max_n_jobs;
        $n = 0;
        for($i = 0, $j = $n_per_job - 1, $id_input = 1; $i < $n_fns; $i += $n_per_job, $j += $n_per_job, ++$id_input) {
            ($j >= $n_fns) and ($j = $#{$fns});
            $fn_fofn = sprintf "%s%s/%0${n_digits}d.fofn", $dn_out, $name, $id_input;
            open($fh_fofn, ">$fn_fofn") or die "Error: cannot open '$fn_fofn' for writing.";
            print $fh_fofn join("\n", @{$fns}[$i..$j]), "\n";
            close($fh_fofn);
            push @inputs, ["--fofn $fn_fofn"];
        }

        return @inputs;
    };

    $options = defined($fn_ecod) ? ("--ecod $fn_ecod") : '';

    # related pdbs often have consecutive identifiers. This means
    # that large structures (eg. the ribosome) can be put in the
    # same split job. Randomise the order of filenames to avoid this.
    @fns2 = shuffle @fns2;

    $processes->create_jobs(
                            name       => $name,
                            input      => \@fns2,
                            max_n_jobs => $max_n_jobs,
                            split      => $split,
                            dn_out     => $dn_out,
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
    $output = {};
    Fist::IO->get_fh(
                     $output,
                     $dn_out,
                     ['Pdb',            '.tsv'],
                     ['Frag',           '.tsv'],
                     ['FragInst',       '.tsv'],
                     ['ChainSegment',   '.tsv'],
                     ['SeqGroup',       '.tsv'],
                     ['FragToSeqGroup', '.tsv'],
                     ['Seq',            '.tsv'],
                     ['SeqToGroup',     '.tsv'],
                     ['SeqToTaxon',     '.tsv'],
                     ['FragResMapping', '.tsv'],
                     ['Expdta',         '.tsv'],
                     ['Contact',        '.tsv'],
                     ['ResContact',     '.tsv'],
                     ['FragDssp',       '.tsv'],
                     #['FragNaccess',    '.tsv'], # naccess is not free to industry
                     ['Ecod',           '.tsv'],
                     ['FragToEcod',     '.tsv'],
                    ) or die;

    if(defined($fn_ecod)) {
        $ecod = parse_ecod($fn_ecod);
        output_ecod_hierarchy($ecod, $output->{Ecod}->{fh});
    }

    $tempdir = File::Temp->newdir(CLEANUP => $cleanup);
    $cleanup or print "#tempdir = '$tempdir'\n";
    $id_contact = 0;
    foreach $fn (@fns2) {
        $time_start = time;
        $pdb = parse($fn, $ecod, $output, $tempdir, $cleanup);
        if($pdb->stamp_safe) {
            $pdb->get_contacts(\$id_contact, $output->{Contact}->{fn}, $output->{ResContact}->{fn});
        }
        else {
            warn "Warning: '$fn' is not STAMP safe. Cannot calculate contacts.";
            # FIXME - fix C programs to read multi-chain identifiers
        }

        foreach $frag ($pdb->frags) {
            if($frag->chemical_type eq 'peptide') {
                # write a pdb file for dssp, naccess and other methods that
                # need one containing only the atoms in the fragment
                ($pdbfile, $res_mapping) = $frag->write_pdbfile(undef, '.pdb'); # naccess requires a suffix on the pdb file
                if(defined($pdbfile)) {
                    # run dssp
                    $residues = $frag->run_dssp($pdbfile, $res_mapping);
                    foreach $residue (@{$residues}) {
                        print({$output->{FragDssp}->{fh}} join("\t", @{$residue}), "\n");
                    }

                    # run naccess
                    # FIXME - disabling because naccess is not free to industry
                    # should make this and dssp optional
                    if(0) {
                        $residues = $frag->run_naccess($pdbfile, $res_mapping, $config->{naccess}->{fn_vdw}, $config->{naccess}->{fn_std}, 0.1); # z = 0.1 for rough, quick calculations
                        if(defined($residues)) {
                            foreach $residue (@{$residues}) {
                                print({$output->{FragNaccess}->{fh}} join("\t", @{$residue}), "\n");
                            }
                        }
                    }
                }
            }
        }

        $time_taken = time - $time_start;
        print "#time $fn $time_taken\n";
    }
}

sub parse_ecod {
    my($fn) = @_;

    my $id;
    my $id_ecod;
    my $ecod;
    my $pdb;
    my $domain;
    my $fh;
    my @headings;
    my @F;
    my %hash;
    my $range;
    my $x;
    my $h;
    my $t;
    my $f;
    my $cid;
    my $resSeq1;
    my $resSeq2;
    my $iCode1;
    my $iCode2;
    my $large;
    my $idcode;

    $ecod = {pdbs => {}, hierarchy => {}};
    if(!open($fh, $fn)) {
        warn "Error: parse_ecod: cannot open '$fn' file for reading.";
        return undef;
    }
    $id = 0;
    while(<$fh>) {
        if(s/^#uid/uid/) {
            chomp;
            @headings = split /\t/;
        }
        elsif(/^#/) {
            next;
        }
        else {
            chomp;
            @F = split /\t/;
            @hash{@headings} = @F;
            ($x, $h, $t, $f) = split(/\./, $hash{f_id}, 4);
            defined($ecod->{hierarchy}->{$x}) or ($ecod->{hierarchy}->{$x} = {id => ++$id, name => ($hash{x_name} eq 'NO_X_NAME') ? '' : $hash{x_name} , h => {}});
            defined($ecod->{hierarchy}->{$x}->{hs}->{$h}) or ($ecod->{hierarchy}->{$x}->{hs}->{$h} = {id => ++$id, name => ($hash{h_name} eq 'NO_H_NAME') ? '' : $hash{h_name}, ts => {}});
            defined($ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}) or ($ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t} = {id => ++$id, name => ($hash{t_name} eq 'NO_T_NAME') ? '' : $hash{t_name}, fs => {}});
            if(defined($f)) {
                defined($ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f}) or ($ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f} = {id => ++$id, name => $hash{f_name}});
                $id_ecod = $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f}->{id};
            }
            else {
                $f = '';
                $id_ecod = $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{id};
            }

            if(!defined($pdb = $ecod->{pdbs}->{$hash{pdb}})) {
                $pdb = {idcode => $hash{pdb}, domains => []};
                $ecod->{pdbs}->{$hash{pdb}} = $pdb;
            }
            $domain = {id => $hash{ecod_domain_id}, id_ecod => $id_ecod, hierarchy => [$x, $h, $t, $f], ranges => []};
            push @{$pdb->{domains}}, $domain;
            foreach $range (split /,/, $hash{pdb_range}) {
                if($range =~ /\A(\S+?):(-{0,1}[\d]+)(\S{0,1}?)-(-{0,1}[\d]+)(\S{0,1})\Z/) {
                    ($cid, $resSeq1, $iCode1, $resSeq2, $iCode2) = ($1, $2, $3, $4, $5);
                    ($iCode1 eq '') and ($iCode1 = ' ');
                    ($iCode2 eq '') and ($iCode2 = ' ');
                    push @{$domain->{ranges}}, [$cid, $resSeq1, $iCode1, $cid, $resSeq2, $iCode2];
                    if(length($cid) > 1) {
                        $large->{$pdb->{idcode}}->{$cid}++;
                        #print join("\t", 'MULTICHAIN', $x, $h, $t, $f, $id_ecod, $hash{f_name}, $pdb->{idcode}, $cid), "\n";
                    }
                }
                elsif($range =~ /\A(\S+?):(-{0,1}[\d]+)(\S{0,1})\Z/) {
                    ($cid, $resSeq1, $iCode1) = ($1, $2, $3);
                    ($iCode1 eq '') and ($iCode1 = ' ');
                    push @{$domain->{ranges}}, [$cid, $resSeq1, $iCode1, $cid, $resSeq1, $iCode1];
                    if(length($cid) > 1) {
                        $large->{$pdb->{idcode}}->{$cid}++;
                        #print join("\t", 'MULTICHAIN', $x, $h, $t, $f, $id_ecod, $hash{f_name}, $pdb->{idcode}, $cid), "\n";
                    }
                }
                else {
                    warn "Warning: do not understand '", $pdb->{idcode}, "', range '", $range, "'";
                }
            }
        }
    }
    close($fh);

    #foreach $idcode (sort keys %{$large}) {
    #    warn "Warning: multi-letter chain identifier(s) for '$idcode': ", join(', ', sort keys %{$large->{$idcode}}), '.';
    #}

    return $ecod;
}

sub output_ecod_hierarchy {
    my($ecod, $fh) = @_;

    # FIXME - move all this to Ecod module(s)

    my $x;
    my $h;
    my $t;
    my $f;

    foreach $x (sort {$a <=> $b} keys %{$ecod->{hierarchy}}) {
        print $fh join("\t", $ecod->{hierarchy}->{$x}->{id}, $x, ('\N') x 3, $ecod->{hierarchy}->{$x}->{name}), "\n";
        foreach $h (sort {$a <=> $b} keys %{$ecod->{hierarchy}->{$x}->{hs}}) {
            print $fh join("\t", $ecod->{hierarchy}->{$x}->{hs}->{$h}->{id}, $x, $h, ('\N') x 2, $ecod->{hierarchy}->{$x}->{hs}->{$h}->{name}), "\n";
            foreach $t (sort {$a <=> $b} keys %{$ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}}) {
                print $fh join("\t", $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{id}, $x, $h, $t, '\N', $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{name}), "\n";
                foreach $f (sort {$a <=> $b} keys %{$ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}}) {
                    print $fh join("\t", $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f}->{id}, $x, $h, $t, $f, $ecod->{hierarchy}->{$x}->{hs}->{$h}->{ts}->{$t}->{fs}->{$f}->{name}), "\n";
                }
            }
        }
    }
}


sub parse {
    my($fn, $ecod, $output, $tempdir, $cleanup) = @_;

    my $pdbio;
    my $pdb;
    my $idcode;
    my $res_mapping;
    my $expdta;
    my $frag;
    my $chain_segment;
    my $seq_group;
    my $seqs;
    my $seq;
    my $taxon;
    my $frag_inst;
    my $cids;
    my $cid;
    my $dn_biounit;
    my $fn_biounit;
    my $biounits;
    my $biounit;
    my $assembly;
    my $model;
    my $found;
    my $domain;
    my $range;
    my $cid_to_frag;
    my $start;
    my $end;
    my $dom;
    my $frag_fullchain;
    my $i;
    my $fist_pos;
    my $fist_to_pdb;
    my $res_mappings;
    my $fist_aas;

    eval { $pdbio = Fist::IO::Pdb->new(fn => $fn); };
    if($@) {
        Carp::cluck($@);
        return undef;
    }

    defined($pdb = $pdbio->parse($tempdir, $cleanup)) or return(undef);
    $idcode = $pdb->idcode;
    $pdb->output_tsv($output->{Pdb}->{fh});

    if(defined($ecod) and defined($ecod->{pdbs}->{$idcode})) {
        $cid_to_frag = {};
        foreach $frag ($pdb->frags) {
            ($frag->chemical_type eq 'peptide') or next;

            # assuming all peptide frags up to now are for full chains
            # (which may anyway have been give as eg. 'A 1 _ to A 100 _')
            if($frag->dom =~ /CHAIN (\S+)/) {
                $cid = $1;
            }
            elsif($frag->dom =~ /\A(\S+)\s+\S+\s+\S+\s+to/) {
                $cid = $1;
            }
            else {
                Carp::cluck(sprintf("cannot parse chain identifier from '%s' dom", $frag->dom));
                next;
            }

            if(defined($cid_to_frag->{$cid})) {
                Carp::cluck("frag for chain '$cid' already found.");
                next;
            }
            $cid_to_frag->{$cid} = {frag => $frag, seq => $frag->fist_seq};
        }

        foreach $domain (@{$ecod->{pdbs}->{$idcode}->{domains}}) {
            # is there already a frag for this domain?
            $found = 0;
            if(@{$domain->{ranges}} == 1) {
                $range = $domain->{ranges}->[0];

                if(!defined($frag = $cid_to_frag->{$range->[0]}->{frag})) {
                    Carp::cluck(sprintf("no frag for %s %s", $pdb->idcode, join('', @{$range}[0..2])));
                    next;
                }

                if(!defined($seq = $cid_to_frag->{$range->[0]}->{seq})) {
                    Carp::cluck(sprintf("no seq for %s %s", $pdb->idcode, join('', "'", join("', '", @{$range}[0..2]), "'")));
                    next;
                }

                if(!defined($start = $frag->fist(@{$range}[0..2]))) {
                    Carp::cluck(sprintf("no fist position for %s %s", $pdb->idcode, join('', @{$range}[0..2])));
                    next;
                }

                if(!defined($end = $frag->fist(@{$range}[3..5]))) {
                    Carp::cluck(sprintf("no fist position for %s %s", $pdb->idcode, join('', @{$range}[3..5])));
                    next;
                }

                if(($start == 1) and ($end == $seq->len)) {
                    # this ECOD domain describes this Frag
                    output_tsv($output, 'FragToEcod', $frag->id, $domain->{id_ecod}, 'ecod', $domain->{id});
                    $found = 1;
                }
            }

            if(!$found) {
                # create new frag object
                $dom = [];
                foreach $range (@{$domain->{ranges}}) {
                    push @{$dom}, sprintf("%s %s %s to %s %s %s", @{$range}[0..1], (($range->[2] eq ' ') ? '_' : $range->[2]), @{$range}[3..4], (($range->[5] eq ' ') ? '_' : $range->[5]));
                }
                $dom = join ' ', @{$dom};
                $frag = Fist::NonDB::Frag->new(pdb => $pdb, fullchain => 0, chemical_type => 'peptide', dom => $dom, description => '', tempdir => $pdb->tempdir, cleanup => $pdb->cleanup); # FIXME - set description
                $pdb->add_to_frags($frag);

                # create Seq, ChainSegments and FragResMappings
                $res_mappings = [];
                $found = 0;
                $fist_aas = [];
                $fist_pos = 1;
                foreach $range (@{$domain->{ranges}}) {
                    $chain_segment = Fist::NonDB::ChainSegment->new(
                                                                    frag         => $frag,
                                                                    chain        => $range->[0],
                                                                    resseq_start => $range->[1],
                                                                    icode_start  => $range->[2],
                                                                    resseq_end   => $range->[4],
                                                                    icode_end    => $range->[5],
                                                                   );
                    $frag->add_to_chain_segments($chain_segment);

                    if(!defined($frag_fullchain = $cid_to_frag->{$range->[0]}->{frag})) {
                        Carp::cluck(sprintf("no fullchain frag for %s %s", $pdb->idcode, $range->[0]));
                        next;
                    }

                    if(!defined($start = $frag_fullchain->fist(@{$range}[0..2]))) {
                        Carp::cluck(sprintf("no fist position for %s %s", $pdb->idcode, join('', @{$range}[0..2])));
                        next;
                    }

                    if(!defined($end = $frag_fullchain->fist(@{$range}[3..5]))) {
                        Carp::cluck(sprintf("no fist position for %s %s", $pdb->idcode, join('', @{$range}[3..5])));
                        next;
                    }
                    ++$found;

                    $fist_to_pdb = $frag_fullchain->fist_to_pdb;
                    for($i = $start; $i <= $end; $i++) {
                        push @{$fist_aas}, $fist_to_pdb->{$i}->[4];
                        $res_mapping = Fist::NonDB::FragResMapping->new(
                                                                        id_frag => $frag->id,
                                                                        fist    => $fist_pos++,
                                                                        chain   => $fist_to_pdb->{$i}->[0],
                                                                        resseq  => $fist_to_pdb->{$i}->[1],
                                                                        icode   => $fist_to_pdb->{$i}->[2],
                                                                        res3    => $fist_to_pdb->{$i}->[3],
                                                                        res1    => $fist_to_pdb->{$i}->[4],
                                                                       );
                        push @{$res_mappings}, $res_mapping;
                    }
                }

                if($found == @{$domain->{ranges}}) {
                    foreach $res_mapping (@{$res_mappings}) {
                        $frag->add_to_res_mappings($res_mapping);
                    }

                    # create new seqgroup object
                    $seq_group = Fist::NonDB::SeqGroup->new(type => 'frag');

                    # link the seqgroup to the fragment
                    $frag->add_to_seq_groups($seq_group);

                    # create a new fist sequence and link it to the group
                    $seq = Fist::NonDB::Seq->new(
                                                 seq           => join('', @{$fist_aas}),
                                                 len           => scalar(@{$fist_aas}),
                                                 chemical_type => $frag->chemical_type,
                                                 source        => 'fist',
                                                );
                    $seq_group->add_to_seqs($seq);
                    $frag->id_seq($seq->id);
                }

                # link the Frag to the Ecod entry
                output_tsv($output, 'FragToEcod', $frag->id, $domain->{id_ecod}, 'ecod', $domain->{id});
            }
        }
    }

    foreach $expdta ($pdb->expdtas) {
        $expdta->output_tsv($output->{Expdta}->{fh});
    }

    $biounits = {};
    foreach $frag ($pdb->frags) {
        $frag->output_tsv($output->{Frag}->{fh});

        foreach $chain_segment ($frag->chain_segments) {
            $chain_segment->output_tsv($output->{ChainSegment}->{fh});
        }

        foreach $res_mapping ($frag->res_mappings) {
            $res_mapping->output_tsv($output->{FragResMapping}->{fh});
        }

        foreach $seq_group ($frag->seq_groups) {
            $seq_group->output_tsv($output->{SeqGroup}->{fh});
            output_tsv($output, 'FragToSeqGroup', $frag->id, $seq_group->id);
            foreach $seq ($seq_group->seqs) {
                $seq->output_tsv($output->{Seq}->{fh});
                output_tsv($output, 'SeqToGroup', $seq->id, $seq_group->id, 0); # FIXME - refactor - use object function
                foreach $taxon ($seq->taxa) {
                    output_tsv($output, 'SeqToTaxon', $seq->id, $taxon->id); # FIXME - refactor - use object function
                }
            }
        }

        # create a FragInst for the PDB instance
        $frag_inst = Fist::NonDB::FragInst->new(frag => $frag, assembly => 0, model => 0);
        $frag->add_to_frag_insts($frag_inst);
        $frag_inst->output_tsv($output->{FragInst}->{fh});

        # create a FragInst for every biounit model that contains all the required chains
        $cids = {};
        foreach $chain_segment ($frag->chain_segments) {
            $cids->{$chain_segment->chain}++;
        }

        if(scalar keys %{$cids} == 0) {
            Carp::cluck(sprintf("no chains found for Frag %d { %s }", $frag->id, $frag->dom));
            next;
        }
        else {
            # FIXME - cannot currently store FragInsts that cover more than one model in a
            # biounit. These might arise from SCOP fragments that cover several chains. In
            # any case, without some extra calculations I could not be sure that these
            # different pieces were oriented in the same way wrt. each other as they are
            # in the original PDB from which the SCOP annotation comes.

            $dn_biounit = sprintf "%s/biounit/%s/", $ENV{DS}, substr($idcode, 1, 2);

            if(!defined($biounit = $biounits->{$idcode})) {
                foreach $fn_biounit (glob("$dn_biounit${idcode}-*-*.pdb.gz")) {
                    get_biounits($biounits, $fn_biounit);
                }
                $biounit = $biounits->{$idcode};
            }

            if(defined($biounit)) { # checking again as the above doesn't guarantee that one exists
                foreach $assembly (sort {$a <=> $b} keys %{$biounit}) {
                    foreach $model (sort {$a <=> $b} keys %{$biounit->{$assembly}}) {
                        $found = 0;
                        foreach $cid (keys %{$cids}) {
                            defined($biounit->{$assembly}->{$model}->{$cid}) and $found++;
                        }

                        if($found == scalar keys %{$cids}) {
                            $frag_inst = Fist::NonDB::FragInst->new(frag => $frag, assembly => $assembly, model => $model);
                            $frag->add_to_frag_insts($frag_inst);
                            $frag_inst->output_tsv($output->{FragInst}->{fh});
                        }
                    }
                }
            }
        }
    }

    return $pdb;
}

sub get_biounits {
    my($biounits, $fn) = @_;

    my $dn;
    my $dh;
    my $idcode;
    my $assembly;
    my $model;
    my $pdbio;
    my $cid;

    if(-d $fn) {
        $dn = $fn;
        if(!opendir($dh, $dn)) {
            Carp::cluck("cannot open '$dn' directory");
            return;
        }
        while($fn = readdir $dh) {
            ($fn =~ /\A\./) and next;
            get_biounits($biounits, "$dn/$fn");
        }
        closedir($dh);
    }
    elsif($fn =~ /\A.*\/{0,1}(\S{4})-(\d+)-(\d+)\.pdb\.gz\Z/) {
        ($idcode, $assembly, $model) = ($1, $2, $3);
        eval { $pdbio = Fist::IO::Pdb->new(fn => $fn); };
        if($@) {
            Carp::cluck($@);
            return 0;
        }
        foreach $cid ($pdbio->get_chains) {
            $biounits->{$idcode}->{$assembly}->{$model}->{$cid}++;
            #print join("\t", $idcode, $assembly, $model, $cid), "\n";
        }
    }

    return 1;
}

sub output_tsv {
    my($output, $key, @columns) = @_;

    my $fh;

    if(!defined($output->{$key}) or !defined($output->{$key}->{fh})) {
        Carp::cluck("no file handle for '$key'");
        return 0;
    }
    $fh = $output->{$key}->{fh};

    print $fh join("\t", @columns), "\n";

    return 1;
}
