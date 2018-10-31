#!/usr/bin/perl -w

use JSON::Any;
use strict;

# code copied from Fist::Utils::Search.pm as a quick
# fix for site_table.tsv.gz files created by the previous
# buggy version that missed DNA/DNA information

site_table_to_tsv('-', '-'); # stdin to stdout

sub site_table_to_tsv {
    my($fn_in, $fn_out) = @_;

    my $str;
    my $fh_in;
    my $fh_out;
    my $encoder;
    my $json;
    my @headings;
    my $i;
    my %hash;
    my $general_info;
    my @interaction_info;
    my $ppi;
    my $rc;
    my $intEvLTP;
    my $intEvHTP;
    my $intEvStructure ;
    my $intev;
    my $pci;
    my $pdi;
    my $structure;
    my $n_info;
    my $name;

    if($fn_out =~ /\.gz\Z/) {
        if(!open($fh_out, "| gzip > $fn_out")) {
            warn "Error: cannot pipe to 'gzip > $fn_out'.";
            return 0;
        }
    }
    else {
        if(!open($fh_out, ">$fn_out")) {
            warn "Error: cannot open '$fn_out' file for writing.";
            return 0;
        }
    }

    if($fn_in =~ /\.gz\Z/) {
        if(!open($fh_in, "zcat $fn_in |")) {
            warn "Error: cannot open pipe from 'zcat $fn_in'.";
            return 0;
        }
    }
    else {
        if(!open($fh_in, $fn_in)) {
            warn "Error: cannot open '$fn_in' file for reading.";
            return 0;
        }
    }

    $str = [];
    while(<$fh_in>) {
        push @{$str}, $_;
    }
    $str = join '', @{$str};
    close($fh_in);

    $encoder = JSON::Any->new();
    $json = $encoder->jsonToObj($str);

    @headings = @{$json->[0]};

    # site_table headings:
    # --------------------
    # id_seq
    # name
    # primary_id
    # pos_a1
    # site
    # user_input
    # mismatch
    # blosum62
    # disordered
    # structure
    # nP
    # ppis
    # nC
    # pcis
    # pdis
    # mechProt
    # mechChem
    # mechDNA
    # mechScore

    print(
          $fh_out
          join(
               "\t",

               ## general info
               'name_a1',        # 00
               'primary_id_a1',  # 01
               'id_seq_a1',      # 02
               'pos_a1',         # 03
               'res_a1',         # 04
               'mut_a1',         # 05
               'user input',     # 06
               'mismatch',       # 07
               'blosum62',       # 08
               'iupred',         # 09
               'nS',             # 10
               'nP',             # 11
               'nC',             # 12
               'nD',             # 13
               'mechProt',       # 14
               'mechChem',       # 15
               'mechDNA/RNA',    # 16
               'mech',           # 17

               ## interaction info
               'name_b1',        # 18
               'primary_id_b1',  # 19
               'id_seq_b1',      # 20
               'dimer',          # 21

               'intEvLTP',       # 22
               'intEvHTP',       # 23
               'intEvStructure', # 24
               'intEv',          # 25
               'conf',           # 26
               'ie',             # 27
               'ie_class',       # 28
               'pos_b1',         # 29
               'res_b1',         # 30

               'id_hit',         # 31 - id_contact_hit or id_aln
               'idcode',         # 32
               'assembly',       # 33

               'pcid_a',         # 34
               'e_value_a',      # 35
               'model_a2',       # 36
               'pos_a2',         # 37
               'res_a2',         # 38
               'chain_a2',       # 39
               'resseq_a2',      # 40
               'icode_a2',       # 41

               'pcid_b',         # 42
               'e_value_b',      # 43
               'model_b2',       # 44
               'pos_b2',         # 45
               'res_b2',         # 46
               'chain_b2',       # 47
               'resseq_b2',      # 48
               'icode_b2',       # 49
              ),
          "\n",
         );

    for($i = 1; $i < @{$json}; $i++) {
        @hash{@headings} = @{$json->[$i]};
        $general_info = [
                         $hash{name},
                         $hash{primary_id},
                         $hash{id_seq},
                         $hash{pos_a1},
                         $hash{res1_a1},
                         $hash{res2_a1},
                         $hash{user_input},
                         ($hash{mismatch} eq '') ? 0 : 1,
                         $hash{blosum62},
                         ($hash{disordered} eq "") ? 0 : 1,
                         ($hash{structure} eq "") ? 0 : 1,
                         $hash{nP},
                         $hash{nC},
                         ($hash{pdis} eq "") ? 0 : 1,
                         $hash{mechProt},
                         $hash{mechChem},
                         $hash{mechDNA},
                         $hash{mechScore},
                        ];
        $n_info = 0;

        if(ref $hash{ppis} eq 'ARRAY') {
            foreach $ppi (@{$hash{ppis}}) {
                $name = $ppi->{name_b1};
                _ppi_info($ppi, $name, $encoder, \$n_info, $general_info, $fh_out);
            }
        }

        if(ref $hash{pcis} eq 'ARRAY') {
            foreach $pci (@{$hash{pcis}}) {
                $name = sprintf("[CHEM:%s:%s]", $pci->{type_chem}, $pci->{id_chem});
                _pci_info($pci, $name, $encoder, \$n_info, $general_info, $fh_out);
            }
        }

        if(ref $hash{pdis} eq 'ARRAY') {
            foreach $pdi (@{$hash{pdis}}) {
                $name = '[DNA/RNA]';
                _pci_info($pdi, $name, $encoder, \$n_info, $general_info, $fh_out);
            }
        }

        # structure matches
        if(ref $hash{structure} eq 'ARRAY') {
            foreach $structure (@{$hash{structure}}) {
                ++$n_info;
                @interaction_info = (
                                     '[PROT]',
                                     ('') x 12,
                                     $structure->{id_aln},
                                     $structure->{idcode},
                                     0,
                                     $structure->{pcid},
                                     $structure->{e_value},
                                     0,
                                     $structure->{pos_a2},
                                     $structure->{res_a2},
                                     $structure->{chain_a2},
                                     $structure->{resseq_a2},
                                     $structure->{icode_a2},

                                     ('') x 8,
                                    );
                print $fh_out join("\t", @{$general_info}, @interaction_info), "\n";
            }
        }

        # output the general info on its own if there are no ints or structures
        if($n_info == 0) {
            @interaction_info = ('') x 32;
            print $fh_out join("\t", @{$general_info}, @interaction_info), "\n";
        }
    }

    return 1;
}

