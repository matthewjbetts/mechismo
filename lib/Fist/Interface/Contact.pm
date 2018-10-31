package Fist::Interface::Contact;

use Moose::Role;
use CHI;

=head1 NAME

 Fist::Interface::Contact

=cut

=head1 ACCESSORS

=cut

=head2 id

=cut

requires 'id';

=head2 schema

=cut

requires 'schema';

=head2 frag_inst1

=cut

requires 'frag_inst1';

=head2 id_frag_inst1

=cut

sub id_frag_inst1 {
    my($self) = @_;

    return($self->frag_inst1->id);
}

=head2 frag_inst2

=cut

requires 'frag_inst2';

=head2 id_frag_inst2

=cut

sub id_frag_inst2 {
    my($self) = @_;

    return($self->frag_inst2->id);
}

=head2 crystal

=cut

requires 'crystal';

=head2 n_res1

=cut

requires 'n_res1';

=head2 n_res2

=cut

requires 'n_res2';

=head2 n_clash

=cut

requires 'n_clash';

=head2 n_resres

=cut

requires 'n_resres';

=head2 homo

 usage   :
 function:
 args    :
 returns :

=cut

requires 'homo';

=head2 _type_frag2

 usage   : used internally
 function:
 args    :
 returns :

=cut

has '_type_frag2' => (is => 'rw', isa => 'Str');

=head2 type

 usage   :
 function:
 args    :
 returns :

=cut

sub type_frag2 {
    my($self) = @_;

    my $type;

    if(!defined($type = $self->_type_frag2)) {
        $type = $self->frag_inst2->frag->chemical_type;
        $self->_type_frag2($type);
    }

    return $type;
}

=head2 url

 usage   :
 function: get the URL of the pdb
 args    :
 returns : the URL

=cut

# FIXME - don't hardcode URL root

sub url {
    my($self) = @_;

    my $dn;
    my $url;

    if($self->assembly == 0) {
        $url = sprintf "static/data/pdb/%s/pdb%s.ent.gz", substr($self->frag_inst1->frag->pdb->idcode, 1, 2), $self->frag_inst1->frag->pdb->idcode;
    }
    else {
        $url = sprintf "static/data/pdb-biounit/%s/%s-%s-%s.pdb.gz", substr($self->frag_inst1->frag->pdb->idcode, 1, 2), $self->frag_inst1->frag->pdb->idcode, $self->assembly, $self->model;
    }

    return $url;
};

=head2 _calc_fist_contacts

 usage   :
 function: calculates the residue-residue contacts as positions in the fist sequences
 args    :
 returns :

=cut

requires '_calc_fist_contacts';

=head2 fist_contacts

 usage   : $fist_contacts = $contact->fist_contacts;
 function: get the residue contacts as positions in the fist sequence
 args    : none
 returns : a reference to a hash of hashes, the first key is the position in
           the first sequence, the second key is the position in the second.

=cut

sub fist_contacts {
    my($self) = @_;

    my $fist_contacts;
    my $pos1;
    my $n;

    if(!defined($fist_contacts = $self->cache->get($self->cache_key))) {
        $fist_contacts = $self->_calc_fist_contacts;
        $self->cache->set($self->cache_key, $fist_contacts);
    }

    return $fist_contacts;
}

=head2 calc_aln_contacts

 usage   :
 function: calculates the residue-residue contacts as positions in aligned fist sequences.
           assumes query and template have identical sequences if alignment is undef
 args    :
 returns :

=cut

