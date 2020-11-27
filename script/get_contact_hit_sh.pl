#!/usr/bin/perl -w

use warnings;
use strict;

my $dn;
my $id_taxon;
my $d2;
my $th;
my $id;
my $fn;

$dn = "$ENV{MECHISMO_DN}contact_hits/";

foreach $id_taxon (split(/ /, $ENV{TAXA})) {
    $d2 = "${dn}${id_taxon}/";
    foreach $th ([0.0, 0.8, 0.8]) {
        $id = sprintf "%.1f-%.1f-%.1f", @{$th};
        $fn = "${d2}${id}.sh";
        print "$fn\n";
        open(SH, ">$fn") or die $fn;
        printf(SH "/usr/bin/time -o ${d2}${id}.time ./c/mechismoContactHits \\
  --contacts $ENV{MECHISMO_DN}contacts_with_fist_numbers.tsv.gz \\
  --dom_to_seq $ENV{MECHISMO_DN}frag_inst_to_fist.tsv.gz \\
  --dom_to_chem_type $ENV{MECHISMO_DN}frag_inst_chem_type.tsv.gz \\
  --queries ${d2}queries.txt \\
  --hsps ${d2}query_to_fist.tsv.gz \\
  --contact_to_group $ENV{MECHISMO_DN}contact_groups/${id}.only.ContactToGroup.tsv.gz \\
  --contact_hit ${d2}${id}.ContactHit.tsv \\
  --pcid -1.0 \\
  --lf_fist 0.8 \\
  1> ${d2}${id}.stdout \\
  2> ${d2}${id}.stderr
", @{$th});
        close(SH);
    }
}
