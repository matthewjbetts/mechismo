#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Dir::Self;
use Config::General;
use Fist::Schema;

# options
my $help;
my $ids = [];
my $sources = [];
my $taxa = [];
my $chemical_types = [];
my $use_primary_id;
my $type_group;

# other variables
my $conf;
my $config;
my $schema;
my $rs_seqs;
my $seq;
my $query;
my $attr;

# parse command line
GetOptions(
	   'help'            => \$help,
           'id=i'            => $ids,
           'source=s'        => $sources,
           'chemical_type=s' => $chemical_types,
           'taxon=i'         => $taxa,
           'primary_id'      => \$use_primary_id,
           'group=s'         => \$type_group,
          );

defined($help) and usage();

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] seqs.fasta

option                 parameter  description                                               default
---------------------  ---------  ---------------- ---------------------------------------  -------
--help                 [none]     print this usage info and exit
--id [1]               integer    fist db sequence identifier                               [all sequences with chemical_type = peptide]
--primary_id           [none]     use primary id                                            [use fist db id]
--source [1,2]         string     source of sequences                                       [all sources]
--chemical_type [1,2]  string     chemical type of sequences                                [all chemical types]
--taxon [1,2]          integer    NCBI taxon ID of sequences                                [all taxa]
--group [2]            string     use only representatives of sequence groups of this type  [all sequences]

1 - these options can be used more than once
2 - ignored if --id used

END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

if(@{$ids} > 0) {
    $rs_seqs = $schema->resultset('Seq')->search({id => $ids});
}
else {
    $query = {len => {'>' => 0}};
    $attr = {};

    (@{$chemical_types} > 0) and ($query->{chemical_type} = $chemical_types);
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
}

foreach $seq ($rs_seqs->all()) {
    $seq->output_fasta(\*STDOUT, $use_primary_id);
}