sub calc_aln_contacts {
    my($self, $fist_contacts, $alnA, $alnB, $id_seqA, $id_seqB) = @_;

    my $aln_contacts;
    my $pos_fistA;
    my $pos_fistB;
    my $pos_alnA;
    my $pos_alnB;
    my $direct;
    my $via_apos;
    my $pos_to_aposA;
    my $pos_to_aposB;
    my $get_posA;
    my $get_posB;

    defined($fist_contacts) or ($fist_contacts = $self->fist_contacts);
    $aln_contacts = {n => 0, pos => {}};

    $| = 1;
    #print join("\t", 'CALC_ALN_CONTACTS', $self->id, scalar keys %{$fist_contacts}), "\n";

    if($fist_contacts->{n} > 0) {
        defined($id_seqA) or ($id_seqA = $self->frag_inst1->frag->fist_seq->id);
        defined($id_seqB) or ($id_seqB = $self->frag_inst2->frag->fist_seq->id);

        if(defined($alnA)) {
            $pos_to_aposA = $alnA->pos_to_apos;
            $get_posA = \&_via_apos;
        }
        else {
            $get_posA = \&_direct;
        }

        if(defined($alnB)) {
            $pos_to_aposB = $alnB->pos_to_apos;
            $get_posB = \&_via_apos;
        }
        else {
            $get_posB = \&_direct;
        }

        foreach $pos_fistA (keys %{$fist_contacts->{pos}}) {
            defined($pos_alnA = $get_posA->($pos_fistA, $id_seqA, $pos_to_aposA)) or next;
            foreach $pos_fistB (keys %{$fist_contacts->{pos}->{$pos_fistA}}) {
                defined($pos_alnB = $get_posB->($pos_fistB, $id_seqB, $pos_to_aposB)) or next;
                $aln_contacts->{pos}->{$pos_alnA}->{$pos_alnB}++;
            }
        }

        foreach $pos_alnA (keys %{$aln_contacts->{pos}}) {
            $aln_contacts->{n} += scalar keys %{$aln_contacts->{pos}->{$pos_alnA}};
        }
    }
    $self->aln_contacts($aln_contacts);

    return $aln_contacts;
}

sub _via_apos {
    my($pos, $id_seq, $pos_to_apos) = @_;

    return $pos_to_apos->{$id_seq}->[$pos];
}

sub _direct {
    my($pos) = @_;

    return $pos;
}

=head2 aln_contacts

 usage   : $aln_contacts = $contact->aln_contacts;
 function: get the residue contacts as positions in the aligned fist sequences
 args    : none
 returns : a reference to a hash of hashes, the first key is the position in
           the first aligned sequence, the second key is the position in the second.
           NOTE: run $contact->calc_aln_contacts($alnA, $alnB) first

=cut

has 'aln_contacts' => (is => 'rw', isa => 'HashRef[Any]');

=head2 doms

 usage   : used internally by roles that require a list of objects with fn, id and dom methods(eg. Fist::Utils::DomFile)
 function:
 args    :
 returns :

=cut

sub doms {
    my($self) = @_;

    return($self->frag_inst1, $self->frag_inst2);
}

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

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';
 with 'Fist::Utils::Cache';
 with 'Fist::Utils::DomFile';
 with 'Fist::Utils::PdbFile';
 with 'Fist::Utils::System';

=cut

with 'Fist::Utils::UniqueIdentifier';
with 'Fist::Utils::Cache';
with 'Fist::Utils::DomFile';
with 'Fist::Utils::PdbFile';
with 'Fist::Utils::System';

=head1 METHODS

=cut

=head2 calc_resres_jaccard

 usage   :
 function:
 args    :
 returns :

=cut

sub calc_resres_jaccard {
    my(
       $self,
       $id_seq_a1,
       $id_seq_b1,
       $contact2,
       $id_seq_a2,
       $id_seq_b2,
       $alnA,
       $alnB,
       $exact_match,
       $threshold_jaccard,
      ) = @_;

    my $positions1;
    my $positions2;
    my $fist_contacts1;
    my $fist_contacts2;
    my $aln_contacts;
    my $fist_contacts;
    my $intersection;
    my $aln_union;
    my $aln_jaccard;
    my $full_union;
    my $full_jaccard;

    $fist_contacts1 = $self->fist_contacts;
    $positions1 = defined($alnA) ? $self->calc_aln_contacts($fist_contacts1, $alnA, $alnB, $id_seq_a1, $id_seq_b1) : $fist_contacts1;

    $fist_contacts2 = $contact2->fist_contacts;
    $positions2 = defined($alnB) ? $contact2->calc_aln_contacts($fist_contacts2, $alnA, $alnB, $id_seq_a2, $id_seq_b2) : $fist_contacts2;

    ($intersection, $aln_union, $aln_jaccard) = _calc_resres_jaccard($positions1, $positions2, $exact_match, $threshold_jaccard);
    $full_union = $self->n_resres + $contact2->n_resres - $intersection;
    $full_jaccard = $full_union ? ($intersection / $full_union) : 0;

    return($intersection, $positions1->{n}, $positions2->{n}, $aln_union, $aln_jaccard, $full_union, $full_jaccard);
}

