#!/usr/bin/perl -w

use strict;

use Test::More;

my $cleanup = 0;

my @inputs = (
              # contacts just within pdb
              {prefix => '1m4x.pdb', id_contact => 0},
              {prefix => '2ein.pdb', id_contact => 0},
              {prefix => '3exh.pdb', id_contact => 0}, # phosphoserine (SEP) residues
              {prefix => '12gs.pdb', id_contact => 0}, # HETATM (0HH)
              {prefix => '1cmx.pdb', id_contact => 0}, # HETATM (GLZ)
              {prefix => '3a0b.pdb', id_contact => 0}, # lowercase chain identifiers
              {prefix => '3une.pdb', id_contact => 0}, # lowercase chain identifiers

              # contacts when considering biounit too:

              # pdb has six chains, biounit splits them in to six different assemblies
              {prefix => '3gls.biounit', id_contact => 0, assemblies => 't/3gls.assemblies.txt'},

              # pdb has one chain, biounit combines multiple instances
              # also, has hydrogen atoms (which I am explicitly ignoring for now)
              #{prefix => '1pfi.biounit', id_contact => 0, assemblies => 't/1pfi.assemblies.txt'}, # NOTE - this is wrong in current mechismo db

              # pdb has three chains, biounit combines multiple instances in to a single assembly
              {prefix => '1m4x.biounit', id_contact => 0, assemblies => 't/1m4x.assemblies.txt'},

              # pdb has eight chains, biounit combines multiple instances in to a single assembly
              {prefix => '3c9k.biounit', id_contact => 0, assemblies => 't/3c9k.assemblies.txt'},

              # pdb has two chains, biounit has two assemblies, one with two chains and one with four
              {prefix => '11bg.biounit', id_contact => 0, assemblies => 't/11bg.assemblies.txt'},

              # peptide-chemical interactions
              {prefix => '25c8.biounit', id_contact => 0, assemblies => 't/25c8.assemblies.txt'},
              {prefix => '2i4i.biounit', id_contact => 0, assemblies => 't/2i4i.assemblies.txt'},

              # nucleotide-chemical interactions
              {prefix => '324d.biounit', id_contact => 0, assemblies => 't/324d.assemblies.txt'},

              # nucleotide-nucleotide and nucleotide-chemical interactions
              {prefix => '100d.biounit', id_contact => 0, assemblies => 't/100d.assemblies.txt'},

             );
my $input;
my $prefix;
my @suffixes = qw(.Contact.tsv .ResContact.tsv);
my $suffix;
my $cmd;
my $stat;
my $fh;
my $n0;
my $n1;
my $diff;
my @F;
my $c0;
my $c1;
my $id_contact0;
my $id_contact1;
my $id_fi1;
my $id_fi2;
my $contact0;
my $contact1;
my $rc0;
my $rc1;
my $chain1;
my $resSeq1;
my $iCode1;
my $chain2;
my $resSeq2;
my $iCode2;
my $type0;
my $type1;
my $tolerance = 0.011;
my $n_missing;
my $n_extra;
my $n_diff;
my $n_diff_types;
my $key;
my @bond_types = qw(SM MS MM SS sm_salt sm_hbond sm_vdw ms_salt ms_hbond ms_vdw mm_salt mm_hbond mm_vdw ss_salt ss_hbond ss_vdw ss_end ss_unmod_salt ss_unmod_hbond ss_unmod_vdw ss_unmod_end);
my $i;
my @contact_headings = qw(crystal n_res1 n_res2 n_clash n_resres homo);
my $idMap01;
my $idMap10;

# check that program runs
foreach $input (@inputs) {
    $cmd = sprintf(
                   "./mechismoContacts --intra --both_directions --id_contact %d%s --contacts_out t/tmp/%s.Contact.tsv --res_contacts_out t/tmp/%s.ResContact.tsv < t/%s.dom",
                   $input->{id_contact},
                   defined($input->{assemblies}) ? sprintf(" --assemblies %s", $input->{assemblies}) : '',
                   $input->{prefix},
                   $input->{prefix},
                   $input->{prefix},
                  );
    $stat = system($cmd);
    $stat >>= 8;

    ok(($stat == 0), "running '$cmd'");
}

