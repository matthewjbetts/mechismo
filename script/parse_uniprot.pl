#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Fist::IO;
use Fist::IO::Seq;
use Fist::NonDB::Features;
use Fist::NonDB::Feature;
use Fist::NonDB::SeqGroup;

# options
my $help;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;
my $trembl;
my $fn_varsplic;

# other variables
my $features;
my $fn;
my $io;
my $seq;
my $alias;
my $taxon;
my $output;
my $ac_to_taxa;
my $ac_uniprot;
my $ac_to_id;
my $ac_primary_isoform;
my $seq_group;
my $id_seq;
my $rep;
my $fh;

# parse command line
GetOptions(
	   'help'       => \$help,
           'outdir=s'   => \$dn_out,
           'trembl'     => \$trembl,
           'varsplic=s' => \$fn_varsplic,
	  );

defined($help) and usage();
(@ARGV == 0) and usage();

sub usage {
    my($msg) = @_;

    my $prog;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    die <<END;

Usage: $prog [options] uniprot1.dat uniprot2.dat...

option      parameter  description                              default
----------  ---------  ---------------------------------------  -------
--help      [none]     print this usage info and exit
--outdir    string     directory for output files               $dn_out_default
--trembl    [none]     indicates trembl (unreviewed) sequences  sprot (reviewed sequences)
--varsplic             name of fasta file of varsplic seqs

END
}

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

$output = {};
Fist::IO->get_fh(
                 $output,
                 $dn_out,
                 ['Seq',               '.tsv'],
                 ['Alias',             '.tsv'],
                 ['SeqToTaxon',        '.tsv'],
                 ['Feature',           '.tsv'],
                 ['FeatureInst',       '.tsv'],
                 ['PmidToFeatureInst', '.tsv'],
                 ['SeqGroup',          '.tsv'],
                 ['SeqToGroup',        '.tsv'],
                );

defined($features = get_uniprot_feature_types($output->{Feature}->{fh})) or die;

$ac_to_taxa = {};
$ac_to_id = {};
foreach $fn (@ARGV) {
    $io = Fist::IO::Seq->new(fn => $fn);
    while($seq = $io->parse_uniprot($features, $trembl)) {
        output($seq, $ac_to_taxa, $output);

        $ac_uniprot = $seq->primary_id;
        $ac_primary_isoform = ($ac_uniprot =~ /\A(\S+)-(\d+)\Z/) ? $1 : $ac_uniprot;
        defined($ac_to_id->{$ac_primary_isoform}) or ($ac_to_id->{$ac_primary_isoform} = []);
        push @{$ac_to_id->{$ac_primary_isoform}}, $seq->id;
    }
}

if(defined($fn_varsplic)) {
    $io = Fist::IO::Seq->new(fn => $fn_varsplic);
    while($seq = $io->parse_fasta('varsplic', undef, $ac_to_taxa)) {
        output($seq, $ac_to_taxa, $output);

        $ac_uniprot = $seq->primary_id;
        $ac_primary_isoform = ($ac_uniprot =~ /\A(\S+)-(\d+)\Z/) ? $1 : $ac_uniprot;
        defined($ac_to_id->{$ac_primary_isoform}) or ($ac_to_id->{$ac_primary_isoform} = []);
        push @{$ac_to_id->{$ac_primary_isoform}}, $seq->id;
    }
}

$fh = $output->{SeqToGroup}->{fh};
foreach $ac_primary_isoform (keys %{$ac_to_id}) {
    $seq_group = Fist::NonDB::SeqGroup->new(type => 'isoforms');
    $seq_group->output_tsv($output->{SeqGroup}->{fh});
    $rep = 1;
    foreach $id_seq (@{$ac_to_id->{$ac_primary_isoform}}) {
        print $fh join("\t", $id_seq, $seq_group->id, $rep), "\n";
        $rep = 0;
    }
}

sub output {
    my($seq, $ac_to_taxa, $output) = @_;

    my $alias;
    my $taxon;
    my $feature_inst;
    my $pmid;
    my $fh;

    $seq->output_tsv($output->{Seq}->{fh});
    foreach $alias ($seq->aliases) {
        $alias->output_tsv($output->{Alias}->{fh});
    }

    $fh = $output->{SeqToTaxon}->{fh};
    foreach $taxon ($seq->taxa) {
        print $fh join("\t", $seq->id, $taxon->id), "\n";
        $ac_to_taxa->{$seq->primary_id}->{$taxon->id}++;
    }

    $fh = $output->{PmidToFeatureInst}->{fh};
    foreach $feature_inst ($seq->feature_insts) {
        $feature_inst->output_tsv($output->{FeatureInst}->{fh});
        foreach $pmid ($feature_inst->pmids) {
            print $fh join("\t", $feature_inst->id, $pmid), "\n";
        }
    }
}

sub get_uniprot_feature_types {
    my($fh_out) = @_;

    my $cmd;
    my $fh;
    my $key;
    my $value;
    my $features;
    my $feature;
    my $state;
    my $type;
    my $ac_src;

    $cmd = 'wget -q -O - http://web.expasy.org/docs/userman.html';
    if(!open($fh, "$cmd |")) {
        warn "Error: get_uniprot_feature_types: cannot open pipe from '$cmd'.";
        return undef;
    }
    $key = '';

    $features = Fist::NonDB::Features->new();
    $state = '';
    while(<$fh>) {
        if(/<div id="FT_(\S+?)">/) {
            $key = $1;
            $state = 'feature';
        }
        elsif(/<p><b>\s*$key\s*<\/b>\s*-\s*(.*?)\s*(<\/p>)/) {
            $value = $1;
            $feature = Fist::NonDB::Feature->new(source => 'uniprot', ac_src => $key, id_src => $key, description => $value);
            $features->add_new($feature);
            $state = '';
        }
        elsif(/<p><b>\s*$key\s*<\/b>\s*-\s*(.*?)\s*\Z/) {
            $value = $1;
            $state = 'feature_desc';
        }
        elsif(($state eq 'feature_desc') and /(.*?)\s*<\/p>/) {
            $value .= $1;
            $feature = Fist::NonDB::Feature->new(source => 'uniprot', ac_src => $key, id_src => $key, description => $value);
            $features->add_new($feature);
            $state = '';
        }
        elsif($state eq 'feature_desc') {
            chomp;
            $value .= $_;
        }
    }
    close($fh);

    $cmd = 'wget -q -O - http://www.uniprot.org/docs/ptmlist';
    if(!open($fh, "$cmd |")) {
        warn "Error: get_uniprot_feature_types: cannot open pipe from '$cmd'.";
        return undef;
    }
    $type = '';
    $ac_src = '';
    while(<$fh>) {
        if(/^\/{2}/) {
            $feature = Fist::NonDB::Feature->new(source => 'uniprot', ac_src => $ac_src, id_src => $ac_src, type => $type, description => $value);
            $features->add_new($feature);
            $type = '';
            $ac_src = '';
        }
        elsif(/^(\S{2})\s+(\S+.*?)\s*\Z/) {
            ($key, $value) = ($1, $2);
            if($key eq 'ID') {
                $type = $value;
            }
            elsif($key eq 'FT') {
                $ac_src = $value;
            }
        }
    }
    close($fh);


    if(defined($fh_out)) {
        foreach $feature ($features->features) {
            $feature->output_tsv($fh_out);
        }
    }

    return $features;
}