=head2 _get_frag_seq_id

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_frag_seq_id { # FIXME - put this somewhere central, eg Fist::ResultSet::Schema::Frag (and require in Interface)
    my($frag_to_seq, $schema, $id_frag, $source) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $id_seq;

    if(!defined($id_seq = $frag_to_seq->{$id_frag})) {
        $dbh = $schema->storage->dbh;
        $query = <<END;
SELECT s.id
FROM   FragToSeqGroup   AS f_to_sg,
       SeqGroup         AS sg,
       SeqToGroup       AS s_to_sg,
       Seq              AS s
WHERE  f_to_sg.id_frag = ?
AND    sg.id = f_to_sg.id_group
AND    sg.type = 'frag'
AND    s_to_sg.id_group = sg.id
AND    s.id = s_to_sg.id_seq
AND    s.source = ?
ORDER BY s.id
END
        $sth = $dbh->prepare($query);
        $sth->execute($id_frag, $source);
        $table = $sth->fetchall_arrayref;
        if(@{$table} == 1) {
            $id_seq = $table->[0]->[0];
            $frag_to_seq->{$id_frag} = $id_seq;
        }
        elsif(@{$table} > 1) {
            Carp::cluck("more than one $source seq for frag $id_frag. Using first.");
            $id_seq = $table->[0]->[0];
            $frag_to_seq->{$id_frag} = $id_seq;
        }
        else {
            Carp::cluck("no $source seq for frag $id_frag.");
            $id_seq = undef;
        }
    }

    return $id_seq;
}

=head2 _get_frags_seq_ids

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_frags_seq_ids { # FIXME - put this somewhere central, eg Fist::ResultSet::Schema::Frag (and require in Interface)
    my($frag_to_seq, $schema, $ids_frags, $source) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $row;
    my $id_frag;
    my $id_seq;

    $dbh = $schema->storage->dbh;
    $query = join ',', @{$ids_frags};
    $query = <<END;
SELECT f_to_sg.id_frag,
       s.id
FROM   FragToSeqGroup   AS f_to_sg,
       SeqGroup         AS sg,
       SeqToGroup       AS s_to_sg,
       Seq              AS s
WHERE  f_to_sg.id_frag IN ($query)
AND    sg.id = f_to_sg.id_group
AND    sg.type = 'frag'
AND    s_to_sg.id_group = sg.id
AND    s.id = s_to_sg.id_seq
AND    s.source = ?
END

    $sth = $dbh->prepare($query);
    $sth->execute($source);
    $table = $sth->fetchall_arrayref;
    foreach $row (@{$table}) {
        ($id_frag, $id_seq) = @{$row};
        $frag_to_seq->{$id_frag} = $id_seq;
    }
}

=head2 _get_seqsim_contacts

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_seqsim_contacts {
    my($seqs_to_contacts, $hspsA, $hspsB) = @_;

    my $pairs;
    my $id_seq_A1;
    my $id_seq_A2;
    my $id_seq_B1;
    my $id_seq_B2;
    my $hspA;
    my $hspB;
    my $seqsB2;
    my $contact_A1B1;
    my $contact_A2B2;

    $pairs = {};
    foreach $id_seq_A1 (keys %{$seqs_to_contacts}) {
        $seqsB2 = {};
        foreach $id_seq_A2 (keys %{$hspsA->{$id_seq_A1}}) {
            $hspA = $hspsA->{$id_seq_A1}->{$id_seq_A2};
            foreach $id_seq_B1 (keys %{$seqs_to_contacts->{$id_seq_A1}}) {
                foreach $id_seq_B2 (keys %{$hspsB->{$id_seq_B1}}) {
                    $seqs_to_contacts->{$id_seq_A2}->{$id_seq_B2} or next;
                    $pairs->{$id_seq_A2}->{$id_seq_B2} and next; # only compare in one direction

                    $hspB = $hspsB->{$id_seq_B1}->{$id_seq_B2};
                    $pairs->{$id_seq_A1}->{$id_seq_B1}->{$id_seq_A2}->{$id_seq_B2} = [$hspA, $hspB];

                    # count the number of times each hsp is needed
                    $hspA->[4]++;
                    $hspB->[4]++;
                }
            }
        }
    }

    # undef all hsps that are no longer required
    foreach $id_seq_A1 (keys %{$hspsA}) {
        foreach $id_seq_A2 (keys %{$hspsA->{$id_seq_A1}}) {
            _remove_hsp_if_not_needed($hspsA, $id_seq_A1, $id_seq_A2);
        }
    }

    foreach $id_seq_B1 (keys %{$hspsB}) {
        foreach $id_seq_B2 (keys %{$hspsB->{$id_seq_B1}}) {
            _remove_hsp_if_not_needed($hspsB, $id_seq_B1, $id_seq_B2);
        }
    }

    return $pairs;
}

