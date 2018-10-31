package Fist::Interface::ContactHit;

use Moose::Role;
use CHI;

use Fist::Utils::JSmol;

=head1 NAME

 Fist::Interface::ContactHit

 A hit between two queries sequences, a1 and b1, and a contact, a2b2, where
 a1 and a2 have similar sequences and b1 and b2 also have similar sequences.

 (May extend to structural similarities at some point in the future. This
 will be easy if these are representable as HSPs.)

=cut

=head1 ACCESSORS

=cut

=head2 id

=cut

requires 'id';

=head2 type

=cut

requires 'type';

=head2 seq_a1

=cut

requires 'seq_a1';

=head2 start_a1

=cut

requires 'start_a1';

=head2 end_a1

=cut

requires 'end_a1';


=head2 seq_b1

=cut

requires 'seq_b1';

=head2 start_b1

=cut

requires 'start_b1';

=head2 end_b1

=cut

requires 'end_b1';

=head2 seq_a2

=cut

requires 'seq_a2';

=head2 start_a2

=cut

requires 'start_a2';

=head2 end_a2

=cut

requires 'end_a2';


=head2 seq_b2

=cut

requires 'seq_b2';

=head2 start_b2

=cut

requires 'start_b2';

=head2 end_b2

=cut

requires 'end_b2';

=head2 contact

=cut

requires 'contact';

=head2 n_res_a1

=cut

requires 'n_res_a1';

=head2 n_res_b1

=cut

requires 'n_res_b1';

=head2 n_resres_a1b1

=cut

requires 'n_resres_a1b1';

=head2 pcid_a

=cut

requires 'pcid_a';

=head2 e_value_a

=cut

requires 'e_value_a';

=head2 pcid_b

=cut

requires 'pcid_b';

=head2 e_value_b

=cut

requires 'e_value_b';

=head2 pcid

=cut

has 'pcid' => (is => 'rw', isa => 'Any');

around 'pcid' => sub {
    my($orig, $self, $pcid) = @_;

    if(defined($pcid)) {
        $self->$orig($pcid);
    }
    else {
        if(!defined($pcid = $self->$orig)) {
            if($self->type eq 'PPI') {
                # get worst (ie. lowest) pcid
                $pcid = ($self->pcid_a <= $self->pcid_b) ? $self->pcid_a : $self->pcid_b;
            }
            else {
                # no b1 - b2 match
                $pcid = $self->pcid_a;
            }
            $self->$orig($pcid);
        }
    }

    return $pcid;
};

=head2 e_value

=cut

has 'e_value' => (is => 'rw', isa => 'Any');

around 'e_value' => sub {
    my($orig, $self, $e_value) = @_;

    if(defined($e_value)) {
        $self->$orig($e_value);
    }
    else {
        if(!defined($e_value = $self->$orig)) {
            if($self->type eq 'PPI') {
                # get worst (ie. highest) e_value
                $e_value = ($self->e_value_a >= $self->e_value_b) ? $self->e_value_a : $self->e_value_b;
            }
            else {
                # no b1 - b2 match
                $e_value = $self->e_value_a;
            }
            $self->$orig($e_value);
        }
    }

    return $e_value;
};

=head2 conf

=cut

has 'conf' => (is => 'rw', isa => 'Any');

around 'conf' => sub {
    my($orig, $self, $conf) = @_;

    $conf = defined($conf) ? $self->$orig($conf) : $self->$orig;

    return $conf;
};

=head2 idcode

=cut

has 'idcode' => (is => 'rw', isa => 'Any');

around 'idcode' => sub {
    my($orig, $self, $idcode) = @_;

    if(defined($idcode)) {
        $self->$orig($idcode);
    }
    else {
        if(!defined($idcode = $self->$orig)) {
            $idcode = $self->contact->frag_inst1->frag->idcode;
            $self->$orig($idcode);
        }
    }

    return $idcode;
};

=head2 hsp_a

 usage   :
 function:
 args    :
 returns :

=cut

requires 'hsp_a';

=head2 hsp_b

 usage   :
 function:
 args    :
 returns :

=cut

requires 'hsp_b';

=head2 hsp_query

 usage   :
 function:
 args    :
 returns :

=cut

requires 'hsp_query';

=head2 hsp_template

 usage   :
 function:
 args    :
 returns :

=cut

requires 'hsp_template';

requires 'id_seq_a1';
requires 'id_seq_b1';
requires 'id_seq_a2';
requires 'id_seq_b2';

=head2 tempdir

 usage   : used internally
 function: get/set temporary directory
 args    : File::Temp::Dir object
 returns : File::Temp::Dir object

=cut

has 'tempdir' => (is => 'rw', isa => 'File::Temp::Dir');

=head2 cleanup

 usage   : used internally
 function: whether or not to delete the temporary files
 args    : boolean
 returns : boolean

=cut

has 'cleanup' => (is => 'rw', isa => 'Bool', default => 1);

=head2 contact

 usage   :
 function:
 args    :
 returns :

=cut

requires 'contact';

=head2 contact_hit_interprets

 usage   :
 function:
 args    :
 returns :

=cut

requires 'contact_hit_interprets';

=head2 best_interprets

 usage   :
 function:
 args    :
 returns :

=cut

sub best_interprets {
    my($self) = @_;

    my @itps;

    @itps = sort {$b->z <=> $a->z} $self->contact_hit_interprets;

    return $itps[0];
}

=head2 add_to_contact_hit_interprets

 usage   :
 function:
 args    :
 returns :

=cut

requires 'add_to_contact_hit_interprets';

