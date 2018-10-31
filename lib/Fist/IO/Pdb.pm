package Fist::IO::Pdb;

use Moose;
use namespace::autoclean;
use DateTime;
use DateTime::Format::ISO8601;
use Fist::NonDB::Pdb;
use Fist::NonDB::Frag;
use Fist::NonDB::Seq;
use Fist::NonDB::FragResMapping;
use Fist::NonDB::Expdta;
use Fist::NonDB::SeqGroup;
use Fist::NonDB::Taxon;
use Fist::NonDB::ChainSegment;

=head1 NAME

 Fist::IO::Pdb

=cut

=head1 ROLES

 with 'Fist::IO';

=cut

with 'Fist::IO';

=head1 METHODS

=cut

=head2 parse

 usage   : $pdb = $io->parse($tempdir, 'cleanup');
 function: parses the pdb file in $self->fn and returns a Fist::NonDB::Pdb object
 args    :
 returns : a Fist::NonDB::Pdb object on success, or undef on error

=cut

sub parse {
    my($self, $tempdir, $cleanup) = @_;

    my $fh;
    my $pdb;
    my @data;
    my $str;
    my $title;
    my $resolution;
    my $expdta_str_all;
    my $expdta_str;
    my $expdta;
    my $ids_mols;
    my $id_mol;
    my $molecules;
    my $cid2mol;
    my @cids;
    my $cid_str;
    my $cid;
    my $seqs;
    my $seq;
    my $frags;
    my $frag;
    my $seqgroups;
    my $atomNums;
    my $atomNum;
    my $atomNum2;
    my $atomName;
    my $altLoc;
    my $resName;
    my $modResName;
    my $resSeqs;
    my $resSeq;
    my $iCode;
    my $iCode2;
    my $cid_p;
    my $resSeq_p;
    my $iCode_p;
    my $resName_p;
    my $chains;
    my $type;
    my $aas;
    my $taxon;
    my $chain_name;
    my $pdbseqs;
    my $interprets_seqs;
    my $id_frag;
    my $aln;
    my $updated;
    my $i;
    my $res_mapping;
    my $seqres;
    my $numRes;
    my $res3;
    my $res1;
    my $seqgroup;
    my $taxa;
    my $chain_segment;
    my $modresns;
    my $seqadvs;
    my $hetatms;
    my $connectivity;
    my %visited;
    my @queued;
    my @members;
    my $chems;
    my $chem;
    my $hetnams;
    my $hetresns;

    defined($cleanup) or ($cleanup = 1);

    $title = '';
    $expdta_str_all = '';
    $molecules = {};
    $cid2mol = {};
    @cids = ();
    $chains = {};
    $cid_p = '';
    $resSeq_p = -1000000;
    $iCode_p = 'XXX';
    $resName_p = '';

    $pdb = Fist::NonDB::Pdb->new();
    $pdb->cleanup($cleanup);
    if(defined($tempdir)) {
        $pdb->tempdir($tempdir);
    }
    else {
        $pdb->tempdir(File::Temp->newdir(CLEANUP => $pdb->cleanup));
    }

    defined($pdb->tempdir) or return(undef);
    $pdb->fn($self->fn);
    $fh = $self->fh;

    $modresns = {};
    $seqadvs = {};
    $hetnams = {};
    $hetatms = {};
    $hetresns = {};
    $connectivity = {};
    while(<$fh>) {
	chomp;

	if(/^ENDMDL/) {
	    last;
	}
	elsif(/^HEADER/) {
	    @data = unpack 'a6a4a40a9a3a4', $_;

	    ($data[3] =~ /\A(.{2})-(.{3})-(.{2})/) and $pdb->depdate(_revdat2date($1, $2, $3));
            $data[5] and ($data[5] ne 'XXXX') and $pdb->idcode(lc $data[5]);
        }
	elsif(/^TITLE.{5}(.*)/) {
	    ($str = $1) =~ s/\s+\Z//;
	    $title .= $str;
	}
        elsif(/^REMARK   2 RESOLUTION\..*?(\d+\.\d+)/) {
            $pdb->resolution($1);
        }
	elsif(/^REVDAT.{7}(.{2})-(.{3})-(.{2})/) {
            $updated = _revdat2date($1, $2, $3);
            (!defined($pdb->updated) or ($updated > $pdb->updated)) and $pdb->updated($updated);
	}
	elsif(/^COMPND.*MOL_ID:\s*(\d+)/) {
	    $id_mol = $1;
	    $molecules->{$id_mol} = {name => '', chains => []};
	}
	elsif(/^COMPND\s*\S+\s*MOLECULE:\s*(.*?)\s*\Z/) {
	    $molecules->{$id_mol}->{name} .= $1;
	}
	elsif(/^COMPND\s*\S+\s*CHAIN:\s*(.*)/) {
	    ($cid_str = $1) =~ s/;?\s*\Z//;

	    foreach $cid (split(/\s*,\s*/, $cid_str)) {
		(length($cid) > 1) and next; # some people abuse the CHAIN info, eg. 3e6p has 'CHAIN: UNP RESIDUES 206-363;'

		push @{$molecules->{$id_mol}->{chains}}, $cid;
		$cid2mol->{$cid} = $id_mol;
	    }
	}
        elsif(/^SOURCE\s+MOL_ID:\s*(\d+)/) {
            # the source info for several molecules might be combined, eg. 1a0n:
            #
            # SOURCE    MOL_ID: 1;
            # SOURCE   2 MOL_ID: 2;
            # SOURCE   3 ORGANISM_SCIENTIFIC: HOMO SAPIENS;
            # SOURCE   4 ORGANISM_COMMON: HUMAN;
            # SOURCE   5 ORGANISM_TAXID: 9606;
            # SOURCE   6 EXPRESSION_SYSTEM: ESCHERICHIA COLI;
            # SOURCE   7 EXPRESSION_SYSTEM_TAXID: 469008;
            # SOURCE   8 EXPRESSION_SYSTEM_STRAIN: BL21 (DE3);
            # SOURCE   9 EXPRESSION_SYSTEM_VECTOR_TYPE: PLASMID;
            # SOURCE  10 EXPRESSION_SYSTEM_PLASMID: PGEX

            $ids_mols = [$1];
        }
	elsif(/^SOURCE.*MOL_ID:\s*(\d+)/) {
            push @{$ids_mols}, $1;
	}
	elsif(/^SOURCE.*ORGANISM_TAXID:\s*?(\d+)/) {
            foreach $id_mol (@{$ids_mols}) {
                $molecules->{$id_mol}->{taxon} = $1;
            }
	}
        elsif(/\AEXPDTA.{4}\s*(.*?)\s*\Z/) {
            $expdta_str_all .= $1;
        }
        elsif(/\ASEQRES\s.{3}\s(.)\s(.{4})\s+(.*)\Z/) {
            ($cid, $numRes, $str) = ($1, $2, $3);
            defined($seqres->{$cid}) or ($seqres->{$cid} = {numRes => $2, res3 => [], res1 => []});
            foreach $res3 (split /\s+/, $str) {
                $res1 = _res3to1($res3);
                push @{$seqres->{$cid}->{res3}}, $res3;
                push @{$seqres->{$cid}->{res1}}, $res1;
            }
        }
        elsif(/^MODRES\s.{4}\s(.{3})\s(.)\s(.{4})(.)\s(.{3})/) {
            # MODRES info will be used to
            # - place the one-letter code of the residue in the sequence
            # - ignore modified residues when storing HETATMs as chemical fragments

            ($modResName, $cid, $resSeq, $iCode, $resName) = ($1, $2, $3, $4, $5);
            $modResName =~ s/\s+//g;
            #$cid        =~ s/\s+//g;
            $resSeq     =~ s/\s+//g;
            #$iCode      =~ s/\s+//g;
            $resName    =~ s/\s+//g;
            $modresns->{$cid}->{$resSeq}->{$iCode}->{$modResName} = $resName;
        }
        elsif(/^SEQADV\s.{4}\s(.{3})\s(.)\s(.{4})(.)/) {
            # SEQADV info will be used to
            # - ignore residues that differ between the pdb entry and the dbREF when storing HETATMs as chemical fragments

            ($modResName, $cid, $resSeq, $iCode) = ($1, $2, $3, $4);
            $modResName =~ s/\s+//g;
            #$cid        =~ s/\s+//g;
            $resSeq     =~ s/\s+//g;
            #$iCode      =~ s/\s+//g;
            $seqadvs->{$cid}->{$resSeq}->{$iCode}->{$modResName} = $resName;
        }
        elsif(/^HETNAM.{5}(.{3})\s+(.*?)\s*\Z/) {
            if(defined($hetnams->{$1})) {
                $hetnams->{$1} .= " $2";
            }
            else {
                $hetnams->{$1} = $2;
            }
        }
	elsif(/^ATOM/ or /^HETATM.{7}CA /) {
            # parse residues from any ATOM or any C-alpha HETATM

            #                0 1 23 456 78
	    @data = unpack 'a6a5a5aa3aaa4a', $_;

	    ($atomName  = $data[2]) =~ s/\s+//g;
	    ($altLoc    = $data[3]) =~ s/\s+//g;
	    ($resName   = $data[4]) =~ s/\s+//g;
	    #($cid       = $data[6]) =~ s/\s+//g;
            $cid = $data[6];
	    ($resSeq    = $data[7]) =~ s/\s+//g;
	    #($iCode     = $data[8]) =~ s/\s+//g;
            $iCode = $data[8];

	    $id_mol = $cid2mol->{$cid};

	    if($cid ne $cid_p) {
		($resSeq_p > -1000000) and _add_res_info($chains, $modresns, $cid_p, $resSeq_p, $iCode_p, $resName_p);

                if(!defined($chains->{$cid})) {
                    # Some entries, eg 11as, have HETATMs after all ATOMs, so the information
                    # for each chain is not given contiguously. This may of course mean that
                    # the ATOMs and HETATMs are not connected, but ignoring that possibility here.
                    push @cids, $cid;
                    $chains->{$cid} = {resSeq => [], iCode => [], modResName => [], resName => [], aa => []};
                }

		$resSeq_p = -1000000;
		$iCode_p = 'XXX';
		$resName_p = '';
	    }

	    if($resSeq eq $resSeq_p) {
		($iCode ne $iCode_p) and $resName_p and _add_res_info($chains, $modresns, $cid, $resSeq_p, $iCode_p, $resName_p);
	    }
	    elsif($resSeq_p > -1000000) {
		 _add_res_info($chains, $modresns, $cid, $resSeq_p, $iCode_p, $resName_p);
	    }

	    $cid_p = $cid;
	    $resSeq_p = $resSeq;
	    $resName_p = $resName;
	    $iCode_p = $iCode;
	}
        elsif(/^HETATM/) {
            #                0 1 23 456 78
	    @data = unpack 'a6a5a5aa3aaa4a', $_;

            ($atomNum   = $data[1]) =~ s/\s+//g;
	    ($atomName  = $data[2]) =~ s/\s+//g;
	    ($altLoc    = $data[3]) =~ s/\s+//g;
	    ($resName   = $data[4]) =~ s/\s+//g;
	    #($cid       = $data[6]) =~ s/\s+//g;
            $cid = $data[6];
	    ($resSeq    = $data[7]) =~ s/\s+//g;
	    #($iCode     = $data[8]) =~ s/\s+//g;
            $iCode = $data[8];

            if(($resName ne 'HOH') and ($resName ne 'DOD')) {
                if(!defined($modresns->{$cid}->{$resSeq}->{$iCode}->{$resName}) and
                   !defined($seqadvs->{$cid}->{$resSeq}->{$iCode}->{$resName})
                  ) {
                    # this HETATM is not part of a normal residue that has been modified
                    # in some way, so it is probably a separate chemical entity. Store by
                    # atomNum so can be grouped into fragments based on the connectivity
                    # given in CONECT records
                    $hetatms->{$atomNum} = {cid => $cid, resSeq => $resSeq, iCode => $iCode, resName => $resName};
                    $hetresns->{$cid}->{$resSeq}->{$iCode}->{$resName}++;
                }
            }
        }
        elsif(/^CONECT(.{0,5})(.{0,5})(.{0,5})(.{0,5})(.{0,5})/) {
            $atomNums = [$1, $2, $3, $4, $5];
            for($i = 0; $i < @{$atomNums}; $i++) {
                $atomNums->[$i] =~ s/\s+//g;
            }
            $atomNum = $atomNums->[0];
            defined($hetatms->{$atomNum}) or next; # ignoring connectivity to normal atoms and water
            for($i = 1; $i < @{$atomNums}; $i++) {
                $atomNum2 = $atomNums->[$i];
                ($atomNum2 eq '') and next;
                defined($hetatms->{$atomNum2}) or next; # ignoring connectivity to normal atoms and water
                $connectivity->{$atomNum}->{$atomNum2}++;
            }
        }
    }
    ($resSeq_p > -1000000) and _add_res_info($chains, $modresns, $cid_p, $resSeq_p, $iCode_p, $resName_p);

    $pdb->updated or $pdb->updated($pdb->depdate);
    $pdb->title($title);

    foreach $expdta_str (split /\s*;\s*/, $expdta_str_all) {
        $expdta_str =~ s/,.*//;
        $expdta = Fist::NonDB::Expdta->new(idcode => $pdb->idcode, expdta => $expdta_str);
        $pdb->add_to_expdtas($expdta);
    }

    $frags = {};
    $seqs = {};
    $taxa = {};
    foreach $cid (@cids) {
        if(defined($id_mol = $cid2mol->{$cid})) {
            $taxon = defined($molecules->{$id_mol}->{taxon}) ? Fist::NonDB::Taxon->new(id => $molecules->{$id_mol}->{taxon}) : undef;
            ($chain_name = $molecules->{$id_mol}->{name}) =~ s/;\s*\Z//;
        }
        else {
            $taxon = undef;
            $chain_name = '';
        }

        $type = _chain_type($chains->{$cid}->{resName});

        # create new frag object
        $frag = Fist::NonDB::Frag->new(pdb => $pdb, fullchain => 1, chemical_type => $type, dom => _get_dom($chains, $cid), description => $chain_name, tempdir => $pdb->tempdir, cleanup => $pdb->cleanup);
        $pdb->add_to_frags($frag);
        $frags->{$frag->id} = $frag;
        $taxon and $taxa->{$frag->id} = $taxon;

        # create new seqgroup object
        $seqgroup = Fist::NonDB::SeqGroup->new(type => 'frag');
        $seqgroups->{$frag->id} = $seqgroup;

        # link the seqgroup to the fragment
        $frag->add_to_seq_groups($seqgroup);

        # create new seq object for the sequence parsed from here

        # FIXME - give primary_id and name to this sequence

        $aas = join '', @{$chains->{$cid}->{aa}};
        $seq = Fist::NonDB::Seq->new(seq => $aas, len => length($aas), chemical_type => $type, source => 'fist', description => $chain_name);
        $frag->id_seq($seq->id);
        $taxon and $seq->add_to_taxa($taxon);
        $seqgroup->add_to_seqs($seq);

        # create new seq object for the seqres sequence
        if($seqres->{$cid}) {
            if(@{$seqres->{$cid}->{res1}} != $seqres->{$cid}->{numRes}) {
                print "'", join("','", @{$seqres->{$cid}->{res3}}), "'\n";
                print "'", join("','", @{$seqres->{$cid}->{res1}}), "'\n";

                Carp::cluck(sprintf("seqres length (%d) != number of residues (%d) for chain $cid.", scalar(@{$seqres->{$cid}->{res1}}), $seqres->{$cid}->{numRes}));
                return undef;
            }
            $aas = join '', @{$seqres->{$cid}->{res1}};

            # FIXME - give primary_id and name to this sequence

            $seq = Fist::NonDB::Seq->new(seq => $aas, len => length($aas), chemical_type => $type, source => 'seqres', description => $chain_name);
            $taxon and $seq->add_to_taxa($taxon);
            $seqgroup->add_to_seqs($seq);
        }

        # res_mapping (fist pos to chain, resSeq, iCode)

        for($i = 0; $i < @{$chains->{$cid}->{resSeq}}; $i++) {
            $res_mapping = Fist::NonDB::FragResMapping->new(
                                                            id_frag => $frag->id,
                                                            fist    => $i + 1, # sequence positions are one-based
                                                            chain   => $cid,
                                                            resseq  => $chains->{$cid}->{resSeq}->[$i],
                                                            icode   => $chains->{$cid}->{iCode}->[$i],
                                                            res3    => $chains->{$cid}->{modResName}->[$i], # using the original resNames, ie. including modifications (SEP not SER, etc)
                                                            res1    => $chains->{$cid}->{aa}->[$i],
                                                           );
            $frag->add_to_res_mappings($res_mapping);
        }

        # fragment chain position
        $chain_segment = Fist::NonDB::ChainSegment->new(
                                                        frag         => $frag,
                                                        chain        => $cid,
                                                        resseq_start => $chains->{$cid}->{resSeq}->[0],
                                                        resseq_end   => $chains->{$cid}->{resSeq}->[$#{$chains->{$cid}->{resSeq}}],
                                                        icode_start  => $chains->{$cid}->{iCode}->[0],
                                                        icode_end    => $chains->{$cid}->{iCode}->[$#{$chains->{$cid}->{resSeq}}],
                                                       );
        $frag->add_to_chain_segments($chain_segment);
    }

    # CONECT info is not given for every HETATM record, eg. hetero
    # Asparagine in pdb 11as. However, all hetero groups in a particular
    # pdb should have different resName, cid, resSeq and iCode
    foreach $cid (sort keys %{$hetresns}) {
        foreach $resSeq (sort {$a <=> $b} keys %{$hetresns->{$cid}}) {
            foreach $iCode (sort keys %{$hetresns->{$cid}->{$resSeq}}) {
                foreach $resName (sort keys %{$hetresns->{$cid}->{$resSeq}->{$iCode}}) {
                    $iCode2 = ($iCode =~ /\A\s*\Z/) ? '_' : $iCode;
                    $frag = Fist::NonDB::Frag->new(
                                                   pdb           => $pdb,
                                                   fullchain     => 0,
                                                   chemical_type => $resName,
                                                   dom           => sprintf("%s %d %s to %s %d %s", $cid, $resSeq, $iCode2, $cid, $resSeq, $iCode2),
                                                   description   => defined($hetnams->{$resName}) ? $hetnams->{$resName} : $resName,
                                                   tempdir       => $pdb->tempdir,
                                                   cleanup       => $pdb->cleanup,
                                                  );
                    $pdb->add_to_frags($frag);
                    $frags->{$frag->id} = $frag;

                    # fragment chain position
                    $chain_segment = Fist::NonDB::ChainSegment->new(
                                                                    frag         => $frag,
                                                                    chain        => $cid,
                                                                    resseq_start => $resSeq,
                                                                    resseq_end   => $resSeq,
                                                                    icode_start  => $iCode,
                                                                    icode_end    => $iCode,
                                                                   );
                    $frag->add_to_chain_segments($chain_segment);
                }
            }
        }
    }

    # add sequences to fragment seqgroups and set taxa
    foreach $id_frag (keys %{$seqs}) {
        $taxon = $taxa->{$id_frag};
        if(defined($seqgroup = $seqgroups->{$id_frag})) {
            foreach $seq (@{$seqs->{$id_frag}}) {
                $seqgroup->add_to_seqs($seq);
                $taxon and $seq->add_to_taxa($taxon);
            }
        }
    }

    return $pdb;
}

sub _get_dom {
    my($chains, $cid) = @_;

    my $start;
    my $end;
    my $p;
    my $i;
    my $n_gaps;
    my $segments;
    my $dom;

    $start = [$chains->{$cid}->{resSeq}->[0], ($chains->{$cid}->{iCode}->[0] eq ' ') ? '_' : $chains->{$cid}->{iCode}->[0]];
    $end = [@{$start}];
    $p = $end->[0] + 1;
    $segments = [];
    for($i = 1; $i < @{$chains->{$cid}->{resSeq}}; $i++) {
        if($chains->{$cid}->{resSeq}->[$i] > $p) {
            push @{$segments}, sprintf "%s %d %s to %s %d %s", $cid, @{$start}, $cid, @{$end};
            $start = [$chains->{$cid}->{resSeq}->[$i], ($chains->{$cid}->{iCode}->[$i] eq ' ') ? '_' : $chains->{$cid}->{iCode}->[$i]];
            $end = [@{$start}];
            $p = $end->[0] + 1;
            ++$n_gaps;
        }
        else {
            $end = [$chains->{$cid}->{resSeq}->[$i], ($chains->{$cid}->{iCode}->[$i] eq ' ') ? '_' : $chains->{$cid}->{iCode}->[$i]];
            $p = $end->[0] + 1;
        }
    }
    push @{$segments}, sprintf "%s %d %s to %s %d %s", $cid, @{$start}, $cid, @{$end};
    $dom = join ' ', @{$segments};

    return $dom;
}

sub _add_res_info {
    my($chains, $modresns, $cid, $resSeq, $iCode, $modResName) = @_;

    my $resName;

    $resName = $modresns->{$cid}->{$resSeq}->{$iCode}->{$modResName};
    defined($resName) or ($resName = $modResName);

    push @{$chains->{$cid}->{resSeq}}, $resSeq;
    push @{$chains->{$cid}->{iCode}}, $iCode;
    push @{$chains->{$cid}->{modResName}}, $modResName;
    push @{$chains->{$cid}->{resName}}, $resName;
    push @{$chains->{$cid}->{aa}}, _res3to1($resName); # use the unmodified form later for the sequence (for better sequence matching)
}

sub _res3to1 {
    my($res3) = @_;

    my $res1;

    my $res3to1 = {
                   # amino acids
                   ALA => 'A',
                   ARG => 'R',
                   ASN => 'N',
                   ASP => 'D',
                   CYS => 'C',
                   GLN => 'Q',
                   GLU => 'E',
                   GLY => 'G',
                   HIS => 'H',
                   ILE => 'I',
                   LEU => 'L',
                   LYS => 'K',
                   MET => 'M',
                   PHE => 'F',
                   PRO => 'P',
                   SER => 'S',
                   THR => 'T',
                   TRP => 'W',
                   TYR => 'Y',
                   VAL => 'V',

                   # nucleic acids
                   A   => 'A',
                   C   => 'C',
                   G   => 'G',
                   T   => 'T',
                   U   => 'U',
                   DA  => 'A',
                   DC  => 'C',
                   DG  => 'G',
                   DT  => 'T',
                   DU  => 'U',

                   # modified residues
                   # FIXME - parse SEQADV and MODRES records to get the unmodified residue
                   #MSE => 'M',
                   #MLY => 'K',
                   #HYP => 'P',
                   #SEP => 'S',
                   #SAH => 'C',
                   #TPO => 'T',
                   #KCX => 'K',
                   #CSO => 'C',
                   #CME => 'C',
                   #PTR => 'Y',
                   #LLP => 'K',
                   #DAL => 'A',
                   #CGU => 'E',
                   #MLE => 'L',
                   #DLE => 'L',
                   #SAM => 'M',
                   #CSD => 'C',
                   #DVA => 'V',
                   #DPR => 'P',
                   #OCS => 'C',
                   #SMC => 'C',
                   #FME => 'M',
                   #TYS => 'Y',
                   #DGL => 'E',
                   #M3L => 'K',
                   #MVA => 'V',
                   #CAS => 'C',
                   #CSW => 'C',
                   #NLE => 'L',
                  };

    $res1 = $res3to1->{$res3} ? $res3to1->{$res3} : 'X';

    return $res1;
}

sub _chain_type {
    my($res_names) = @_;

    my $res_name;
    my $types;
    my $type;

    my $chain_types = {
		       'ALA' => 'peptide',
		       'ARG' => 'peptide',
		       'ASN' => 'peptide',
		       'ASP' => 'peptide',
		       'CYS' => 'peptide',
		       'GLN' => 'peptide',
		       'GLU' => 'peptide',
		       'GLY' => 'peptide',
		       'HIS' => 'peptide',
		       'ILE' => 'peptide',
		       'LEU' => 'peptide',
		       'LEU' => 'peptide',
		       'LYS' => 'peptide',
		       'MET' => 'peptide',
		       'PHE' => 'peptide',
		       'PRO' => 'peptide',
		       'SER' => 'peptide',
		       'THR' => 'peptide',
		       'TRP' => 'peptide',
		       'TYR' => 'peptide',
		       'VAL' => 'peptide',
		       'PCA' => 'peptide',
		       'ACE' => 'peptide',
		       'FOR' => 'peptide',
		       'ASX' => 'peptide',
		       'GLX' => 'peptide',
		       'A'   => 'nucleotide',
		       'C'   => 'nucleotide',
		       'G'   => 'nucleotide',
		       'T'   => 'nucleotide',
		       'U'   => 'nucleotide',
		       'DA'  => 'nucleotide',
		       'DC'  => 'nucleotide',
		       'DG'  => 'nucleotide',
		       'DT'  => 'nucleotide',
		       'DU'  => 'nucleotide',
		      };

    $types = {};
    foreach $res_name (@{$res_names}) {
        defined($type = $chain_types->{$res_name}) and $types->{$type}++;
    }
    $types = [sort {$types->{$b} <=> $types->{$a}} keys %{$types}];
    $type = $types->[0] ? $types->[0] : 'unknown';

    return $type;
}

=head2 _revdat2date

 converts pdb-format dates to DateTime objects

=cut

# FIXME - there is probably a CPAN DateTime::Format::* module for this
sub _revdat2date {
    my($dd, $mmm, $yy) = @_;

    my $mmm2number;
    my $datetime;

    $mmm2number = {
                   'JAN' =>  1,
                   'FEB' =>  2,
                   'MAR' =>  3,
                   'APR' =>  4,
                   'MAY' =>  5,
                   'JUN' =>  6,
                   'JUL' =>  7,
                   'AUG' =>  8,
                   'SEP' =>  9,
                   'OCT' => 10,
                   'NOV' => 11,
                   'DEC' => 12,
                  };

    $yy = ($yy < 70) ? ($yy + 2000) : ($yy + 1900); # we're screwed if the PDB format and this code lasts past 2070.
    $datetime = DateTime->new(day => $dd, month => $mmm2number->{$mmm}, year => $yy);

    return $datetime;
}

=head2 get_chains

 usage   : $pdb = $io->get_chains();
 function: finds the chain identifiers in pdb file $self->fn
 args    : none
 returns : a list of chain identifiers

=cut

sub get_chains {
    my($self) = @_;

    my $cid;
    my $p;
    my @chains;
    my $fh;

    @chains = ();
    $p = '';
    $fh = $self->fh;
    while(<$fh>) {
        if(/^ATOM.{17}(.)/ or /^HETATM.{15}(.)/) {
            $cid = $1;
            ($cid ne $p) and push(@chains, $cid);
            $p = $cid;
        }
    }
    close($fh);

    return @chains;
}

=head2 resultset_name

 usage   :
 function: used internally to provide the result set name
 args    : none
 returns : the name of the result set

=cut

sub resultset_name {
    return 'Pdb';
}

=head2 column_names

 usage   :
 function: used internally to provide the column names in order used by tsv files
 args    : none
 returns : a list of column names

=cut

sub column_names {
    return(qw/idcode title resolution depdate updated/);
}

__PACKAGE__->meta->make_immutable;
1;