=head2 _remove_hsp_if_not_needed

 usage   :
 function:
 args    :
 returns :

=cut

sub _remove_hsp_if_not_needed {
    my($hsps, $id_seq1, $id_seq2) = @_;

    if(!$hsps->{$id_seq1}->{$id_seq2}->[4]) {
        $hsps->{$id_seq1}->{$id_seq2} = undef;
        delete $hsps->{$id_seq1}->{$id_seq2};
        #print join("\t", 'delete hsp', $id_seq1, $id_seq2), "\n";
        if(keys(%{$hsps->{$id_seq1}}) == 0) {
            $hsps->{$id_seq1} = undef;
            delete $hsps->{$id_seq1};
        }
    }
}

=head2 _use_hsp

 usage   :
 function:
 args    :
 returns :

=cut

sub _use_hsp {
    my($hsps, $id_seq1, $id_seq2) = @_;

    $hsps->{$id_seq1}->{$id_seq2}->[4]--;
    _remove_hsp_if_not_needed($hsps, $id_seq1, $id_seq2);
}

=head2 _get_hsps

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_hsps { # FIXME - put this somewhere central?
    my($seqs, $hsps0, $schema) = @_;

    my $identicals;
    my $hsps;
    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $row;
    my $id_frag1;
    my $id_frag2;
    my $id_seq1;
    my $id_seq2;
    my $e_value;
    my $pcid;
    my $id_aln;
    my $lf1;
    my $lf2;
    my $n_identicals;
    my $n_hsps;

    $identicals = {};
    $n_identicals = 0;
    $hsps = {};
    $n_hsps = 0;

    $dbh = $schema->storage->dbh;

    $query = <<END;
SELECT a.id_seq2,
       a.e_value,
       a.pcid,
       a.id_aln,
       b.len / (a.end1 - a.start1 + 1) lf1,
       c.len / (a.end2 - a.start2 + 1) lf2
FROM   Hsp AS a,
       Seq AS b,
       Seq AS c
WHERE  a.id_seq1 = ?
AND    a.id_seq2 != a.id_seq1
AND    b.id = a.id_seq1
AND    c.id = a.id_seq2
END
    $sth = $dbh->prepare($query);

    foreach $id_seq1 (keys %{$seqs}) {
        $sth->execute($id_seq1);
        $table = $sth->fetchall_arrayref;
        foreach $row (@{$table}) {
            ($id_seq2, $e_value, $pcid, $id_aln, $lf1, $lf2) = @{$row};
            defined($seqs->{$id_seq2}) or next;
            if(($pcid == 100) and ($lf1 == 1) and ($lf2 == 1)) {
                $identicals->{$id_seq1}->{$id_seq2}++;
                ++$n_identicals;
            }
            else {
                if(defined($hsps0->{$id_seq1}->{$id_seq2})) {
                    # if hsp has been found in a previous search, don't need another copy here, just need to point to the old one
                    $hsps->{$id_seq1}->{$id_seq2} = $hsps0->{$id_seq1}->{$id_seq2};
                    ++$n_hsps;
                }
                else {
                    if(defined($hsps->{$id_seq1}->{$id_seq2})) {
                        if($e_value < $hsps->{$id_seq1}->{$id_seq2}->[0]) {
                            $hsps->{$id_seq1}->{$id_seq2} = [$e_value, $pcid, $id_aln, undef, 0];
                            # [3] = undef = alignment, to be fetched later
                            # [4] = number of times this hsp is needed, which is not yet known
                        }
                    }
                    else {
                        $hsps->{$id_seq1}->{$id_seq2} = [$e_value, $pcid, $id_aln, undef, 0];
                        ++$n_hsps;
                    }
                }
            }
        }
    }
    print "n_hsps = $n_hsps, n_identicals = $n_identicals\n";

    return($n_identicals, $identicals, $n_hsps, $hsps);
}