=head2 contact_hit_residue_query_hashes

 usage   : ($posns_a1, $posns_b1) = $contact_hit->contact_hit_residue_query_hashes;

           foreach $pos_a1 (sort {$a <=> $b} keys %{$posns_a1}) {
               foreach $pos_b1 ((sort {$a <=> $b} keys %{$posns_a1->{$pos_a1}}) {
                   print "res $pos_a1 in a1 is in contact with res $pos_b1 in b1\n";
               }
           }

           foreach $pos_b1 (sort {$a <=> $b} keys %{$posns_b1}) {
               foreach $pos_a1 ((sort {$a <=> $b} keys %{$posns_b1->{$pos_b1}}) {
                   print "res $pos_b1 in b1 is in contact with res $pos_a1 in a1\n";
               }
           }

 function: get query contact positions as two hashes,
           the first keyed by positions in the a1,
           the second keyed by positions in b1
 args    : none
 returns : two anonymous hashes

=cut

sub contact_hit_residue_query_hashes {
    my($self) = @_;

    my $hash_a1;
    my $hash_b1;
    my $hit_res;

    $hash_a1 = {};
    $hash_b1 = {};
    foreach $hit_res ($self->contact_hit_residues) {
        $hash_a1->{$hit_res->pos_a1}->{$hit_res->pos_b1}++;
        $hash_b1->{$hit_res->pos_b1}->{$hit_res->pos_a1}++;
    }

    return($hash_a1, $hash_b1);
}

=head2 res_contact_table_list

 usage   :
 function: gets contact hit residues with sidechain-sidechain etc info

           $table->{rows}     # rows of data
           $table->{fields}   # keys for rows, eg. $table->{fields}->{pos_a1} gives the column number of 'pos_a1' info in a row
           $table->{a1_to_b1} # row numbers for a particular a1 to b1 residue contact, keyed by query sequence positions, eg $table->{a1_to_b1}->{100}->{120};
           $table->{b1_to_a1} # row numbers for a particular b1 to a1 residue contact, keyed by query sequence positions
 args    :
 returns :

=cut

sub res_contact_table_list {
    my($self, $ss_unmod_only, $posns_a1) = @_;

    my $table;
    my $fist_contacts;
    my $tmpChFile;
    my $cmd;
    my $idsSeqs;
    my $seqs;
    my $strs;
    my $idSeq;
    my $idSeqA1;
    my $idSeqB1;
    my $idSeqA2;
    my $idSeqB2;
    my $seq;
    my $seqA1;
    my $seqB1;
    my $seqA2;
    my $seqB2;
    my $strA1;
    my $strB1;
    my $strA2;
    my $strB2;
    my $idCh;
    my $posA1;
    my $posB1;
    my $posA2;
    my $posB2;
    my $bondType;
    my $bondTypes;
    my $bitMask;
    my $A1A2str;
    my $chrStr;
    my @posns;
    my $i;
    my $j;

    $table = {
              fields => {
                         pos_a1         =>  0,
                         res_a1         =>  1,

                         pos_b1         =>  2,
                         res_b1         =>  3,

                         pos_a2         =>  4,
                         res_a2         =>  5,
                         chain_a2       =>  6,
                         resseq_a2      =>  7,
                         icode_a2       =>  8,

                         pos_b2         =>  9,
                         res_b2         => 10,
                         chain_b2       => 11,
                         resseq_b2      => 12,
                         icode_b2       => 13,

                         sm             => 14,
                         ms             => 15,
                         mm             => 16,
                         ss             => 17,

                         ss_salt        => 18,
                         ss_hbond       => 19,
                         ss_end         => 20,

                         ss_unmod_salt  => 21,
                         ss_unmod_hbond => 22,
                         ss_unmod_end   => 23,

                         res3_a2        => 24,
                         res3_b2        => 25,
                        },
              rows => [],
              a1_to_b1 => {},
              b1_to_a1 => {},
             };

    #printf "ID   : %d\nTYPE : %s\n", $self->id, $self->type;

    $fist_contacts = $self->contact->fist_contacts;

    $idsSeqs = [$self->id_seq_a1, $self->id_seq_b1, $self->id_seq_a2, $self->id_seq_b2];
    $seqs = {};
    $strs = {};
    foreach $idSeq (@{$idsSeqs}) {
        defined($seqs->{$idSeq}) and next;
        if($idSeq == 0) {
            $seqs->{$idSeq} = undef;
            $strs->{$idSeq} = '';
        }
        else {
            $seq = $self->get_seq($idSeq);
            if(defined($seq)) {
                $seqs->{$idSeq} = $seq;
                $strs->{$idSeq} = $seq->seq;
            }
            else {
                $seqs->{$idSeq} = undef;
                $strs->{$idSeq} = '';
            }
        }
    }
    ($seqA1, $idSeqA1, $strA1) = defined($seqs->{$idsSeqs->[0]}) ? ($seqs->{$idsSeqs->[0]}, $idsSeqs->[0], $strs->{$idsSeqs->[0]}) : (undef, '', '');
    ($seqB1, $idSeqB1, $strB1) = defined($seqs->{$idsSeqs->[1]}) ? ($seqs->{$idsSeqs->[1]}, $idsSeqs->[1], $strs->{$idsSeqs->[1]}) : (undef, '', '');
    ($seqA2, $idSeqA2, $strA2) = defined($seqs->{$idsSeqs->[2]}) ? ($seqs->{$idsSeqs->[2]}, $idsSeqs->[2], $strs->{$idsSeqs->[2]}) : (undef, '', '');
    ($seqB2, $idSeqB2, $strB2) = defined($seqs->{$idsSeqs->[3]}) ? ($seqs->{$idsSeqs->[3]}, $idsSeqs->[3], $strs->{$idsSeqs->[3]}) : (undef, '', '');

    $chrStr = $self->chr;
    defined($chrStr) or die("ContactHit ", $self->id);
    foreach $A1A2str (split /;/, $chrStr) {
        @posns = split /,/, $A1A2str;
        $posA1 = $posns[0];
        $posA2 = $posns[1];
        for($i = 2, $j = 3; $j < @posns; $i += 2, $j += 2) {
            $posB1 = $posns[$i];
            $posB2 = $posns[$j];

            if(defined($seqB2)) {
                $bondType = $fist_contacts->{pos}->{$posA2}->{$posB2}->[6];

                defined($bondType) or print(join("\t", 'MISSING', $self->id, $self->contact->id, $posA2, $posB2), "\n");

                # convert bondType using bit masks in c/contact.h
                $bondTypes = [];
                foreach $bitMask (
                                      4, # 0 - SM
                                      2, # 1 - MS
                                      1, # 2 - MM
                                      8, # 3 - SS

                                   2048, # 4 - SS_SALTBRIDGE
                                   1024, # 5 - SS_HBOND
                                   4096, # 6 - SS_BUSINESSEND

                                  16384, # 7 - SS_UNMOD_SALTBRIDGE
                                   8192, # 8 - SS_UNMOD_HBOND
                                  32768, # 9 - SS_UNMOD_BUSINESSEND
                                 ) {
                    push @{$bondTypes}, (($bondType & $bitMask) == $bitMask) ? 1 : 0;
                }
            }
            else {
                # fake bond types for PCIs
                $bondTypes = [1, 1, 1, 1, 0, 0, 1, 0, 0, 1];
            }
            #print @{$bondTypes}, "\n";
            $ss_unmod_only and ($bondTypes->[7] == 0) and ($bondTypes->[8] == 0) and ($bondTypes->[9] == 0) and next;

            push(
                 @{$table->{rows}}, [
                                     $posA1,
                                     $strA1 ? substr($strA1, $posA1 - 1, 1) : '',

                                     $posB1,
                                     $strB1 ? substr($strB1, $posB1 - 1, 1) : '', # always blank for PCI* and PDI*

                                     $posA2,
                                     $strA2 ? substr($strA2, $posA2 - 1, 1) : '',
                                     @{$fist_contacts->{pos}->{$posA2}->{$posB2}}[0..2],

                                     $posB2,
                                     $strB2 ? substr($strB2, $posB2 - 1, 1) : '', # always blank for PCI* and PDI*
                                     @{$fist_contacts->{pos}->{$posA2}->{$posB2}}[3..5],

                                     @{$bondTypes},

                                     @{$fist_contacts->{pos}->{$posA2}->{$posB2}}[7..8],
                                    ],
                );
            #print join("\t", 'RC', @{$table->{rows}->[$#{$table->{rows}}]}), "\n";

            $table->{a1_to_b1}->{$posA1}->{$posB1} = $#{$table->{rows}};
            $table->{b1_to_a1}->{$posB1}->{$posA1} = $#{$table->{rows}};
        }
    }
    #print "//\n";

    return $table;
}

sub res_contact_table_list_v01 {
    my($self, $ss_unmod_only, $posns_a1) = @_;

    my $table;
    my $fist_contacts;
    my $tmpChFile;
    my $cmd;
    my $idsSeqs;
    my $seqs;
    my $strs;
    my $idSeq;
    my $idSeqA1;
    my $idSeqB1;
    my $idSeqA2;
    my $idSeqB2;
    my $seq;
    my $seqA1;
    my $seqB1;
    my $seqA2;
    my $seqB2;
    my $strA1;
    my $strB1;
    my $strA2;
    my $strB2;
    my $idCh;
    my $posA1;
    my $posB1;
    my $posA2;
    my $posB2;
    my $bondType;
    my $bondTypes;
    my $bitMask;
    my $A1A2str;
    my $B2B1str;
    my $hsp_a;
    my $hsp_b;

    $table = {
              fields => {
                         pos_a1         =>  0,
                         res_a1         =>  1,

                         pos_b1         =>  2,
                         res_b1         =>  3,

                         pos_a2         =>  4,
                         res_a2         =>  5,
                         chain_a2       =>  6,
                         resseq_a2      =>  7,
                         icode_a2       =>  8,

                         pos_b2         =>  9,
                         res_b2         => 10,
                         chain_b2       => 11,
                         resseq_b2      => 12,
                         icode_b2       => 13,

                         sm             => 14,
                         ms             => 15,
                         mm             => 16,
                         ss             => 17,

                         ss_salt        => 18,
                         ss_hbond       => 19,
                         ss_end         => 20,

                         ss_unmod_salt  => 21,
                         ss_unmod_hbond => 22,
                         ss_unmod_end   => 23,

                         res3_a2        => 24,
                         res3_b2        => 25,
                        },
              rows => [],
              a1_to_b1 => {},
              b1_to_a1 => {},
             };

    #printf "ID   : %d\nTYPE : %s\n", $self->id, $self->type;

    $fist_contacts = $self->contact->fist_contacts;

    $idsSeqs = [$self->id_seq_a1, $self->id_seq_b1, $self->id_seq_a2, $self->id_seq_b2];
    $seqs = {};
    $strs = {};
    foreach $idSeq (@{$idsSeqs}) {
        defined($seqs->{$idSeq}) and next;
        if($idSeq == 0) {
            $seqs->{$idSeq} = undef;
            $strs->{$idSeq} = '';
        }
        else {
            $seq = $self->get_seq($idSeq);
            if(defined($seq)) {
                $seqs->{$idSeq} = $seq;
                $strs->{$idSeq} = $seq->seq;
            }
            else {
                $seqs->{$idSeq} = undef;
                $strs->{$idSeq} = '';
            }
        }
    }
    ($seqA1, $idSeqA1, $strA1) = defined($seqs->{$idsSeqs->[0]}) ? ($seqs->{$idsSeqs->[0]}, $idsSeqs->[0], $strs->{$idsSeqs->[0]}) : (undef, '', '');
    ($seqB1, $idSeqB1, $strB1) = defined($seqs->{$idsSeqs->[1]}) ? ($seqs->{$idsSeqs->[1]}, $idsSeqs->[1], $strs->{$idsSeqs->[1]}) : (undef, '', '');
    ($seqA2, $idSeqA2, $strA2) = defined($seqs->{$idsSeqs->[2]}) ? ($seqs->{$idsSeqs->[2]}, $idsSeqs->[2], $strs->{$idsSeqs->[2]}) : (undef, '', '');
    ($seqB2, $idSeqB2, $strB2) = defined($seqs->{$idsSeqs->[3]}) ? ($seqs->{$idsSeqs->[3]}, $idsSeqs->[3], $strs->{$idsSeqs->[3]}) : (undef, '', '');

    if(0) {
        $seqA1 = $self->get_seq($self->id_seq_a1);
        $seqB1 = $self->get_seq($self->id_seq_b1);
        $seqA2 = $self->get_seq($self->id_seq_a2);
        $seqB2 = $self->get_seq($self->id_seq_b2);

        ($idSeqA1, $strA1) = defined($seqA1) ? ($seqA1->id, $seqA1->seq) : ('', '');
        ($idSeqB1, $strB1) = defined($seqB1) ? ($seqA1->id, $seqB1->seq) : ('', '');
        ($idSeqA1, $strA2) = defined($seqA2) ? ($seqA2->id, $seqA2->seq) : ('', '');
        ($idSeqB2, $strB2) = defined($seqB2) ? ($seqB2->id, $seqB2->seq) : ('', '');
    }

    # FIXME - create dummy HSPs so that the dummy string creation is done within Hsp.pm rather than hacked together here?
    $A1A2str = defined($hsp_a = $self->hsp_a(undef, $seqA1, $seqA2)) ? $hsp_a->string($seqA1->len, $seqA2->len) : join("\t", '', '', '', '', $idSeqA1, $idSeqA2, ('') x 8);
    $B2B1str = defined($hsp_b = $self->hsp_b(undef, $seqB2, $seqB2)) ? $hsp_b->string_reverse($seqB1->len, $seqB2->len) : join("\t", '', '', '', '', $idSeqB2, $idSeqB1, ('') x 8);

    $tmpChFile = File::Temp->new(DIR => $self->tempdir, UNLINK => 0);

    print $tmpChFile join("\n", $self->id, $self->contact->string, $A1A2str, $B2B1str), "\n";
    #print join("\n", $self->id, $self->contact->string, $A1A2str, $B2B1str), "\n//\n";

    $cmd = "mechismoContactHitResidues < $tmpChFile";
    if(!open(IN, "$cmd |")) {
        Carp::cluck("cannot open pipe from '$cmd'");
        return undef;
    }

    while(<IN>) {
        ($idCh, $posA1, $posB1, $posA2, $posB2) = split;
        $bondType = $fist_contacts->{pos}->{$posA2}->{$posB2}->[6];

        # convert bondType using bit masks in c/contact.h
        $bondTypes = [];
        foreach $bitMask (
                              4, # 0 - SM
                              2, # 1 - MS
                              1, # 2 - MM
                              8, # 3 - SS

                           2048, # 4 - SS_SALTBRIDGE
                           1024, # 5 - SS_HBOND
                           4096, # 6 - SS_BUSINESSEND

                          16384, # 7 - SS_UNMOD_SALTBRIDGE
                           8192, # 8 - SS_UNMOD_HBOND
                          32768, # 9 - SS_UNMOD_BUSINESSEND
                         ) {
            push @{$bondTypes}, (($bondType & $bitMask) == $bitMask) ? 1 : 0;
        }
        #print @{$bondTypes}, "\n";
        $ss_unmod_only and ($bondTypes->[7] == 0) and ($bondTypes->[8] == 0) and ($bondTypes->[9] == 0) and next;

        push(
             @{$table->{rows}}, [
                                 $posA1,
                                 $strA1 ? substr($strA1, $posA1 - 1, 1) : '',

                                 $posB1,
                                 $strB1 ? substr($strB1, $posB1 - 1, 1) : '',

                                 $posA2,
                                 $strA2 ? substr($strA2, $posA2 - 1, 1) : '',
                                 @{$fist_contacts->{pos}->{$posA2}->{$posB2}}[0..2],

                                 $posB2,
                                 $strB2 ? substr($strB2, $posB2 - 1, 1) : '',
                                 @{$fist_contacts->{pos}->{$posA2}->{$posB2}}[3..5],

                                 @{$bondTypes},

                                 @{$fist_contacts->{pos}->{$posA2}->{$posB2}}[7..8],
                                ],
            );
        #print join("\t", 'RC', @{$table->{rows}->[$#{$table->{rows}}]}), "\n";

        $table->{a1_to_b1}->{$posA1}->{$posB1} = $#{$table->{rows}};
        $table->{b1_to_a1}->{$posB1}->{$posA1} = $#{$table->{rows}};
    }
    close(IN);

    #print "//\n";

    return $table;
}

sub get_seq {
    Carp::cluck('not implemented');
}

=head2 jmol_str

 usage   :
 function: gets contact hit residues with sidechain-sidechain etc info
           as a list of lists (first element gives headings).
 args    :
 returns : a string for a2 and a string for b2

=cut

sub jmol_str {
    my($self) = @_;

    my $res_a2;
    my $res_b2;
    my $hit_res;
    my $str_a2;
    my $str_b2;
    my $chain;
    my $resseq;

    $res_a2 = {};
    $res_b2 = {};
    foreach $hit_res ($self->contact_hit_residues) {
        $res_a2->{$hit_res->chain_a2($self)}->{$hit_res->resseq_a2($self)}++;
        $res_b2->{$hit_res->chain_b2($self)}->{$hit_res->resseq_b2($self)}++;
    }

    $str_a2 = [];
    foreach $chain (sort keys %{$res_a2}) {
        foreach $resseq (sort {$a <=> $b} keys %{$res_a2->{$chain}}) {
            push @{$str_a2}, "$resseq$chain";
        }
    }
    if(@{$str_a2} > 0) {
        $str_a2 = (@{$str_a2} > 1) ? join(',', @{$str_a2}) : $str_a2->[0];
        ($self->frag_inst_a2->model > 0) and ($str_a2 = sprintf("model=%d and (%s)", $self->frag_inst_a2->model, $str_a2));
    }
    else {
        $str_a2 = '';
    }

    $str_b2 = [];
    foreach $chain (sort keys %{$res_b2}) {
        foreach $resseq (sort {$a <=> $b} keys %{$res_b2->{$chain}}) {
            push @{$str_b2}, "$resseq$chain";
        }
    }
    if(@{$str_b2} > 0) {
        $str_b2 = (@{$str_b2} > 1) ? join(',', @{$str_b2}) : $str_b2->[0];
        ($self->frag_inst_b2->model > 0) and ($str_b2 = sprintf("model=%d and (%s)", $self->frag_inst_b2->model, $str_b2));
    }
    else {
        $str_b2 = '';
    }

    return($str_a2, $str_b2);
};

=head2 doms

 usage   :
 function:
 args    :
 returns :

=cut

sub doms {
    my($self) = @_;

    return($self->contact->doms);
}

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';
 with 'Fist::Utils::Cache';
 with 'Fist::Utils::DomFile';
 with 'Fist::Utils::Interprets';

=cut

with 'Fist::Utils::UniqueIdentifier';
with 'Fist::Utils::Cache';
with 'Fist::Utils::DomFile';
with 'Fist::Utils::Interprets';

=head1 METHODS

=cut

=head2 template_url

 usage   :
 function: get the URL of the pdb of the template
 args    :
 returns : the URL

=cut

# FIXME - don't hardcode URL root

sub template_url {
    my($self) = @_;

    my $dn;
    my $url;

    if($self->frag_inst_a2->assembly == 0) {
        $url = sprintf "static/data/pdb/%s/pdb%s.ent.gz", substr($self->frag_inst_a2->frag->pdb->idcode, 1, 2), $self->frag_inst_a2->frag->pdb->idcode;
    }
    else {
        $url = sprintf "static/data/pdb-biounit/%s/%s.pdb%s.gz", substr($self->frag_inst_a2->frag->pdb->idcode, 1, 2), $self->frag_inst_a2->frag->pdb->idcode, $self->frag_inst_a2->assembly;
    }

    return $url;
};

=head2 phos_switch_score

 usage   :
 function:
 args    :
 returns :

=cut

sub phos_switch_score {
    my($pcidA, $pcidB, $intra_charge, $inter_charge) = @_;

    #      inter:   3   2   1   0  -1  -2  -3
    # intra  phos
    #     1    -1   1   1   1   0  -1  -1  -1
    #     0    -2   2   2   1   0  -1  -2  -2
    #    -1    -3   3   2   1   0  -1  -2  -3
    #    -2    -4   3   2   1   0  -1  -2  -3
    #    -3    -5   3   2   1   0  -1  -2  -3

    my $fA;
    my $fB;
    my $score;
    my $min;
    my $sign_inter;

    $fA = $pcidA / 100;
    $fB = $pcidB / 100;

    ($intra_charge eq '-') and ($intra_charge = 0);
    ($inter_charge eq '-') and ($inter_charge = 0);

    if($intra_charge > 1) {
        $score = 0;
    }
    else {
        ($min) = sort {$a <=> $b} abs($intra_charge - 2), abs($inter_charge);  # '-2' for the charge on the phosphate
        $sign_inter = ($inter_charge == 0) ? 0 : ($inter_charge / abs($inter_charge));
        $score = $min * $sign_inter;
    }

    $score = $fA * $fB * $score;

    return $score;
}

=head2 jmol_ss_str

 usage   : $self->jsmol_ss_str($posns_a1, $sites_a1, $posns_b1, $sites_b1);
 function: returns various jsmol selection strings for sidechain-sidechain
           contact residues involving the sites at the given positions
 args    : - a reference to an array of integers representing
             positions in the first query sequence
           - a reference to a hash of sites information for the first
             query keyed by sequence position

           [and then the same for the second query sequence]

 returns : - a string containing jsmol/pdb residue identifiers of the site residues
             of the first query
           - a string containing jsmol/pdb identifiers of the atoms in site residues
             that differ from the corresponding residues in the first query
           - a string containing jsmol/pdb identifiers of the last common atoms of
             the site residues and the corresponding residues in the first query
           - a string containing jsmol/pdb identifiers of the site residues of the
             first query that are in contact with the second query

           [and then the same for the second query sequence]

           - a string containing all the jsmol/pdb residue identifiers of all sites
             and residues in contact
           - a reference to a hash keyed by jsmol/pdb residue identifiers with values
             as the corresponding site labels

 returns : - a string containing jsmol/pdb residue identifiers of the
             site residues
           - a string containing jsmol/pdb residue identifiers of the
             atoms in the fragment contact residues that differ from
             the corresponding residues in the query
           - a string containing jsmol/pdb residue identifiers of the
             last common atoms of the fragment contact residues and
             the corresponding residues in the query
           - a reference to a hash keyed by positions in the query
             with values as the corresponding jsmol/pdb residue
             identifiers from the fragment
           - a reference to a hash keyed by jsmol/pdb residue
             identifiers with values as the corresponding site labels

=cut


sub jmol_ss_str {
    my($self, $posns_a1, $sites_a1, $posns_b1, $sites_b1) = @_;

    my $rc;

    my $seq_a1;
    my $id_seq_a1;
    my $aa_a1;
    my $seq_a2;
    my $id_seq_a2;
    my $aa_a2;
    my $aln_a;

    my $seq_b1;
    my $id_seq_b1;
    my $aa_b1;
    my $seq_b2;
    my $id_seq_b2;
    my $aa_b2;
    my $aln_b;

    my $fi_a2;
    my $f_a2;
    my $fist_to_pdb_a2;

    my $fi_b2;
    my $f_b2;
    my $fist_to_pdb_b2;

    my $site_resns_a2;
    my $a1_to_pdbres;
    my $b1_to_pdbres;
    my $labels_by_pdbres;
    my $atomdiffs_a2;
    my $atomdiff_a2;
    my $lcas_a2;
    my $lca_a2;
    my $atomdiffs_b2;
    my $atomdiff_b2;
    my $lcas_b2;
    my $lca_b2;
    my $site_resns_b2;
    my $contact_resns_a2;
    my $contact_resns_b2;
    my $pos_a1;
    my $pos_b1;
    my $row;
    my $res_a1;
    my $res_b1;
    my $res_a2;
    my $res_b2;
    my $pdbres_a2;
    my $pdbres_a2_with_model;
    my $pdbres_b2;
    my $pdbres_b2_with_model;
    my $site;
    my $apos;
    my $pos_a2;
    my $pos_b2;
    my $res_jmol_str;

    $rc = $self->res_contact_table_list;

    $seq_a1 = $self->seq_a1;
    $id_seq_a1 = $seq_a1->id;
    $aa_a1 = $seq_a1->seq;
    $seq_a2 = $self->seq_a2;
    $id_seq_a2 = $seq_a2->id;
    $aa_a2 = $seq_a2->seq;
    $aln_a = $self->hsp_a->aln;

    if(defined($seq_b1 = $self->seq_b1)) {
        $id_seq_b1 = $seq_b1->id;
        $aa_b1 = $seq_b1->seq;
        $seq_b2 = $self->seq_b2;
        $id_seq_b2 = $seq_b2->id;
        $aa_b2 = $seq_b2->seq;
        $aln_b = $self->hsp_b->aln;
    }

    $fi_a2 = $self->contact->frag_inst1;
    $f_a2 = $fi_a2->frag;
    ($fist_to_pdb_a2) = $f_a2->fist_to_pdb;

    $fi_b2 = $self->contact->frag_inst2;
    $f_b2 = $fi_b2->frag;
    ($fist_to_pdb_b2) = $f_b2->fist_to_pdb;

    $site_resns_a2 = {};
    $atomdiffs_a2 = {};
    $lcas_a2 = {};
    $a1_to_pdbres = {};
    $site_resns_b2 = {};
    $atomdiffs_b2 = {};
    $lcas_b2 = {};
    $b1_to_pdbres = {};
    $labels_by_pdbres = {};
    $contact_resns_a2 = {};
    $contact_resns_b2 = {};

    if($posns_a1) {
        foreach $pos_a1 (@{$posns_a1}) {
            if(defined($rc->{a1_to_b1}->{$pos_a1})) {
                foreach $pos_b1 (keys %{$rc->{a1_to_b1}->{$pos_a1}}) {
                    $row = $rc->{rows}->[$rc->{a1_to_b1}->{$pos_a1}->{$pos_b1}];
                    if($row->[$rc->{fields}->{ss_unmod_salt}] or $row->[$rc->{fields}->{ss_unmod_hbond}] or $row->[$rc->{fields}->{ss_unmod_end}]) {
                        $res_a1 = $row->[$rc->{fields}->{res_a1}];
                        $res_b1 = $row->[$rc->{fields}->{res_b1}];
                        $res_a2 = $row->[$rc->{fields}->{res_a2}];
                        $res_b2 = $row->[$rc->{fields}->{res_b2}];

                        $pdbres_a2 = join ':', $row->[$rc->{fields}->{resseq_a2}], $row->[$rc->{fields}->{chain_a2}];
                        $pdbres_a2_with_model = ($fi_a2->model > 0) ? sprintf("(model = %d) and %s", $fi_a2->model, $pdbres_a2) : $pdbres_a2;
                        ($atomdiff_a2 = Fist::Utils::JSmol::pdbres_atomdiff($pdbres_a2, $res_a1, $res_a2)) and $atomdiffs_a2->{$atomdiff_a2}++;
                        ($lca_a2 = Fist::Utils::JSmol::pdbres_lca($pdbres_a2, $res_a1, $res_a2)) and $lcas_a2->{$lca_a2}++;

                        $pdbres_b2 = join ':', $row->[$rc->{fields}->{resseq_b2}], $row->[$rc->{fields}->{chain_b2}];
                        $pdbres_b2_with_model = ($fi_b2->model > 0) ? sprintf("(model = %d) and %s", $fi_b2->model, $pdbres_b2) : $pdbres_b2;
                        ($atomdiff_b2 = Fist::Utils::JSmol::pdbres_atomdiff($pdbres_b2, $res_b1, $res_b2)) and $atomdiffs_b2->{$atomdiff_b2}++;
                        ($lca_b2 = Fist::Utils::JSmol::pdbres_lca($pdbres_b2, $res_b1, $res_b2)) and $lcas_b2->{$lca_b2}++;

                        $site_resns_a2->{$pdbres_a2}++;
                        $contact_resns_a2->{$pdbres_a2}++;
                        $contact_resns_b2->{$pdbres_b2}++;
                        $a1_to_pdbres->{$pos_a1} = $pdbres_a2;

                        $labels_by_pdbres->{$pdbres_a2_with_model} = [];
                        foreach $site (@{$sites_a1->{$pos_a1}->{sites}}) {
                            push @{$labels_by_pdbres->{$pdbres_a2_with_model}}, $site->{label};
                        }
                        $labels_by_pdbres->{$pdbres_a2_with_model} = join('', '"', join(', ', @{$labels_by_pdbres->{$pdbres_a2_with_model}}), '"');

                        if($sites_b1 and defined($sites_b1->{$pos_b1})) {
                            $labels_by_pdbres->{$pdbres_b2_with_model} = [];
                            foreach $site (@{$sites_a1->{$pos_b1}->{sites}}) {
                                push @{$labels_by_pdbres->{$pdbres_b2_with_model}}, $site->{label};
                            }
                            $labels_by_pdbres->{$pdbres_b2_with_model} = join('', '"', join(', ', @{$labels_by_pdbres->{$pdbres_b2_with_model}}), '"');
                        }
                        else {
                            $labels_by_pdbres->{$pdbres_b2_with_model} = "$res_b1$pos_b1";
                        }
                    }
            }
            }
            else {
                $res_a1 = substr($aa_a1, $pos_a1 - 1, 1);
                if($apos = $aln_a->apos_from_pos($id_seq_a1, $pos_a1)) {
                    if($pos_a2 = $aln_a->pos_from_apos($id_seq_a2, $apos)) {
                        $res_a2 = substr($aa_a2, $pos_a2 - 1, 1);
                        $pdbres_a2 = join ':', $fist_to_pdb_a2->{$pos_a2}->[1], $fist_to_pdb_a2->{$pos_a2}->[0];
                        $pdbres_a2_with_model = ($fi_a2->model > 0) ? sprintf("(model = %d) and %s", $fi_a2->model, $pdbres_a2) : $pdbres_a2;
                        ($atomdiff_a2 = Fist::Utils::JSmol::pdbres_atomdiff($pdbres_a2, $res_a1, $res_a2)) and $atomdiffs_a2->{$atomdiff_a2}++;
                        ($lca_a2 = Fist::Utils::JSmol::pdbres_lca($pdbres_a2, $res_a1, $res_a2)) and $lcas_a2->{$lca_a2}++;

                        $site_resns_a2->{$pdbres_a2}++;
                        $a1_to_pdbres->{$pos_a1} = $pdbres_a2;

                        $labels_by_pdbres->{$pdbres_a2_with_model} = [];
                        foreach $site (@{$sites_a1->{$pos_a1}->{sites}}) {
                            push @{$labels_by_pdbres->{$pdbres_a2_with_model}}, $site->{label};
                        }
                        $labels_by_pdbres->{$pdbres_a2_with_model} = join('', '"', join(', ', @{$labels_by_pdbres->{$pdbres_a2_with_model}}), '"');
                    }
                }
            }
        }
    }

    if($posns_b1) {
        foreach $pos_b1 (@{$posns_b1}) {
            if(defined($rc->{b1_to_a1}->{$pos_b1})) {
                foreach $pos_a1 (keys %{$rc->{b1_to_a1}->{$pos_b1}}) {
                    $row = $rc->{rows}->[$rc->{b1_to_a1}->{$pos_b1}->{$pos_a1}];
                    if($row->[$rc->{fields}->{ss_unmod_salt}] or $row->[$rc->{fields}->{ss_unmod_hbond}] or $row->[$rc->{fields}->{ss_unmod_end}]) {
                        $res_a1 = $row->[$rc->{fields}->{res_a1}];
                        $res_b1 = $row->[$rc->{fields}->{res_b1}];
                        $res_a2 = $row->[$rc->{fields}->{res_a2}];
                        $res_b2 = $row->[$rc->{fields}->{res_b2}];

                        $pdbres_a2 = join ':', $row->[$rc->{fields}->{resseq_a2}], $row->[$rc->{fields}->{chain_a2}];
                        $pdbres_a2_with_model = ($fi_a2->model > 0) ? sprintf("(model = %d) and %s", $fi_a2->model, $pdbres_a2) : $pdbres_a2;
                        ($atomdiff_a2 = Fist::Utils::JSmol::pdbres_atomdiff($pdbres_a2, $res_a1, $res_a2)) and $atomdiffs_a2->{$atomdiff_a2}++;
                        ($lca_a2 = Fist::Utils::JSmol::pdbres_lca($pdbres_a2, $res_a1, $res_a2)) and $lcas_a2->{$lca_a2}++;

                        $pdbres_b2 = join ':', $row->[$rc->{fields}->{resseq_b2}], $row->[$rc->{fields}->{chain_b2}];
                        $pdbres_b2_with_model = ($fi_b2->model > 0) ? sprintf("(model = %d) and %s", $fi_b2->model, $pdbres_b2) : $pdbres_b2;
                        ($atomdiff_b2 = Fist::Utils::JSmol::pdbres_atomdiff($pdbres_b2, $res_b1, $res_b2)) and $atomdiffs_b2->{$atomdiff_b2}++;
                        ($lca_b2 = Fist::Utils::JSmol::pdbres_lca($pdbres_b2, $res_b1, $res_b2)) and $lcas_b2->{$lca_b2}++;

                        $site_resns_b2->{$pdbres_b2}++;
                        $contact_resns_b2->{$pdbres_b2}++;
                        $contact_resns_a2->{$pdbres_a2}++;
                        $b1_to_pdbres->{$pos_b1} = $pdbres_b2;

                        $labels_by_pdbres->{$pdbres_a2_with_model} = [];
                        if($sites_a1 and defined($sites_a1->{$pos_a1})) {
                            foreach $site (@{$sites_a1->{$pos_a1}->{sites}}) {
                                push @{$labels_by_pdbres->{$pdbres_a2_with_model}}, $site->{label};
                            }
                            $labels_by_pdbres->{$pdbres_a2_with_model} = join('', '"', join(', ', @{$labels_by_pdbres->{$pdbres_a2_with_model}}), '"');
                        }
                        else {
                            $labels_by_pdbres->{$pdbres_a2_with_model} = "$res_a1$pos_a1";
                        }

                        $labels_by_pdbres->{$pdbres_b2_with_model} = [];
                        foreach $site (@{$sites_b1->{$pos_b1}->{sites}}) {
                            push @{$labels_by_pdbres->{$pdbres_b2_with_model}}, $site->{label};
                        }
                        $labels_by_pdbres->{$pdbres_b2_with_model} = join('', '"', join(', ', @{$labels_by_pdbres->{$pdbres_b2_with_model}}), '"');
                    }
                }
            }
            else {
                $res_b1 = substr($aa_b1, $pos_b1 - 1, 1);
                if($apos = $aln_b->apos_from_pos($id_seq_b1, $pos_b1)) {
                    if($pos_b2 = $aln_b->pos_from_apos($id_seq_b2, $apos)) {
                        $res_b2 = substr($aa_b2, $pos_b2 - 1, 1);
                        $pdbres_b2 = join ':', $fist_to_pdb_b2->{$pos_b2}->[1], $fist_to_pdb_b2->{$pos_b2}->[0];
                        $pdbres_b2_with_model = ($fi_b2->model > 0) ? sprintf("(model = %d) and %s", $fi_b2->model, $pdbres_b2) : $pdbres_b2;
                        ($atomdiff_b2 = Fist::Utils::JSmol::pdbres_atomdiff($pdbres_b2, $res_b1, $res_b2)) and $atomdiffs_b2->{$atomdiff_b2}++;
                        ($lca_b2 = Fist::Utils::JSmol::pdbres_lca($pdbres_b2, $res_b1, $res_b2)) and $lcas_b2->{$lca_b2}++;

                        $site_resns_b2->{$pdbres_b2}++;
                        $b1_to_pdbres->{$pos_b1} = $pdbres_b2;

                        $labels_by_pdbres->{$pdbres_b2_with_model} = [];
                        if($sites_b1 and defined($sites_b1->{$pos_b1})) {
                            foreach $site (@{$sites_b1->{$pos_b1}->{sites}}) {
                                push @{$labels_by_pdbres->{$pdbres_b2_with_model}}, $site->{label};
                            }
                        }
                        $labels_by_pdbres->{$pdbres_b2_with_model} = join('', '"', join(', ', @{$labels_by_pdbres->{$pdbres_b2_with_model}}), '"');
                    }
                }
            }
        }
    }

    $site_resns_a2 = join(', ', sort keys %{$site_resns_a2});
    $site_resns_b2 = join(', ', sort keys %{$site_resns_b2});
    $contact_resns_a2 = join(', ', sort keys %{$contact_resns_a2});
    $contact_resns_b2 = join(', ', sort keys %{$contact_resns_b2});

    $atomdiffs_a2 = join(', ', sort keys %{$atomdiffs_a2});
    $lcas_a2 = join(', ', sort keys %{$lcas_a2});
    $atomdiffs_b2 = join(', ', sort keys %{$atomdiffs_b2});
    $lcas_b2 = join(', ', sort keys %{$lcas_b2});

    if($fi_a2->model > 0) {
        $site_resns_a2 = ($site_resns_a2 ne '') ? sprintf("(model = %d) and (%s)", $fi_a2->model, $site_resns_a2) : '';
        $contact_resns_a2 = ($contact_resns_a2 ne '') ? sprintf("(model = %d) and (%s)", $fi_a2->model, $contact_resns_a2) : '';
        $atomdiffs_a2 = ($atomdiffs_a2 ne '') ? sprintf("(model = %d) and (%s)", $fi_a2->model, $atomdiffs_a2) : '';
        $lcas_a2 = ($lcas_a2 ne '') ? sprintf("(model = %d) and (%s)", $fi_a2->model, $lcas_a2) : '';
    }

    if($fi_b2->model > 0) {
        $site_resns_b2 = ($site_resns_b2 ne '') ? sprintf("(model = %d) and (%s)", $fi_b2->model, $site_resns_b2) : '';
        $contact_resns_b2 = ($contact_resns_b2 ne '') ? sprintf("(model = %d) and (%s)", $fi_b2->model, $contact_resns_b2) : '';
        $atomdiffs_b2 = ($atomdiffs_b2 ne '') ? sprintf("(model = %d) and (%s)", $fi_b2->model, $atomdiffs_b2) : '';
        $lcas_b2 = ($lcas_b2 ne '') ? sprintf("(model = %d) and (%s)", $fi_b2->model, $lcas_b2) : '';
    }

    $res_jmol_str = [];
    $site_resns_a2 and push(@{$res_jmol_str}, $site_resns_a2);
    $contact_resns_a2 and push(@{$res_jmol_str}, $contact_resns_a2);
    $site_resns_b2 and push(@{$res_jmol_str}, $site_resns_b2);
    $contact_resns_b2 and push(@{$res_jmol_str}, $contact_resns_b2);
    $res_jmol_str = join ', ', @{$res_jmol_str};

    return(
           $site_resns_a2,
           $atomdiffs_a2,
           $lcas_a2,
           $contact_resns_a2,

           $site_resns_b2,
           $atomdiffs_b2,
           $lcas_b2,
           $contact_resns_b2,

           $res_jmol_str,
           $labels_by_pdbres,
          );
}

=head2 TO_JSON

 usage   :
 function:
 args    :
 returns :

=cut

sub TO_JSON {
    my($self) = @_;

    my $json;

    $json = {
             id            => $self->id,

             id_seq_a1     => $self->id_seq_a1,
             start_a1      => $self->start_a1,
             end_a1        => $self->end_a1,

             id_seq_b1     => $self->id_seq_b1,
             start_b1      => $self->start_b1,
             end_b1        => $self->end_b1,

             id_seq_a2     => $self->id_seq_a2,
             start_a2      => $self->start_a2,
             end_a2        => $self->end_a2,

             id_seq_b2     => $self->id_seq_b2,
             start_b2      => $self->start_b2,
             end_b2        => $self->end_b2,

             id_contact    => $self->id_contact,

             n_res_a1      => $self->n_res_a1,
             n_res_b1      => $self->n_res_b1,
             n_resres_a1b1 => $self->n_resres_a1b1,
             pcid_a        => $self->pcid_a,
             e_value_a     => $self->e_value_a,
             pcid_b        => $self->pcid_b,
             e_value_b     => $self->e_value_b,
            };

    return $json;
}

=head2 self_jaccard

 usage   :
 function: calc jaccard index of posns_a1 and posns_b1, to identify open and closed homodimers
 args    :
 returns :

=cut

sub self_jaccard {
    my($self) = @_;

    my $chr;
    my $posns_a1;
    my $posns_b1;
    my $union;
    my $intersection;
    my $n_union;
    my $n_intersection;
    my $jaccard;
    my $pos_a1;

    if($self->id_seq_b1 == $self->id_seq_a1) {
        $posns_a1 = {};
        $posns_b1 = {};
        $union = {};
        $intersection = {};
        foreach $chr ($self->contact_hit_residues) {
            $posns_a1->{$chr->pos_a1}++;
            $posns_b1->{$chr->pos_b1}++;
            $union->{$chr->pos_a1}++;
            $union->{$chr->pos_b1}++;
        }

        foreach $pos_a1 (keys %{$posns_a1}) {
            defined($posns_b1->{$pos_a1}) and $intersection->{$pos_a1}++;
        }

        $n_union = scalar keys %{$union};
        $n_intersection = scalar keys %{$intersection};
        $jaccard = ($n_union > 0) ? ($n_intersection / $n_union) : 0;
    }
    else {
        $jaccard = 0;
    }

    return $jaccard;
}

=head2 reverse

 usage   :
 function:
 args    :
 returns :

=cut

sub reverse {
    my($self) = @_;

    my $reverse;

    $reverse = (ref $self)->new(
                                {
                                 id_seq_a1     => $self->id_seq_b1,
                                 start_a1      => $self->start_b1,
                                 end_a1        => $self->end_b1,

                                 id_seq_b1     => $self->id_seq_a1,
                                 start_b1      => $self->start_a1,
                                 end_b1        => $self->end_a1,

                                 id_seq_a2     => $self->id_seq_b2,
                                 start_a2      => $self->start_b2,
                                 end_a2        => $self->end_b2,

                                 id_seq_b2     => $self->id_seq_a2,
                                 start_b2      => $self->start_a2,
                                 end_b2        => $self->end_a2,

                                 id_contact    => $self->id_contact,

                                 n_res_a1      => $self->n_res_b1,
                                 n_res_b1      => $self->n_res_a1,
                                 n_resres_a1b1 => $self->n_resres_a1b1,

                                 pcid_a        => $self->pcid_b,
                                 e_value_a     => $self->e_value_b,

                                 pcid_b        => $self->pcid_a,
                                 e_value_b     => $self->e_value_a,
                                }
                               );

    return $reverse;
}

=head2 output_tsv

 usage   :
 function:
 args    :
 returns :

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print(
          $fh
          join(
               "\t",
               $self->id,

               $self->id_seq_a1,
               $self->start_a1,
               $self->end_a1,

               $self->id_seq_b1,
               $self->start_b1,
               $self->end_b1,

               $self->id_seq_a2,
               $self->start_a2,
               $self->end_a2,

               $self->id_seq_b2,
               $self->start_b2,
               $self->end_b2,

               $self->id_contact,

               $self->n_res_a1,
               $self->n_res_b1,
               $self->n_resres_a1b1,

               $self->pcid_a,
               $self->e_value_a,
               $self->pcid_b,
               $self->e_value_b,
              ),
          "\n",
         );
}

1;
