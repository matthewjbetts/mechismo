#!/usr/bin/perl -w

use strict;

my $r2u;
my @F;
my $site;
my $ac_refseq;
my $ac_uniprot;

open(I, 'Sahni_et_al_Cell_2015_Table_S1A.refseq_to_uniprot.txt') or die;
$r2u = {};
while(<I>) {
    @F = split;
    $r2u->{$F[0]} = $F[1];
}
close(I);

while(<STDIN>) {
    /^Category/ and next;
    chomp;
    @F = split /\t/;
    $site = $F[5];
    if($F[5] =~ /(\S+):p\.(\S+)/) {
        ($ac_refseq, $site) = ($1, $2);
        if(!defined($ac_uniprot = $r2u->{$ac_refseq})) {
            warn "Error: no uniprot for '$ac_refseq'.";
            next;
        }
    }
    else {
        die "Error: do not understand site \"$F[5]\"";
    }
    print "$ac_uniprot/$site \"$F[0]\",allele=$F[3],dbSNP=$F[8],\"$F[9]\"\n";
}