=head2 _get_alns

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_alns {
    my($hspsA, $hspsB, $schema) = @_;

    my $ids_alns;
    my $id_aln;
    my $ids_alns2;
    my $id_seq_A1;
    my $id_seq_A2;
    my $id_seq_B1;
    my $id_seq_B2;
    my $hspA;
    my $hspB;
    my $aln_to_hsp;
    my $alignment;
    my $i;
    my $j;

    $aln_to_hsp = {};
    foreach $id_seq_A1 (keys %{$hspsA}) {
        foreach $id_seq_A2 (keys %{$hspsA->{$id_seq_A1}}) {
            $hspA = $hspsA->{$id_seq_A1}->{$id_seq_A2};
            $id_aln = $hspA->[2];
            $aln_to_hsp->{$id_aln} = $hspA;
        }
    }
    foreach $id_seq_B1 (keys %{$hspsB}) {
        foreach $id_seq_B2 (keys %{$hspsB->{$id_seq_B1}}) {
            $hspB = $hspsB->{$id_seq_B1}->{$id_seq_B2};
            $id_aln = $hspB->[2];
            $aln_to_hsp->{$id_aln} = $hspB;
        }
    }

    $ids_alns = [sort {$a <=> $b} keys %{$aln_to_hsp}];

    # can get a DBI exception if there are too many ids (query string too long) so get a few at a time
    # FIXME - might have to store them some other way when there are loads (but also don't want to query
    # the db for the same one repeatedly).

    for($i = 0, $j = 999; $i < @{$ids_alns}; $i += 1000, $j += 1000) {
        ($j > $#{$ids_alns}) and ($j = $#{$ids_alns});
        $ids_alns2 = [@{$ids_alns}[$i..$j]];
        foreach $alignment ($schema->resultset('Alignment')->search({id => {in => $ids_alns2}})) {
            $aln_to_hsp->{$alignment->id}->[3] = $alignment;
        }
    }
}

=head2 _get_aln

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_aln {
    my($hsps, $id_seq1, $id_seq2, $schema) = @_;

    my $aln;
    my $id_aln;

    if(!defined($aln = $hsps->{$id_seq1}->{$id_seq2}->[3])) {
        $id_aln = $hsps->{$id_seq1}->{$id_seq2}->[2];
        $aln = $schema->resultset('Alignment')->search({id => $id_aln})->first;
        $hsps->{$id_seq1}->{$id_seq2}->[3] = $aln;
    }

    return $aln;
}

sub _calc_resres_jaccard {
    my($positions1, $positions2, $exact_match, $threshold_jaccard) = @_;

    my $positions3;
    my $positions4;
    my $max_possible_intersection;
    my $min_possible_union;
    my $max_possible_jaccard;
    my $intersection;
    my $pos_A1;
    my $pos_B1;
    my $union;
    my $jaccard;
    my $pair;

    # use the smallest set first
    ($positions3, $positions4) = ($positions1->{n} <= $positions2->{n}) ? ($positions1, $positions2) : ($positions2, $positions1);

    $intersection = 0;
    if($exact_match) {
        A1: foreach $pos_A1 (keys %{$positions3->{pos}}) {
            defined($positions4->{pos}->{$pos_A1}) or last;
            foreach $pos_B1 (keys %{$positions3->{pos}->{$pos_A1}}) {
                if(defined($positions4->{pos}->{$pos_A1}->{$pos_B1})) {
                    ++$intersection;
                }
                else {
                    $intersection = 0;
                    last A1;
                }
            }
        }
    }
    elsif(defined($threshold_jaccard)) { # stop calculating if meeting this threshold is no longer possible
        # the maximum possible jaccard occurs if the smallest set of positions is a subset of the largest
        $max_possible_intersection = $positions3->{n};
        $min_possible_union = $positions4->{n};
        $max_possible_jaccard = $min_possible_union ? ($max_possible_intersection / $min_possible_union) : 0;

        if($max_possible_jaccard >= $threshold_jaccard) {
            foreach $pos_A1 (keys %{$positions3->{pos}}) {
                if(defined($positions4->{pos}->{$pos_A1})) {
                    foreach $pos_B1 (keys %{$positions3->{pos}->{$pos_A1}}) {
                        if(defined($positions4->{pos}->{$pos_A1}->{$pos_B1})) {
                            ++$intersection;
                        }
                    }
                }
            }
        }
    }
    else {
        foreach $pos_A1 (keys %{$positions3->{pos}}) {
            defined($positions4->{pos}->{$pos_A1}) or next;
            foreach $pos_B1 (keys %{$positions3->{pos}->{$pos_A1}}) {
                defined($positions4->{pos}->{$pos_A1}->{$pos_B1}) and ++$intersection;
            }
        }
    }
    $union = $positions3->{n} + $positions4->{n} - $intersection;
    $jaccard = $union ? ($intersection / $union) : 0;

    return($intersection, $union, $jaccard);
}

sub _calc_resres_jaccard_v01 {
    my($positions1, $positions2, $exact_match, $threshold_jaccard) = @_;

    my $positions3;
    my $positions4;
    my $max_possible_intersection;
    my $min_possible_union;
    my $max_possible_jaccard;
    my $intersection;
    my $pos_A1;
    my $pos_B1;
    my $union;
    my $jaccard;
    my $pair;

    # use the smallest set first
    ($positions3, $positions4) = ($positions1->{n} <= $positions2->{n}) ? ($positions1, $positions2) : ($positions2, $positions1);

    $intersection = 0;
    if($exact_match) {
        A1: foreach $pos_A1 (keys %{$positions3->{pos}}) {
            defined($positions4->{pos}->{$pos_A1}) or last;
            foreach $pos_B1 (keys %{$positions3->{pos}->{$pos_A1}}) {
                if(defined($positions4->{pos}->{$pos_A1}->{$pos_B1})) {
                    ++$intersection;
                }
                else {
                    $intersection = 0;
                    last A1;
                }
            }
        }
    }
    elsif(defined($threshold_jaccard)) { # stop calculating if meeting this threshold is no longer possible
        # the maximum possible jaccard occurs if the smallest set of positions is a subset of the largest
        $max_possible_intersection = $positions3->{n};
        $min_possible_union = $positions4->{n};
        $max_possible_jaccard = $min_possible_union ? ($max_possible_intersection / $min_possible_union) : 0;

        if($max_possible_jaccard >= $threshold_jaccard) {
            $union = $positions3->{n} + $positions4->{n};
            $intersection = 0;
            A1: foreach $pos_A1 (keys %{$positions3->{pos}}) {
                if(!defined($positions4->{pos}->{$pos_A1})) {
                    $union -= scalar keys %{$positions3->{pos}->{$pos_A1}};
                    $jaccard = $union ? ($intersection / $union) : 0;
                    if($max_possible_jaccard < $threshold_jaccard) {
                        $intersection = 0;
                        last A1;
                    }
                }
                else {
                    foreach $pos_B1 (keys %{$positions3->{pos}->{$pos_A1}}) {
                        if(defined($positions4->{pos}->{$pos_A1}->{$pos_B1})) {
                            ++$intersection;
                            --$union;
                            $jaccard = $union ? ($intersection / $union) : 0;
                            if($max_possible_jaccard < $threshold_jaccard) {
                                $intersection = 0;
                                last A1;
                            }
                        }
                    }
                }
            }
        }
    }
    else {
        foreach $pos_A1 (keys %{$positions3->{pos}}) {
            defined($positions4->{pos}->{$pos_A1}) or next;
            foreach $pos_B1 (keys %{$positions3->{pos}->{$pos_A1}}) {
                defined($positions4->{pos}->{$pos_A1}->{$pos_B1}) and ++$intersection;
            }
        }
    }
    $union = $positions3->{n} + $positions4->{n} - $intersection;
    $jaccard = $union ? ($intersection / $union) : 0;

    return($intersection, $union, $jaccard);
}

=head2 group_by_jaccards

 usage   :
 function:
 args    :
 returns :

=cut

sub group_by_jaccards {
    my($self, %args) = @_;

    my $min_aln_jaccard;
    my $d_aln_jaccard;
    my $min_full_jaccard;
    my $d_full_jaccard;
    my @contacts;
    my $id_to_contact;
    my $jaccards;
    my $jaccard_type;
    my $fh_contact;
    my $fh_new_to_old;
    my $fh_old_to_new;
    my $fh_new_to_new;
    my %visited;
    my @members;
    my @queue;
    my $contact1;
    my $contact2;
    my $id1;
    my $id2;
    my $aln_jaccard;
    my $full_jaccard;
    my @new_groups;
    my $new_group;
    my $new_to_old;
    my $old_to_new;
    my $new_to_new;
    my $id_old;
    my $id_new;
    my $id_new2;

    # parse arguments
    $min_aln_jaccard = $args{min_aln_jaccard};
    $d_aln_jaccard = $args{d_aln_jaccard} ? $args{d_aln_jaccard} : 0;
    $min_full_jaccard = $args{min_full_jaccard};
    $d_full_jaccard = $args{d_full_jaccard} ? $args{d_full_jaccard} : 0;
    $jaccards = $args{jaccards};
    $fh_contact = $args{fh_contact};
    $fh_new_to_old = $args{fh_new_to_old};
    $fh_old_to_new = $args{fh_old_to_new};
    $fh_new_to_new = $args{fh_new_to_new};

    $new_to_old = {};
    $old_to_new = {};
    $new_to_new = {};

    @contacts = $self->get_children_or_contacts($args{s_lf}, $args{s_pcid}, $args{s_same_frag}, $args{s_aln_jaccard}, $args{s_full_jaccard});

    $id_to_contact = {};
    foreach $contact1 (@contacts) {
        $id_to_contact->{$contact1->id} = $contact1;
    }

    @new_groups = ();
    %visited = ();
    foreach $contact1 (@contacts) {
        $id1 = $contact1->id;
        @members = ();
        @queue = ();
        if(!$visited{$id1}) {
            $visited{$id1} = 1;

            while(defined($id1)) {
                push @members, $id1;
                foreach $id2 (keys %{$jaccards->{$id1}}) {
                    $id_to_contact->{$id2} or next; # $jaccards may include comparisons to contacts not in this set
                    if(!$visited{$id2}) {
                        $aln_jaccard = $jaccards->{$id1}->{$id2} ? $jaccards->{$id1}->{$id2}->{aln} : 0;
                        $full_jaccard = $jaccards->{$id1}->{$id2} ? $jaccards->{$id1}->{$id2}->{full} : 0;
                        if(($aln_jaccard >= $args{min_aln_jaccard}) and ($full_jaccard >= $args{min_full_jaccard})) {
                            #print join("\t", 'jacc', $id1, $id2, $aln_jaccard, $full_jaccard), "\n";
                            $visited{$id2} = 1;
                            push @queue, $id2;
                        }
                    }
                }

                $visited{$id1} = 2;
                $id1 = shift @queue;
            }
        }

        # output
        if(@members > 0) {
            @members = sort {$id_to_contact->{$b}->n_resres <=> $id_to_contact->{$a}->n_resres} @members;
            $id1 = $members[0];
            $contact1 = $id_to_contact->{$id1};

            # create a new contact group with the first member as the representative
            $new_group = Fist::NonDB::Contact->new(
                                                   frag_inst1    => $contact1->frag_inst1,
                                                   frag_inst2    => $contact1->frag_inst2,
                                                   crystal       => $contact1->crystal,
                                                   n_res1        => $contact1->n_res1,
                                                   n_res2        => $contact1->n_res2,
                                                   n_clash       => $contact1->n_clash,
                                                   n_resres      => $contact1->n_resres,
                                                   isa_group     => 1,
                                                   lf            => $self->lf,
                                                   pcid          => $self->pcid,
                                                   same_frag     => $self->same_frag,
                                                   aln_jaccard   => $args{min_aln_jaccard},
                                                   full_jaccard  => $args{min_full_jaccard},
                                                  );
            $new_group->output_tsv($fh_contact);
            push @new_groups, $new_group;

            # add the original group as a parent of the new group
            if($args{new_group}) {
                $new_to_new->{$self->id}->{$new_group->id}++;
            }
            else {
                $old_to_new->{$self->id}->{$new_group->id}++;
            }

            # FIXME - remove links from original group to other groups

            foreach $id1 (@members) {
                $contact1 = $id_to_contact->{$id1};

                if($contact1->isa_group) {
                    # add the new group as a parent of the old group
                    #$contact1->add_to_parents($new_group); # FIXME - can't do this if $contact1 is Fist::Schema::Result::Contact and new_group is Fist::NonDB::Contact
                    $new_group->add_to_children($contact1);
                    $new_to_old->{$new_group->id}->{$contact1->id}++;

                    # Don't add parents of contact1 as parents of the new group.
                    # For example: contact1 might be a jaccard refinement of an
                    # identical sequence group but that does not mean the identical
                    # sequence group should be a parent of the new one.

                    # add all the contacts of the old group to the new group
                    foreach $contact2 ($contact1->contacts) {
                        #print join("\t", 'Contact', $new_group->id, $contact1->id, $contact2->id), "\n";
                        $new_group->add_to_contacts($contact2);
                        $new_to_old->{$new_group->id}->{$contact2->id}++;
                    }

                }
                else {
                    # if a member is not a group, add it to the new group as a contact
                    $new_group->add_to_contacts($contact1);
                    $new_to_old->{$new_group->id}->{$contact1->id}++;
                }
            }
        }
    }

    # iteratively refine groups
    if(($d_aln_jaccard > 0) or ($d_full_jaccard > 0)) {
        $min_aln_jaccard += $d_aln_jaccard;
        $min_full_jaccard += $d_full_jaccard;
        if(($min_aln_jaccard <= 1) and ($min_full_jaccard <= 1)) {
            foreach $new_group (@new_groups) {
                $new_group->group_by_jaccards(
                                              new_group        => 1,

                                              jaccards         => $args{jaccards},

                                              fh_contact       => $args{fh_contact},
                                              fh_new_to_old    => $args{fh_new_to_old},
                                              fh_old_to_new    => $args{fh_old_to_new},
                                              fh_new_to_new    => $args{fh_new_to_new},

                                              min_aln_jaccard  => $min_aln_jaccard,
                                              d_aln_jaccard    => $args{d_aln_jaccard},
                                              min_full_jaccard => $min_full_jaccard,
                                              d_full_jaccard   => $args{d_full_jaccard},

                                              s_lf             => $args{s_lf},
                                              s_pcid           => $args{s_pcid},
                                              s_same_frag      => $args{s_same_frag},
                                              s_aln_jaccard    => $args{s_aln_jaccard},
                                              s_full_jaccard   => $args{s_full_jaccard},
                                             );
            }
        }
    }

    foreach $id_old (keys %{$old_to_new}) {
        foreach $id_new (keys %{$old_to_new->{$id_old}}) {
            print $fh_old_to_new join("\t", $id_old, $id_new), "\n";
        }
    }

    foreach $id_new (keys %{$new_to_old}) {
        foreach $id_old (keys %{$new_to_old->{$id_new}}) {
            print $fh_new_to_old join("\t", $id_new, $id_old), "\n";
        }
    }

    foreach $id_new (keys %{$new_to_new}) {
        foreach $id_new2 (keys %{$new_to_new->{$id_new}}) {
            print $fh_new_to_new join("\t", $id_new, $id_new2), "\n";
        }
    }
}

=head2 output_tsv

=cut

sub output_tsv {
    my($self, $fh) = @_;

    print(
          $fh
          join(
               "\t",
               $self->id,
               defined($self->frag_inst1) ? $self->id_frag_inst1 : '',
               defined($self->frag_inst2) ? $self->id_frag_inst2 : '',
               $self->crystal,
               $self->n_res1,
               $self->n_res2,
               $self->n_clash,
               $self->n_resres,
               $self->homo,
              ),
          "\n",
         );
}

=head2 output_dom

=cut

sub output_dom {
    my($self, $fh) = @_;

    printf(
           $fh
           "%s %d { %s }\n%s %d { %s }\n",
           $self->frag_inst1->fn,
           $self->id_frag_inst1,
           $self->frag_inst1->frag->dom,

           $self->frag_inst2->fn,
           $self->id_frag_inst2,
           $self->frag_inst2->frag->dom,
          );
}

=head2 string

 usage   :
 function:
 args    :
 returns :

=cut

sub string {
    my($self) = @_;

    my $fist_contacts;
    my $pos1;
    my $fist_numbers;
    my $str;

    $fist_contacts = $self->fist_contacts;
    $fist_numbers = [];
    foreach $pos1 (sort {$a <=> $b} keys %{$fist_contacts->{pos}}) {
        push @{$fist_numbers}, join(',', $pos1, sort {$a <=> $b} keys %{$fist_contacts->{pos}->{$pos1}});
    }

    $str = join(
                "\t",
                $self->id,
                $self->id_frag_inst1,
                $self->id_frag_inst2,
                $self->crystal,
                $self->n_res1,
                $self->n_res2,
                $self->n_clash,
                $self->n_resres,
                @{$fist_numbers},
               );

    return $str;
}

1;
