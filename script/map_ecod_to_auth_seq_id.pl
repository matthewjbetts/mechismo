#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Fist::IO::Ecod;

# options
my $help;
my $dn_cif_default = $ENV{DS} . '/pdb-cif/';
my $dn_cif = $dn_cif_default;
my $fn_ecod;

# other variables
my $ecod_io;
my $ecod;

GetOptions(
	   'help'  => \$help,
           'cif=s' => \$dn_cif,
	  );

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options] ecod.latest.domains.txt

option       parameter  description                                  default
---------    ---------  ---------------- --------------------------  -------
--help       [none]     print this usage info and exit
--cif        string     pdb cif root directory                       $dn_cif_default

END
    die($usage);
}

defined($help) and usage();
defined($fn_ecod = shift @ARGV) or usage();

$ecod_io = Fist::IO::Ecod->new();
$ecod = $ecod_io->parse_ecod_latest_domains($fn_ecod);
map_all_to_auth($ecod);

sub map_all_to_auth {
    my($ecod) = @_;

    my $idcode;
    my $fn_cif;
    my $to_auth_seq_id;
    my $domain;
    my $range;
    my $new_ranges;
    my $cid;
    my $resSeq1;
    my $iCode1;
    my $resSeq2;
    my $iCode2;
    my $resSeq1a;
    my $resSeq2a;
    my $resSeq1b;
    my $resSeq2b;

    foreach $idcode (keys %{$ecod->{pdbs}}) {
        print "# $idcode\n";
        $fn_cif = sprintf "%s/%s/%s.cif.gz", $dn_cif, substr($idcode, 1, 2), $idcode;
        if(!(-e $fn_cif)) {
            warn "Warning: map_all_to_auth: '$fn_cif' not found.";
            next;
        }
        $to_auth_seq_id = pdbx_poly_seq_scheme_to_auth_seq_id($fn_cif);

        foreach $domain (@{$ecod->{pdbs}->{$idcode}->{domains}}) {
            $new_ranges = [];
            foreach $range (@{$domain->{ranges}}) {
                ($cid, $resSeq1, $iCode1, $resSeq2, $iCode2) = @{$range};

                #printf "1: %s:%s%s-%s%s\n", $cid, $resSeq1, $iCode1, $resSeq2, $iCode2;

                $resSeq1a = $resSeq1;
                while(!defined($resSeq1b = $to_auth_seq_id->{$cid}->{$resSeq1a})) {
                    # track forward to next defined position
                    ++$resSeq1a;
                    exists($to_auth_seq_id->{$cid}->{$resSeq1a}) or last; # $resSeq1a is after the end of $cid in $fn_cif
                }
                if(!defined($resSeq1b)) {
                    warn "Error: map_all_to_auth: $cid:$resSeq1 not found in $fn_cif.";
                    next;
                }

                $resSeq2a = $resSeq2;
                while(!defined($resSeq2b = $to_auth_seq_id->{$cid}->{$resSeq2a})) {
                    # track backwards to previous defined position
                    --$resSeq2a;
                    exists($to_auth_seq_id->{$cid->{$resSeq2a}}) or last; # $resSeq2a is after the end of $cid in $fn_cif
                }
                if(!defined($resSeq2b)) {
                    warn "Error: map_all_to_auth: $cid:$resSeq2 not found in $fn_cif.";
                    next;
                }

                if($resSeq2b < $resSeq1b) {
                    warn "Error: map_all_to_auth: $cid:$resSeq1-$resSeq2 not found in $fn_cif.";
                    next;
                }

                push @{$new_ranges}, sprintf "%s:%s%s-%s%s", $cid, $resSeq1b, $iCode1, $resSeq2b, $iCode2;
            }
            print join("\t", $domain->{id}, $domain->{id_ecod}, join(',', @{$new_ranges})), "\n";
        }
    }
}

sub pdbx_poly_seq_scheme_to_auth_seq_id {
    my($fn_cif) = @_;

    my $map;
    my $category;
    my $keyword;
    my $value;
    my $fh_cif;
    my $idcode;
    my $headings;
    my $values;
    my $row;
    my @F;

    if(!open($fh_cif, "zcat $fn_cif |")) {
        warn "Error: pdbx_poly_seq_scheme_to_auth_seq_id: cannot open pipe from 'zcat $fn_cif'.";
        return undef;
    }

    $map = {};
    $category = '';
    $headings = [];
    $values = {};
    while(<$fh_cif>) {
        if(/^#/) {
            ($category eq 'pdbx_poly_seq_schema') and last;

            $category = '';
            $values = {};
            $headings = undef;
        }
        elsif(/^loop_/) {
            # start of table
            $headings = [];
        }
        elsif(/^_entry\.id\s+(\S+)/) {
            ($idcode = $1) =~ tr/[A-Z]/[a-z]/;
        }
        elsif(/^_(\S+?)\.(\S+)\s*\Z/) {
            ($category, $keyword) = ($1, $2);
            defined($headings) and push(@{$headings}, $2);
        }
        elsif(/^_(\S+?)\.(\S+)\s+(.*?)\s*\Z/) {
            ($category, $keyword, $value) = ($1, $2, $3);
            $values->{$category}->{$keyword} = $value;

            # FIXME - deal with values split over several lines
        }
        elsif($category eq 'pdbx_poly_seq_scheme') {
            # ecod.latest.domains.txt column 8 [1-based] ("seqid_range") derives from the text value of the pdb_seq_num child element for the same pdbx_poly_seq_scheme node
            #   - pdbx_poly_seq_scheme:asym_id       = atom_site:label_asym_id
            #   - pdbx_poly_seq_scheme:seq_id        = atom_site:label_seq_id
            #   - pdbx_poly_seq_scheme:pdb_strand_id = atom_site:auth_asym_id = chainID
            #   - pdbx_poly_seq_scheme:pdb_seq_num   = atom_site:auth_seq_id  = resSeq

            @F = split;
            $row = {};
            @{$row}{@{$headings}} = @F;

            # ($row->{auth_seq_num} eq '?') means the position is not resolved in the structure
            $map->{$row->{pdb_strand_id}}->{$row->{seq_id}} = ($row->{auth_seq_num} eq '?') ? undef : $row->{pdb_seq_num};
        }
    }
    close($fh_cif);

    return $map;
}

sub label_to_auth_seq_id {
    my($fn_cif) = @_;

    my $map;
    my $fh_cif;
    my $idcode;
    my $headings;
    my @F;
    my $atom;

    if(!open($fh_cif, "zcat $fn_cif |")) {
        warn "Error: label_to_auth_seq_id: cannot open pipe from 'zcat $fn_cif'.";
        return undef;
    }

    $map = {};
    while(<$fh_cif>) {
        if(/^_entry\.id\s+(\S+)/) {
            ($idcode = $1) =~ tr/[A-Z]/[a-z]/;
        }
        elsif(/^loop_/) {
            $headings = [];
        }
        elsif(/^_atom_site\.(\S+)/) {
            push @{$headings}, $1;
        }
        elsif(/^ATOM/) {
            @F = split;
            $atom = {};
            @{$atom}{@{$headings}} = @F;
            $map->{$atom->{label_asym_id}}->{$atom->{label_seq_id}} = [$atom->{auth_asym_id}, $atom->{auth_seq_id}];
            # auth_asym_id = chainID in old-style pdb format
            # auth_seq_id = resSeq in old-style pdb format
        }
    }
    close($fh_cif);

    return $map;
}