# compare to expected output
foreach $input (@inputs) {
    $prefix = $input->{prefix};
    foreach $suffix (@suffixes) {
        open($fh, "t/${prefix}${suffix}");
        $n0 = 0;
        while(<$fh>) {
            ++$n0;
        }
        close($fh);

        open($fh, "t/tmp/${prefix}${suffix}");
        ok($fh, "opening 't/tmp/${prefix}${suffix}' file for reading.");
        $n1 = 0;
        while(<$fh>) {
            ++$n1;
        }
        close($fh);

        ok(($n1 == $n0), "number of output lines");
    }

    # detailed comparison of Contacts
    $suffix = '.Contact.tsv';

    open($fh, "t/${prefix}${suffix}");
    $c0 = {};
    while(<$fh>) {
        chomp;
        @F = split /\t/;
        @{$c0->{$F[1]}->{$F[2]}}{('id', @contact_headings)} = ($F[0], @F[3..$#F]);
    }
    close($fh);

    open($fh, "t/tmp/${prefix}${suffix}");
    $c1 = {};
    while(<$fh>) {
        chomp;
        @F = split /\t/;
        @{$c1->{$F[1]}->{$F[2]}}{('id', @contact_headings)} = ($F[0], @F[3..$#F]);
    }
    close($fh);

    $n_missing = 0;
    $n_extra = 0;
    $n_diff = 0;
    foreach $id_fi1 (keys %{$c0}) {
        foreach $id_fi2 (keys %{$c0->{$id_fi1}}) {
            $contact0 = $c0->{$id_fi1}->{$id_fi2};
            if(defined($contact1 = $c1->{$id_fi1}->{$id_fi2})) {
                $idMap01->{$contact0->{id}} = $contact1->{id};
                $idMap10->{$contact1->{id}} = $contact0->{id};
                foreach $key (@contact_headings) {
                    ($key eq 'homo') and next; # homo or hetero dynamic status is set elsewhere

                    if($contact1->{$key} != $contact0->{$key}) {
                        warn "Warning: $key for Contact $id_fi1, $id_fi2 differs for '$prefix'.";
                        ++$n_diff;
                    }
                }
            }
            else {
                warn "Warning: Contact $id_fi1, $id_fi2 is missing for '$prefix'.";
                ++$n_missing;
            }
        }
    }

    foreach $id_fi1 (keys %{$c1}) {
        foreach $id_fi2 (keys %{$c1->{$id_fi1}}) {
            $contact1 = $c1->{$id_fi1}->{$id_fi2};
            if(!defined($contact0 = $c0->{$id_fi1}->{$id_fi2})) {
                warn "Warning: Contact $id_fi1, $id_fi2 is extra for '$prefix'.";
                ++$n_extra;
            }
        }
    }

    ok(($n_missing == 0), "found all expected Contacts for '$prefix'");
    ok(($n_extra == 0), "found no extra Contacts for '$prefix'");
    ok(($n_diff == 0), "common contacts are as expected for '$prefix'");

    # detailed comparison of ResContacts
    $suffix = '.ResContact.tsv';

    open($fh, "t/${prefix}${suffix}");
    $rc0 = {};
    while(<$fh>) {
        chomp;
        @F = split /\t/;
        $rc0->{$F[0]}->{$F[2]}->{$F[3]}->{$F[4]}->{$F[5]}->{$F[6]}->{$F[7]} = {bond_type => $F[1]};
    }
    close($fh);

    open($fh, "t/tmp/${prefix}${suffix}");
    $rc1 = {};
    while(<$fh>) {
        chomp;
        @F = split /\t/;
        $rc1->{$F[0]}->{$F[2]}->{$F[3]}->{$F[4]}->{$F[5]}->{$F[6]}->{$F[7]} = {bond_type => $F[1]};
    }
    close($fh);

    $n_missing = 0;
    $n_extra = 0;
    $n_diff_types = 0;
    foreach $id_contact0 (keys %{$rc0}) {
        foreach $chain1 (keys %{$rc0->{$id_contact0}}) {
            foreach $resSeq1 (keys %{$rc0->{$id_contact0}->{$chain1}}) {
                foreach $iCode1 (keys %{$rc0->{$id_contact0}->{$chain1}->{$resSeq1}}) {
                    foreach $chain2 (keys %{$rc0->{$id_contact0}->{$chain1}->{$resSeq1}->{$iCode1}}) {
                        foreach $resSeq2 (keys %{$rc0->{$id_contact0}->{$chain1}->{$resSeq1}->{$iCode1}->{$chain2}}) {
                            foreach $iCode2 (keys %{$rc0->{$id_contact0}->{$chain1}->{$resSeq1}->{$iCode1}->{$chain2}->{$resSeq2}}) {
                                $type0 = $rc0->{$id_contact0}->{$chain1}->{$resSeq1}->{$iCode1}->{$chain2}->{$resSeq2}->{$iCode2}->{bond_type};
                                if(defined($id_contact1 = $idMap01->{$id_contact0})) {
                                    if(defined($rc1->{$id_contact1}->{$chain1}->{$resSeq1}->{$iCode1}->{$chain2}->{$resSeq2}->{$iCode2})) {
                                        $type1 = $rc1->{$id_contact1}->{$chain1}->{$resSeq1}->{$iCode1}->{$chain2}->{$resSeq2}->{$iCode2}->{bond_type};
                                        if($type1 != $type0) {
                                            ++$n_diff_types;
                                            warn "Warning: $id_contact0 -> $id_contact1, $chain1$resSeq1$iCode1, $chain2$resSeq2$iCode2 bond_type differs for '$prefix'.";
                                        }
                                    }
                                    else {
                                        warn "Warning: $id_contact0 -> $id_contact1, $chain1$resSeq1$iCode1, $chain2$resSeq2$iCode2 missing for '$prefix'.";
                                        ++$n_missing;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    foreach $id_contact1 (keys %{$rc0}) { # specifically testing only for extra residues in the expected contacts
        foreach $chain1 (keys %{$rc1->{$id_contact1}}) {
            foreach $resSeq1 (keys %{$rc1->{$id_contact1}->{$chain1}}) {
                foreach $iCode1 (keys %{$rc1->{$id_contact1}->{$chain1}->{$resSeq1}}) {
                    foreach $chain2 (keys %{$rc1->{$id_contact1}->{$chain1}->{$resSeq1}->{$iCode1}}) {
                        foreach $resSeq2 (keys %{$rc1->{$id_contact1}->{$chain1}->{$resSeq1}->{$iCode1}->{$chain2}}) {
                            foreach $iCode2 (keys %{$rc1->{$id_contact1}->{$chain1}->{$resSeq1}->{$iCode1}->{$chain2}->{$resSeq2}}) {
                                if(defined($id_contact0 = $idMap10->{$id_contact1})) {
                                    if(!defined($rc0->{$id_contact0}->{$chain1}->{$resSeq1}->{$iCode1}->{$chain2}->{$resSeq2}->{$iCode2})) {
                                        warn "Warning: $id_contact0 <- $id_contact1, $chain1$resSeq1$iCode1, $chain2$resSeq2$iCode2 extra for '$prefix'.";
                                        ++$n_extra;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ok(($n_missing == 0), "found all expected ResContacts for '$prefix'");
    ok(($n_extra == 0), "found no extra ResContacts for '$prefix'");
    ok(($n_diff_types == 0), "common ResContacts have the expected bond types for '$prefix'");

}

# clean-up output files
if($cleanup) {
    foreach $input (@inputs) {
        $prefix = $input->{prefix};
        foreach $suffix (@suffixes) {
            unlink "t/tmp/${prefix}${suffix}";
        }
    }
}

done_testing();