sub _ppi_info {
    my($ppi, $name, $encoder, $n_info, $general_info, $fh_out) = @_;

    my @info;
    my $intEvLTP;
    my $intEvHTP;
    my $intEvStructure;
    my $intev;
    my $rc;

    ++${$n_info};
    $intEvLTP = 0;
    $intEvHTP = 0;
    $intEvStructure = 0;
    foreach $intev (@{$ppi->{intev}}) {
        if($intev->{method} eq 'structure') {
            $intEvStructure = 1;
        }

        if($intev->{htp}) {
            $intEvHTP = 1;
        }
        else {
            $intEvLTP = 1;
        }
    }

    foreach $rc (@{$ppi->{rc}}) {
        @info = (
                 $name,                              #  0
                 $ppi->{primary_id_b1},              #  1
                 $ppi->{id_seq_b1},                  #  2
                 ($ppi->{homo} ? 'homo' : 'hetero'), #  3

                 $intEvLTP,                          #  4
                 $intEvHTP,                          #  5
                 $intEvStructure,                    #  6
                 $encoder->encode($ppi->{intev}),    #  7

                 $ppi->{conf},                       #  8
                 $ppi->{ie},                         #  9
                 $ppi->{ie_class},                   # 10
                 $rc->{pos_b1},                      # 11
                 $rc->{res_b1},                      # 12

                 $ppi->{id_ch},                      # 13
                 $ppi->{idcode},                     # 14
                 $ppi->{assembly},                   # 15

                 $ppi->{pcid_a},                     # 16
                 $ppi->{e_value_a},                  # 17
                 $ppi->{model_a},                    # 18
                 $rc->{pos_a2},                      # 19
                 $rc->{res_a2},                      # 20
                 $rc->{chain_a2},                    # 21
                 $rc->{resseq_a2},                   # 22
                 $rc->{icode_a2},                    # 23

                 $ppi->{pcid_b},                     # 24
                 $ppi->{e_value_b},                  # 25
                 $ppi->{model_b},                    # 26
                 $rc->{pos_b2},                      # 27
                 $rc->{res_b2},                      # 28
                 $rc->{chain_b2},                    # 29
                 $rc->{resseq_b2},                   # 30
                 $rc->{icode_b2},                    # 31
                );
        print $fh_out join("\t", @{$general_info}, @info), "\n";
    }

    return 1;
}

sub _pci_info {
    my($pci, $name, $encoder, $n_info, $general_info, $fh_out) = @_;

    my $rc;
    my @info;

    ++${$n_info};
    foreach $rc (@{$pci->{rc}}) {
        @info = (
                 $name,    # 0
                 ('') x 7, # 1-7

                 $pci->{conf},                       #  8
                 $pci->{ie},                         #  9
                 $pci->{ie_class},                   # 10
                 $rc->{pos_b1},                      # 11
                 $rc->{res_b1},                      # 12

                 $pci->{id_ch},                      # 13
                 $pci->{idcode},                     # 14
                 $pci->{assembly},                   # 15

                 $pci->{pcid_a},                     # 16
                 $pci->{e_value_a},                  # 17
                 $pci->{model_a},                    # 18
                 $rc->{pos_a2},                      # 19
                 $rc->{res_a2},                      # 20
                 $rc->{chain_a2},                    # 21
                 $rc->{resseq_a2},                   # 22
                 $rc->{icode_a2},                    # 23

                 '',                                 # 24
                 '',                                 # 25
                 $pci->{model_b},                    # 26
                 $rc->{pos_b2},                      # 27
                 $rc->{res_b2},                      # 28
                 $rc->{chain_b2},                    # 29
                 $rc->{resseq_b2},                   # 30
                 $rc->{icode_b2},                    # 31
                );
        print $fh_out join("\t", @{$general_info}, @info), "\n";
    }

    return 1;
}

