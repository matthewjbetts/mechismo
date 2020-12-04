package Fist::Interface::Seq;

use Moose::Role;
use Dir::Self;
use Fist::Utils::SubstitutionMatrix;
use Fist::Utils::Search;

my $id_site = 0;
my $mat_blosum62 = Fist::Utils::SubstitutionMatrix->new(fn => __DIR__ . '/../../../root/static/data/matrices/BLOSUM62_mjb.txt', format => 'ncbi'); # FIXME - better way of given path to static files? in config file maybe?

=head1 NAME

 Fist::Interface::Seq

=cut

=head1 ACCESSORS

=cut

=head2 id

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id';

=head2 primary_id

 usage   :
 function:
 args    :
 returns :

=cut

requires 'primary_id';

=head2 name

 usage   :
 function:
 args    :
 returns :

=cut

requires 'name';

=head2 seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq';

=head2 seqs

 usage   :
 function:
 args    :
 returns :

=cut

sub seqs {
    my($self) = @_;

    return $self;
}

=head2 len

 usage   :
 function:
 args    :
 returns :

=cut

requires 'len';

=head2 chemical_type

 usage   :
 function:
 args    :
 returns :

=cut

requires 'chemical_type';

=head2 source

 usage   :
 function:
 args    :
 returns :

=cut

requires 'source';

=head2 description

 usage   :
 function:
 args    :
 returns :

=cut

requires 'description';

=head2 aliases

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aliases';

=head2 feature_insts

 usage   :
 function:
 args    :
 returns :

=cut

requires 'feature_insts';

=head2 feature_insts_by_source

 usage   : $seq->feature_insts_no_overlap
 function:
 args    :
 returns : a hash of lists of feature instances, keyed by feature source

=cut

sub feature_insts_by_source {
    my($self, $source, $ac_src) = @_;

    my $fis;
    my @fis0;
    my $fi;
    my @sources;

    if(!defined($source)) {
        @fis0 = $self->feature_insts({}, {prefetch => 'feature'});
        $fis = {};
    }
    elsif(!defined($ac_src)) {
        @fis0 = $self->feature_insts({'feature.source' => $source}, {prefetch => 'feature'});
        $fis = {$source => {}};
    }
    else {
        @fis0 = $self->feature_insts({'feature.source' => $source, 'feature.ac_src' => $ac_src}, {prefetch => 'feature'});
        $fis = {$source => {}};
    }

    # groups instances by feature source
    foreach $fi (@fis0) {
        $fis->{$fi->feature->source}->{$fi->id} = $fi;
    }
    foreach $source (keys %{$fis}) {
        #$fis->{$source} = [sort {$a->id <=> $b->id} values %{$fis->{$source}}];
        $fis->{$source} = [values %{$fis->{$source}}];
    }

    return $fis;
}

=head2 feature_insts_no_overlap

 usage   : $seq->feature_insts_no_overlap
 function: for each feature source, keep only the best (lowest e-value) of each set of overlapping instances
 args    : none
 returns : a hash of lists of feature instances, keyed by feature source

=cut

sub feature_insts_no_overlap {
    my($self) = @_;

    my $fis;
    my $fi1;
    my $fi2;
    my $source;
    my $ids;
    my $links;
    my $i;
    my $j;
    my $id1;
    my $id2;
    my $overlap;
    my %visited;
    my @queue;
    my @members;
    my $fis_kept;
    my $fi_kept;

    # groups instances by feature source
    $fis = {};
    foreach $fi1 ($self->feature_insts) {
        $fis->{$fi1->feature->source}->{$fi1->id} = $fi1;
    }

    # for each source, keep only the best (lowest e-value) of each set of overlapping instances
    foreach $source (keys %{$fis}) {
        # order the feature instances by increasing start position on the sequence
        $ids = [sort {$fis->{$source}->{$a}->start_seq <=> $fis->{$source}->{$b}->start_seq} keys %{$fis->{$source}}];

        # find overlaps
        $links = {};
        $links = {};
        for($i = 0; $i < @{$ids}; $i++) {
            $id1 = $ids->[$i];
            $fi1 = $fis->{$source}->{$id1};
            for($j = $i + 1; $j < @{$ids}; $j++) {
                $id2 = $ids->[$j];
                $fi2 = $fis->{$source}->{$id2};

                # since the feature instances have already been ordered by
                # increasing start position on the sequence, can quickly
                # check if fi2 starts after the end of fi1. If it does, can
                # skip it and all the remaining fi2s.
                ($fi2->start_seq > $fi1->end_seq) and last;

                $overlap = Fist::Utils::Overlap->new(start1 => $fi1->start_seq, end1 => $fi1->end_seq, start2 => $fi2->start_seq, end2 => $fi2->end_seq);
                if(defined($overlap) and ($overlap->overlap > 0)) {
                    $links->{$id1}->{$id2}++;
                    $links->{$id2}->{$id1}++;
                }
            }
        }

        # breadth-first search to group feature instances by single-linkage
        %visited = ();
        @queue = ();
        $fis_kept = [];
        foreach $id1 (@{$ids}) {
            if(!$visited{$id1}) {
                $visited{$id1} = 1;

                @members = ();
                while(defined($id1)) {
                    push @members, $fis->{$source}->{$id1};

                    foreach $id2 (keys %{$links->{$id1}}) {
                        if(!$visited{$id2}) {
                            $visited{$id2} = 1;
                            push @queue, $id2;
                        }
                    }

                    $visited{$id1} = 2;
                    $id1 = shift @queue;
                }

                if(@members > 0) {
                    @members = sort {$a->e_value <=> $b->e_value} @members;
                    $fi_kept = $members[0];
                    push @{$fis_kept}, $fi_kept;
                }
            }
        }
        $fis->{$source} = $fis_kept;
    }

    return $fis;
}

=head2 taxa

 usage   :
 function:
 args    :
 returns :

=cut

requires 'taxa';

=head2 frag

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag';

=head2 hash_sites_by_pos

 usage   :
 function: hash sites by their position and type, giving
           a list of sources and a hash of lists of pmids
           keyed by throughput (instead of the default
           simple list of sites)
 args    :
 returns :

=cut

sub hash_sites_by_pos {
    my($self) = @_;

    my $sites;
    my $site;
    my $pmid;

    $sites = {};
    foreach $site ($self->sites) {
        defined($sites->{$site->pos}->{$site->type->type}) or ($sites->{$site->pos}->{$site->type->type} = {sources => {}, pmids => {}});
        $sites->{$site->pos}->{$site->type->type}->{sources}->{$site->source}++;

        foreach $pmid ($site->pmids) {
            $sites->{$site->pos}->{$site->type->type}->{pmids}->{$pmid->throughput}->{$pmid->pmid}++;
        }
    }

    return $sites;
}

=head2 charge

 usage   : ($res_str, $charge) = $seq->charge(1, 2, 10, 15, 20);
 function: given a list of positions in the sequence, will return a sum of
           their charges and a string with just those residues. If no positions
           are given, will return the sum of charges of all residues

           where
               - D or E: charge -1
               - K or R: charge +1

 args    : a list of integers, = positions in the sequence
 returns : a signed integer and a string

=cut

sub charge {
    my($self, @posns) = @_;

    my $str;
    my $charge;
    my $pos;
    my $aa;

    $charge = 0;
    if(@posns > 0) {
        $str = [];
        foreach $pos (@posns) {
            if($pos < 1) {
                Carp::cluck("position $pos is < 1");
                Carp::cluck(sprintf("position %d is < seq %d position 1", $pos, $self->id));
            }
            elsif($pos > $self->len) {
                Carp::cluck(sprintf("position %d is > seq %d length %d", $pos, $self->id, $self->len));
            }
            else {
                $aa = substr($self->seq, $pos - 1, 1);
                push @{$str}, $aa;

                if($aa =~ /[DE]/) {
                    --$charge;
                }
                elsif($aa =~ /[KR]/) {
                    ++$charge;
                }
            }
        }
        $str = join '', @{$str};
    }
    else {
        $str = $self->seq;

        while($str =~ /[DE]/g) {
            --$charge;
        }

        while($str =~ /[KR]/g) {
            ++$charge;
        }
    }

    return($charge, $str);
}

=head2 hydrophobicity

 usage   : ($res_str, $charge) = $seq->hydrophobicity(1, 2, 10, 15, 20);
 function: given a list of positions in the sequence, will return the sum of
           their Kyte and Doolittle hydrophibicity score (PMID: 7108955) and
           a string with just those residues. If no positions are given, will
           return the sum for all residues.

 args    : a list of integers, = positions in the sequence
 returns : a signed integer and a string

=cut

sub hydrophobicity {
    my($self, @posns) = @_;

    my $kd_scores;
    my $scores;
    my $str;
    my $charge;
    my $pos;
    my @aas;
    my $aa;
    my $hydrophobicity;

    $kd_scores = {
                  I =>  4.5,
                  V =>  4.2,
                  L =>  3.8,
                  F =>  2.8,
                  C =>  2.5,
                  M =>  1.9,
                  A =>  1.8,
                  G => -0.4,
                  T => -0.7,
                  S => -0.8,
                  W => -0.9,
                  Y => -1.3,
                  P => -1.6,
                  H => -3.2,
                  E => -3.5,
                  Q => -3.5,
                  D => -3.5,
                  N => -3.5,
                  K => -3.9,
                  R => -4.5,
                 };
    $scores = $kd_scores;

    $hydrophobicity = 0;
    if(@posns > 0) {
        $str = [];
        foreach $pos (@posns) {
            if($pos < 1) {
                Carp::cluck("position $pos is < 1");
                Carp::cluck(sprintf("position %d is < seq %d position 1", $pos, $self->id));
            }
            elsif($pos > $self->len) {
                Carp::cluck(sprintf("position %d is > seq %d length %d", $pos, $self->id, $self->len));
            }
            else {
                $aa = substr($self->seq, $pos - 1, 1);
                push @{$str}, $aa;
                $hydrophobicity += (defined($scores->{$aa}) ? $scores->{$aa} : 0);
            }
        }
        $str = join '', @{$str};
    }
    else {
        $str = $self->seq;
        @aas = split //, $str;
        foreach $aa (@aas) {
            $hydrophobicity += (defined($scores->{$aa}) ? $scores->{$aa} : 0);
        }
    }

    return($hydrophobicity, $str);
}

=head2 seq_flank

 usage   : $aas = $seq->seq_flank($pos, $flank);
 function: given a position in the sequence, will return a string containg the the sequence
           from $flank residues before the position to $flank residues after the position,
           with the residue at the position given in lowercase.
 args    : a position and a flank size
 returns : a string

=cut

sub seq_flank {
    my($self, $pos, $flank) = @_;

    my $nterm;
    my $res;
    my $cterm;
    my $subseq;
    my $start;
    my $len;

    ($nterm = substr($self->seq, $pos - $flank - 1, $flank)) =~ tr/[a-z]/[A-Z]/;
    ($res   = substr($self->seq, $pos - 1, 1)) =~ tr/[A-Z]/[a-z]/;
    ($cterm = substr($self->seq, $pos, $flank)) =~ tr/[a-z]/[A-Z]/;

    $subseq = join '', $nterm, $res, $cterm;

    return $subseq;
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
 with 'Fist::Utils::IUPred';
 with 'Fist::Utils::Hmmscan';
 with 'Fist::Utils::PESTFind';

=cut

with 'Fist::Utils::UniqueIdentifier';
with 'Fist::Utils::Cache';
with 'Fist::Utils::IUPred';
with 'Fist::Utils::Hmmscan';
with 'Fist::Utils::PESTFind';

=head1 METHODS

=cut

requires 'add_to_aliases';
requires 'add_to_feature_insts';
requires 'add_to_taxa';

=head2 get_new_feature_inst

 usage   :
 function:
 args    :
 returns :

=cut

requires 'get_new_feature_inst';

=head2 url_in_source

 usage   :
 function:
 args    :
 returns :

=cut

# FIXME - url template should be specified in the db

sub url_in_source {
    my($self) = @_;

    my $url;

    if($self->source =~ /\Auniprot/) {
        $url = 'http://www.uniprot.org/uniprot/' . $self->primary_id;
    }

    return $url;
}

=head2 ids_taxa

 usage   :
 function:
 args    :
 returns :

=cut

sub ids_taxa {
    my($self) = @_;

    my $ids_taxa;
    my $taxon;

    # FIXME - cache this

    $ids_taxa = {};
    foreach $taxon ($self->taxa) {
        $ids_taxa->{$taxon->id}++;
    }
    $ids_taxa = [sort {$a <=> $b} keys %{$ids_taxa}];

    return $ids_taxa;
}

=head2 initialise_site_info

 usage   :
 function: initialise site info from input search text
 args    :
 returns :

=cut

sub initialise_site_info {
    my($self, $json) = @_;

    my $site_info;
    my $alias;
    my $pos;
    my $site_query;
    my $site;
    my $label;
    my $given_res;
    my $res2;
    my $source;
    my $ac_src;
    my $fis;
    my $fi;

    $site_info = {
                  sites                 => {},
                  fh_to_interface_sites => {},
                  ch_to_interface_sites => {},
                 };
    foreach $alias (keys %{$json->{results}->{search}->{seqs_to_aliases}->{$self->id}}) {
        foreach $pos (keys %{$json->{temporary_search}->{aliases}->{$alias}->{posns}}) {
            # store the residue found in this sequence at this position, for checking against the given residue

            defined($site_info->{sites}->{$pos}) or ($site_info->{sites}->{$pos} = {sites => {}});

            foreach $site_query (@{$json->{temporary_search}->{aliases}->{$alias}->{posns}->{$pos}}) {
                # Initially saving different sites at the same position in a hash keyed by the site label,
                # so that the same site coming from different sequence aliases is not counted more than once.
                # The hash of sites will be converted to a list later on.

                if(!defined($site_info->{$pos}->{sites}->{$site_query->{label_orig}})) {
                    $site = $self->site_new($pos, $site_query->{res2}, $site_query->{res});
                    $site_info->{sites}->{$pos}->{sites}->{$site_query->{label_orig}} = $site;

                    $site->{label_orig} = $site_query->{label_orig};

                    $label = $site_query->{label};
                    $label = ($label =~ /\A\[(\S+)\]\Z/) ? $1 : join('', $site->{res}, $pos, $label);
                    $site->{label} = $label;
                }
            }
        }
    }

    # add extSites if selected
    if(defined($json->{params}->{processed}->{extSites})) {
        foreach $source (keys %{$json->{params}->{processed}->{extSites}}) {
            foreach $ac_src (keys %{$json->{params}->{processed}->{extSites}->{$source}}) {
                $fis = $self->feature_insts_by_source($source, $ac_src);
                foreach $fi (@{$fis->{$source}}) {
                    if($fi->end_seq == $fi->start_seq) { # only taking features that cover a single amino acid for now
                        $pos = $fi->start_seq;
                        if($fi->description =~ /\A(\S)\s*->\s*(\S)/) {
                            ($given_res, $res2) = ($1, $2);
                        }
                        elsif($fi->description =~ /\APhosphoserine/) {
                            ($given_res, $res2) = qw(S Sp);
                        }
                        elsif($fi->description =~ /\APhosphothreonine/) {
                            ($given_res, $res2) = qw(T Tp);
                        }
                        elsif($fi->description =~ /\APhosphoserine/) {
                            ($given_res, $res2) = qw(Y Yp);
                        }
                        else {
                            ($given_res, $res2) = (undef, 'X');
                        }
                        $site = $self->site_new($pos, $res2, $given_res);
                        $site->{label_orig} = $fi->description;
                        $label = join(' ', join('', $site->{res}, $pos, $res2), $source, $ac_src);
                        $site->{label} = $label;
                        $site_info->{sites}->{$pos}->{sites}->{$label} = $site;
                        $json->{results}->{search}->{n_sites_from_elsewhere}++;
                    }
                }
            }
        }
    }

    foreach $pos (keys %{$site_info->{sites}}) {
        # convert the hashes of sites to lists
        $site_info->{sites}->{$pos}->{sites} = [values %{$site_info->{sites}->{$pos}->{sites}}]
    }

    return $site_info;
}

=head2 get_site_info_from_params

=cut

sub get_site_info_from_params {
    my($self, $json, $params, $suffix) = @_;

    my $site_info;
    my $posns;
    my $pos;
    my $labels;
    my $colours;
    my $bg_colours;
    my $i;
    my $res_from_label;
    my $pos_from_label;
    my $label_minus_res_and_pos;
    my $res2;
    my $site;

    $site_info = {
                  sites                 => {},
                  fh_to_interface_sites => {},
                  ch_to_interface_sites => {},
                 };

    if(defined($params->{"pos$suffix"})) {
        $posns = [split /,/, $params->{"pos$suffix"}];

        foreach $pos (@{$posns}) {
            defined($site_info->{sites}->{$pos}) or ($site_info->{sites}->{$pos} = {sites => []});
        }

        if(defined($params->{"label$suffix"})) {
            $labels = [split /,/, $params->{"label$suffix"}];
            for($i = 0; $i < @{$labels}; $i++) {
                defined($pos = $posns->[$i]) or last;

                # FIXME - what if this site has already been processed as part of a search?

                ($res_from_label, $pos_from_label, $label_minus_res_and_pos, $res2) = Fist::Utils::Search::parse_label($labels->[$i]);
                #warn "PARSE_LABEL: Seq: res = '$res_from_label', pos = '$pos_from_label', label = '$label_minus_res_and_pos', res2 = '$res2'";
                $site = $self->site_new($pos, $res2);
                push @{$site_info->{sites}->{$pos}->{sites}}, $site;
                $site->{label} = $labels->[$i];

                # FIXME - check that $res_from_label agrees with res at this position in the sequence
            }
        }

        if(defined($params->{"colour$suffix"})) {
            $colours = [split /,/, $params->{"colour$suffix"}];
            for($i = 0; $i < @{$colours}; $i++) {
                defined($pos = $posns->[$i]) or last;
                $site->{colour} = $colours->[$i];
            }
        }

        if(defined($params->{"bg_colour$suffix"})) {
            $bg_colours = [split /,/, $params->{"bg_colour$suffix"}];
            for($i = 0; $i < @{$bg_colours}; $i++) {
                defined($pos = $posns->[$i]) or last;
                $site->{bg_colour} = $bg_colours->[$i];
            }
        }

        return $site_info;
    }
    else {
        return undef;
    }
}

=head2 site_new

=cut

sub site_new {
    my($self, $pos, $res2, $given_res) = @_;

    my $site_info;

    $site_info = {
                  id         => ++$id_site,
                  pos        => $pos,
                  res        => (($pos >= 0) and ($pos <= $self->len)) ? substr($self->seq, $pos - 1, 1) : '*',
                  given_res  => '',
                  res2       => defined($res2) ? $res2 : '', # the substituted residue, if any. Parsed from the label.
                  disordered => 0,
                  blosum62   => 0,
                  label      => '',
                  label_orig => '',
                  colour     => '',
                  bg_colour  => '',
                  ppis       => {}, # keyed by ContactHit.id
                  pcis       => {}, # keyed by type_chem, id_chem, and (pseudo) FragHit.id. Includes DNA/RNA as well as chems
                  structs    => {}, # keyed by (pseudo) FragHit.id
                  mechProt   => 0,
                  mechChem   => 0,
                  mechDNA    => 0,
                  mechScore  => 0,
                 };
    $site_info->{given_res} = defined($given_res) ? $given_res : $site_info->{res};
    $site_info->{blosum62} = $mat_blosum62->value($site_info->{res}, $site_info->{res2});

    return $site_info;
}

=head2 structs

 usage   :
 function: gets structure matches
 args    :
 returns :

=cut

sub structs {
    my($self, $schema, $json, $results_type, $all_structs, $site_info) = @_;

    my $seq_to_idcode;
    my $seq_a1;
    my $id_seq_a1;
    my @hsps;
    my $hsp;
    my $id_seq_a2;
    my $id_frag;
    my $seq_a2;
    my $frag;
    my $id_fh;
    my $posns;
    my $min_pos;
    my $max_pos;
    my $n_posns;
    my $found;
    my $n_found;
    my $n_sites;
    my $pos_a1;
    my $site;
    my $start_a1;
    my $end_a1;
    my $dbh;
    my $query;
    my $sth_naccess;
    my $table_naccess;
    my $aln;
    my $pos_a2;
    my $chain_a2;
    my $resseq_a2;
    my $icode_a2;
    my $res3;
    my $acc;
    my $acc_s;
    my @keep;
    my $idcode;

    $seq_to_idcode = {};
    $seq_a1 = $self;
    $id_seq_a1 = $seq_a1->id;

    if(defined($site_info->{sites}) and (keys(%{$site_info->{sites}}) > 0)) {
        $posns = [sort {$a <=> $b} keys %{$site_info->{sites}}];
        $min_pos = $posns->[0];
        $max_pos = $posns->[$#{$posns}];
        $n_posns = scalar @{$posns};
        $found = {};
        $n_found = 0;

        $dbh = $schema->storage->dbh;
        $query = <<END;
SELECT a.chain,
       a.resseq,
       a.icode,
       a.res3,
       b.acc,
       b.acc_s
FROM   (
        SELECT *
        FROM   FragResMapping
        WHERE  id_frag = ?
        AND    fist = ?
       ) AS a
LEFT JOIN FragNaccess AS b
ON  b.id_frag = a.id_frag
AND b.chain   = a.chain
AND b.resseq = a.resseq
AND b.icode = a.icode
END
        $sth_naccess = $dbh->prepare($query);

        @hsps = $schema->resultset('Hsp')->search(
                                                  {
                                                   id_seq1       => $id_seq_a1,
                                                   pcid          => {'>=' => $json->{params}->{processed}->{min_pcid}},
                                                   'seq2.source' => 'fist',
                                                  },
                                                  {
                                                   prefetch => ['seq2', 'aln'],
                                                  },
                                                 )->all;

        #printf "SELECT * FROM Hsp AS h, Seq AS s2 WHERE h.id_seq1 = %d AND h.pcid >= %f AND s2.id = h.id_seq2 AND s2.source = 'fist';\n", $id_seq_a1, $json->{params}->{processed}->{min_pcid};
        #printf "n_hsps = %d, n_posns = %d\n", scalar @hsps, $n_posns;

        # order the hsps by descending pcid and then only use the best Hsp
        # that covers a particular site unless 'all_structs' specified.
        # FIXME - only use additional structs that have a SEP, TPO or PTR in the right position
        @hsps = sort {$b->pcid <=> $a->pcid} @hsps;
        foreach $hsp (@hsps) {
            $start_a1 = $hsp->start1;
            $end_a1 = $hsp->end1;
            (($start_a1 > $max_pos) or ($end_a1 < $min_pos)) and next; # doesn't cover any of the sites

            $id_seq_a2 = $hsp->id_seq2;
            $aln = $hsp->aln;
            $json->{results}->{$results_type}->{counts}->{alignments}->{$aln->id}++;

            $seq_a2 = $hsp->seq2;
            $frag = $seq_a2->frag;
            $id_frag = $frag->id;

            # which sites are covered by this hsp?
            $n_sites = 0;
            $idcode = $frag->idcode;
            foreach $pos_a1 (@{$posns}) {
                defined($found->{$pos_a1}) and !defined($all_structs) and next;
                if(($start_a1 <= $pos_a1) and ($end_a1 >= $pos_a1)) {
                    # check that pos_a1 is actually mapped to a position in the structure and not to a gap
                    $pos_a2 = $aln->map_position($id_seq_a1, $pos_a1, $id_seq_a2);
                    if($pos_a2 != 0) {
                        $sth_naccess->execute($id_frag, $pos_a2);
                        $table_naccess = $sth_naccess->fetchall_arrayref;
                        if(@{$table_naccess} > 0) {
                            ($chain_a2, $resseq_a2, $icode_a2, $res3, $acc, $acc_s) = @{$table_naccess->[0]};
                            defined($found->{$pos_a1}) and !defined($all_structs) and next;
                            # FIXME - filter additional HSPs for modified res3, eg. ($res3 eq 'SEP') or ($res3 eq 'TPO') or ($res3 eq 'PTR'),
                            # for when we want to look at modifications mapped to specific modified residues in the pdb.

                            $found->{$pos_a1}++;
                            foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
                                # FIXME - this could be stored per position, although the change in the residue may become important later,
                                $site->{struct}->{$hsp->id} = {
                                                               idcode    => $idcode,
                                                               id_frag   => $id_frag,
                                                               id_aln    => $aln->id,
                                                               pos_a2    => $pos_a2,
                                                               res_a2    => substr($seq_a2->seq, $pos_a2 - 1, 1),
                                                               chain_a2  => $chain_a2,
                                                               resseq_a2 => $resseq_a2,
                                                               icode_a2  => $icode_a2,
                                                               res3      => $res3, # res3 = three-letter residue code for matched template residue
                                                               acc       => $acc,
                                                               acc_s     => $acc_s,
                                                              };
                                $n_sites++;
                            }
                        }
                    }
                }
            }

            # only save this frag and hsp if they cover at least one site
            if($n_sites > 0) {
                _json_add_frag($json, $frag, $id_seq_a2, $results_type, $dbh);
                _json_add_hsp($json, $hsp);
            }

            $n_found = scalar keys %{$found};
            #($n_found >= $n_posns) and !defined($all_structs) and last;
            if(($n_found >= $n_posns) and !defined($all_structs)) {
                #print "all posns found\n";
                last;
            }
        }

        #foreach $pos_a1 (@{$posns}) {
        #    print join("\t", $pos_a1, $found->{$pos_a1} ? 'FOUND' : 'MISSED'), "\n";
        #}
    }
}

=head2 ppis_known

 usage   :
 function: gets known protein-protein interactions from string tables
 args    :
 returns :

=cut

sub ppis_known {
    my($self, $schema, $json, $results_type) = @_;

    # FIXME - move this to a proper method in (eg.) StringInt.pm ?

    # NOTE - not storing any info about these sequences in $json->{results}->{$results_type}->{seqs},
    # am assuming that all that is needed here is their database ids and
    # that any other info will be added if structural templates for the
    # interactions are found.
    #
    # FIXME - this might change if I want to indicate known interactions
    # for which no structural template is found.

    my $dbh;
    my $query;
    my $sth;
    my $table;
    my $row;
    my $seq_a1;
    my $id_seq1;
    my $id_seq2;
    my $id_string1;
    my $id_string2;
    my $score;
    my $ac;

    $dbh = $schema->storage->dbh;
    $query = 'SELECT id_seq2, id_string1, id_string2, score FROM StringInt WHERE id_seq1 = ? AND score >= ?';
    $sth = $dbh->prepare($query);
    $seq_a1 = $self;
    $id_seq1 = $seq_a1->id;
    $sth->execute($id_seq1, $json->{params}->{processed}->{known_min_string_score});
    $table = $sth->fetchall_arrayref;
    foreach $row (@{$table}) {
        ($id_seq2, $id_string1, $id_string2, $score) = @{$row};

        defined($json->{temporary}->{known_ints}->{$id_seq1}->{$id_seq2}) or ($json->{temporary}->{known_ints}->{$id_seq1}->{$id_seq2} = []);
        push @{$json->{temporary}->{known_ints}->{$id_seq1}->{$id_seq2}}, [$id_string1, $id_string2, $score];
        $ac = join ':', (sort {$a <=> $b} $id_seq1, $id_seq2);
        $json->{results}->{$results_type}->{counts}->{known_ints}->{$ac}++;
    }
}

=head2 process_contact_hits

 usage   :
 function: gets contact hits and map sites to them
 args    :
 returns :

=cut

sub process_contact_hits {
    my($self, $schema, $json, $mat_ss, $mat_prot_chem_class, $mat_conf, $results_type, $site_info) = @_;

    my $dbh;
    my $seq_a1;
    my $id_seq_a1;
    my $min_pcid;
    my @contact_hits;
    my $types_chem;
    my $sth;
    my $id_seq_b1_p;
    my $desc_b1;
    my $primary_id_b1;
    my $name_b1;
    my $ch;
    my $id_ch;
    my $type_ch;
    my $pcid;
    my $id_seq_b1;
    my $seq_b1;
    my $c;
    my $ac;
    my $idcode;
    my $pdbTitle;
    my $table;
    my $row;
    my $id_chem;
    my $type_chem;

    $dbh = $schema->storage->dbh;

    $seq_a1 = $self;
    $id_seq_a1 = $seq_a1->id;
    json_add_seq($json, $id_seq_a1, $seq_a1->name, $seq_a1->primary_id, $seq_a1->description, 'query', $results_type);

    ($min_pcid) = (
                   sort {$a <=> $b} (
                                     $json->{params}->{processed}->{min_pcid_hetero},
                                     $json->{params}->{processed}->{min_pcid_homo},
                                     $json->{params}->{processed}->{min_pcid_nuc},
                                     $json->{params}->{processed}->{min_pcid_chem},
                                    )
                  );
    @contact_hits = $schema->resultset('ContactHit')->search({id_seq_a1 => $id_seq_a1, pcid_a => {'>=' => $min_pcid}, pcid_b => {'>=' => $min_pcid}})->all;
    @contact_hits = sort {$b->id_seq_b1 <=> $a->id_seq_b1} @contact_hits;

    $sth = $dbh->prepare('SELECT id_chem, type FROM PdbChem');
    $sth->execute;
    $table = $sth->fetchall_arrayref;
    $types_chem = {};
    foreach $row (@{$table}) {
        $types_chem->{$row->[0]} = $row->[1];
    }

    $id_seq_b1_p = -1;
    defined($json->{params}->{given}->{isoforms}) or ($json->{params}->{given}->{isoforms} = 'no');
    foreach $ch (@contact_hits) {
        #$type_ch = $ch->type($dbh);
        $type_ch = $ch->type;
        $id_ch = $ch->id;
        #($type_ch eq 'PCInqm') or next;
        #print "TYPE: $type_ch\n";

        $pcid = $ch->pcid;

        if($type_ch eq 'PPI') {
            $type_chem = 'peptide';
            $id_seq_b1 = $ch->id_seq_b1;

            # - if known_min_string_score is not defined or is <= 0, take all contact hits
            # - otherwise, assume that only knowns at the correct level (or higher) were read in and check against those
            # - otherwise, if both pcid_a and pcid_b are >= min_pcid_known, call
            #   the interaction 'known' purely on the basis of the structure match
            if(
               !defined($json->{params}->{processed}->{known_min_string_score})
               or ($json->{params}->{processed}->{known_min_string_score} <= 0)
               or defined($json->{temporary}->{known_ints}->{$id_seq_a1}->{$id_seq_b1})
               or ($pcid >= $json->{params}->{processed}->{min_pcid_known})
              ) {

                if($id_seq_b1 != $id_seq_b1_p) {
                    $seq_b1 = $ch->get_seq($id_seq_b1);
                    $desc_b1 = $seq_b1->description;
                    $primary_id_b1 = $seq_b1->primary_id;
                    $name_b1 = $seq_b1->name;
                    ($name_b1 eq '') and ($name_b1 = $primary_id_b1);
                }
                $id_seq_b1_p = $id_seq_b1;

                # ignore isoform interactors
                ($json->{params}->{given}->{isoforms} eq 'no') and ($seq_b1->source eq 'varsplic') and next;

                # ignore interactions with some proteins
                # FIXME - don't hardcode the ignore list / rules, put them in a file or in the db
                if($desc_b1 !~ /\AIg \S+ chain/) {
                    defined($c = $ch->contact) or next;

                    # ignore interactions that use crystal contacts
                    if(!$c->crystal) {
                        # filter homo and hetero differently
                        $min_pcid = $c->homo ? $json->{params}->{processed}->{min_pcid_homo} : $json->{params}->{processed}->{min_pcid_hetero};
                        if($pcid >= $min_pcid) {
                            $ac = join ':', (sort {$a <=> $b} $id_seq_a1, $id_seq_b1);
                            $json->{results}->{$results_type}->{counts}->{known_ints}->{$ac}++; # FIXME - should be counting 'known int, template found'?

                            # save this ppi
                            json_add_seq($json, $id_seq_b1, $name_b1, $primary_id_b1, $desc_b1, 'friend', $results_type);
                            ($idcode, $pdbTitle) = _get_contact_pdb($dbh, $c->id);
                            _json_add_contact_hit($json, $idcode, $pdbTitle, $id_seq_a1, $type_chem, $id_seq_b1, $ch->id, $ch, $mat_conf, $results_type);

                            # record any sites involved in the interface
                            if(!defined($ch->hsp_a)) {
                                Carp::cluck(sprintf("hsp_a undefined for ContactHit %d", $ch->id));
                                next;
                            }

                            if(!defined($ch->hsp_b)) {
                                Carp::cluck(sprintf("hsp_b undefined for ContactHit %d", $ch->id));
                                next;
                            }

                            $ch->map_sites($dbh, $json, $type_chem, $id_seq_b1, $mat_ss, $mat_conf, $results_type, $site_info, $seq_a1, $seq_b1);
                        }
                    }
                }
            }
        }
        elsif($type_ch =~ /^PPI/) {
            # interaction with a peptide that is not matched to a query protein
            $type_chem = 'Peptide';
            $c = $ch->contact;
            #$id_chem = $ch->contact->frag_inst2->frag->chemical_type;
            $id_chem = $c->type_frag2($dbh);

            if(!$c->crystal) {
                # filter homo and hetero differently
                $min_pcid = $c->homo ? $json->{params}->{processed}->{min_pcid_homo} : $json->{params}->{processed}->{min_pcid_hetero};
                if($pcid >= $min_pcid) {
                    # save this ppi
                    ($idcode, $pdbTitle) = _get_contact_pdb($dbh, $c->id);
                    _json_add_contact_hit($json, $idcode, $pdbTitle, $id_seq_a1, $type_chem, $id_chem, $ch->id, $ch, $mat_conf, $results_type);

                    # record any sites in the interface
                    $ch->map_sites($dbh, $json, $type_chem, $id_chem, $mat_ss, $mat_conf, $results_type, $site_info, $seq_a1, undef);
                }
            }
        }
        elsif($type_ch =~ /^PDI/) {
            $type_chem = 'DNA/RNA';
            #$id_chem = $ch->contact->frag_inst2->frag->chemical_type;
            $c = $ch->contact;
            $id_chem = $c->type_frag2($dbh);

            if($pcid >= $json->{params}->{processed}->{min_pcid_nuc}) {
                # save this pdi
                ($idcode, $pdbTitle) = _get_contact_pdb($dbh, $c->id);
                _json_add_contact_hit($json, $idcode, $pdbTitle, $id_seq_a1, $type_chem, $id_chem, $ch->id, $ch, $mat_conf, $results_type);

                # record any sites in the interface
                $ch->map_sites($dbh, $json, $type_chem, $id_chem, $mat_prot_chem_class, $mat_conf, $results_type, $site_info, $seq_a1, undef);
            }
        }
        elsif($type_ch =~ /^PCI/) {
            $c = $ch->contact;
            $id_chem = $c->type_frag2($dbh);
            #$id_chem = $ch->contact->frag_inst2->frag->chemical_type;
            $type_chem = defined($types_chem->{$id_chem}) ? $types_chem->{$id_chem} : 'Unknown';

            # should this chem be ignored?
            (($type_chem eq 'Unknown') or ($type_chem eq 'Exp-mod') or ($type_chem eq 'Medium') or ($type_chem eq 'IGNORE')) and next;

            if($pcid >= $json->{params}->{processed}->{min_pcid_chem}) {
                #$c = $ch->contact;

                # save this pci
                ($idcode, $pdbTitle) = _get_contact_pdb($dbh, $c->id);
                _json_add_contact_hit($json, $idcode, $pdbTitle, $id_seq_a1, $type_chem, $id_chem, $ch->id, $ch, $mat_conf, $results_type);

                # record any sites in the interface
                $ch->map_sites($dbh, $json, $type_chem, $id_chem, $mat_prot_chem_class, $mat_conf, $results_type, $site_info, $seq_a1, undef);
            }
        }
        else {
            Carp::cluck(sprintf("unrecognised type '%s' ContactHit %d", $type_ch, $ch->id));
            next;
        }
    }
}

sub _get_contact_pdb {
    my($dbh, $id) = @_;

    my $query;
    my $sth;
    my $table;
    my $idcode;
    my $title;

    $query = <<END;
SELECT pdb.idcode,
       pdb.title
FROM   Contact  AS c,
       FragInst AS fi,
       Frag     AS f,
       Pdb      AS pdb
WHERE  c.id = ?
aND    fi.id = c.id_frag_inst1
AND    f.id = fi.id_frag
AND    pdb.idcode = f.idcode
END
    $sth = $dbh->prepare($query);
    $sth->execute($id);
    $table = $sth->fetchall_arrayref;
    ($idcode, $title) = @{$table->[0]};

    return($idcode, $title);
}

=head2 prot_and_site_tables

 usage   :
 function:
 args    :
 returns :

=cut

sub prot_and_site_tables {
    my($self, $schema, $json, $prot_tables, $prot_countss, $site_tables, $site_countss, $results_type, $all_ppis, $site_info) = @_;

    my $alias;
    my $id_seq_a1;
    my $id_seq_b1;
    my $seq_a1;
    my $fis_a1;
    my $fi_a1;
    my $aliases;
    my $pos_a1;
    my $site;
    my $n_iupred;

    my $ids_fh; # FIXME - remove
    my $id_fh;
    my $fhs;
    my $fh;

    my $ids_hsps;
    my $id_hsp;
    my $hsp;
    my $structs;
    my $struct;

    my $pos_a1_str;
    my $label_a1_str;
    my $ids_ch;
    my $ids_ch_b1;
    my $id_ch;
    my $i;
    my $nP;
    my $ppis;
    my $ch;
    my $type_chem;
    my $id_chem;
    my $nC;
    my $pcis;
    my $nD;
    my $pdis;
    my $mechProt;
    my $mechChem;
    my $mechDNA;
    my $mechScore;
    my $absProt;
    my $absChem;
    my $absDNA;
    my $prot_info;
    my $acc_site;
    my $category;
    my $prot_table;
    my $prot_counts;
    my $site_table;
    my $site_counts;
    my $idcode;

    $seq_a1 = $self;
    $id_seq_a1 = $seq_a1->id;

    $aliases = defined($json->{results}->{search}->{seqs_to_aliases}->{$id_seq_a1}) ? [sort keys %{$json->{results}->{search}->{seqs_to_aliases}->{$id_seq_a1}}] : [$seq_a1->primary_id];
    $aliases = join '|', @{$aliases};

    $fis_a1 = $seq_a1->feature_insts_by_source;
    foreach $prot_counts (@{$prot_countss}) {
        $prot_counts->{unique}->{n}->{$id_seq_a1}++;
    }

    $prot_info = {
                  nSites        => 0,
                  nMismatch     => 0,
                  minB62        => 999999,
                  maxB62        => -999999,
                  nDi           => 0,
                  nS            => 0,
                  nP            => 0,
                  nC            => 0,
                  nD            => 0,
                  maxNegativeIE => 999999,
                  maxPositiveIE => -999999,
                  mechScore     => 0,
                 };

    foreach $pos_a1 (keys %{$site_info->{sites}}) {
        if(defined($site_info->{sites}->{$pos_a1}->{sites})) {
            $prot_info->{nSites} += scalar @{$site_info->{sites}->{$pos_a1}->{sites}};

            # some things are the same for all sites at a particular position:

            # disorder
            $n_iupred = 0;
            if(defined($fis_a1->{iupred})) {
                foreach $fi_a1 (@{$fis_a1->{iupred}}) {
                    ($fi_a1->start_seq <= $pos_a1) and ($fi_a1->end_seq >= $pos_a1) and ++$n_iupred;
                }
            }

            # get position and label strings that include all sites at this position
            $pos_a1_str = [];
            $label_a1_str = [];
            foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
                push @{$pos_a1_str}, $pos_a1;
                push @{$label_a1_str}, $site->{label};
            }
            $pos_a1_str = join ',', @{$pos_a1_str};
            $label_a1_str = join ',', @{$label_a1_str};

            # some things are different for different sites at the same position
            foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
                $mechProt = 0;
                $mechChem = 0;
                $mechDNA = 0;

                $acc_site = sprintf "%s/%s:%s", $id_seq_a1, $pos_a1, $site->{label};
                foreach $site_counts (@{$site_countss}) {
                    $site_counts->{unique}->{n}->{$acc_site}++;
                }

                foreach $site_table (@{$site_tables}) {
                    $site_table->add_row($site->{id});
                    $site_table->element($site->{id}, 'id_seq',      $id_seq_a1);
                    $site_table->element($site->{id}, 'name',        $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{name});
                    $site_table->element($site->{id}, 'primary_id',  $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{primary_id});
                    $site_table->element($site->{id}, 'pos_a1',      $pos_a1);
                    $site_table->element($site->{id}, 'res1_a1',     $site->{res});
                    $site_table->element($site->{id}, 'res2_a1',     $site->{res2});
                    $site_table->element($site->{id}, 'site',        $site->{label});
                    $site_table->element($site->{id}, 'user_input',  join('/', $aliases, $site->{label_orig} ? $site->{label_orig} : $site->{label}));
                }

                if($site->{given_res} ne $site->{res}) {
                    foreach $site_table (@{$site_tables}) {
                        $site_table->element($site->{id}, 'mismatch', sprintf("%s != %s", $site->{given_res}, $site->{res}));
                    }
                    ++$prot_info->{nMismatch};
                    foreach $site_counts (@{$site_countss}) {
                        $site_counts->{mismatch}->{n}->{$acc_site}++;
                    }
                    foreach $prot_counts (@{$prot_countss}) {
                        $prot_counts->{mismatch}->{n}->{$id_seq_a1}++;
                    }
                }

                foreach $site_table (@{$site_tables}) {
                    $site_table->element($site->{id}, 'blosum62', $site->{blosum62});
                }
                ($site->{blosum62} < $prot_info->{minB62}) and ($prot_info->{minB62} = $site->{blosum62});
                ($site->{blosum62} > $prot_info->{maxB62}) and ($prot_info->{maxB62} = $site->{blosum62});

                # disorder
                if($n_iupred > 0) {
                    $site->{disordered} = 1;

                    foreach $site_table (@{$site_tables}) {
                        $site_table->element($site->{id}, 'disordered', 'Y');
                    }
                    ++$prot_info->{nDi};
                    foreach $site_counts (@{$site_countss}) {
                        $site_counts->{disordered}->{n}->{$acc_site}++;
                    }
                    foreach $prot_counts (@{$prot_countss}) {
                        $prot_counts->{disordered}->{n}->{$id_seq_a1}++;
                    }
                }

                # structure
                $ids_hsps = [sort {$json->{temporary}->{hsps}->{$b}->pcid <=> $json->{temporary}->{hsps}->{$a}->pcid} keys %{$site->{struct}}];
                if(@{$ids_hsps} > 0) {
                    $structs = [];
                    foreach $id_hsp (@{$ids_hsps}) {
                        # FIXME - use Hsp->TO_JSON
                        $hsp = $json->{temporary}->{hsps}->{$id_hsp};
                        $struct = {
                                   id_seq_a1 => $hsp->id_seq1,
                                   start_a1  => $hsp->start1,
                                   end_a1    => $hsp->end1,
                                   id_seq_a2 => $hsp->id_seq2,
                                   start_a2  => $hsp->start2,
                                   end_a2    => $hsp->end2,
                                   pcid      => $hsp->pcid,
                                   e_value   => $hsp->e_value,
                                   id_frag   => $site->{struct}->{$id_hsp}->{id_frag},
                                   idcode    => $site->{struct}->{$id_hsp}->{idcode},
                                   id_aln    => $site->{struct}->{$id_hsp}->{id_aln},
                                   pos_a2    => $site->{struct}->{$id_hsp}->{pos_a2},
                                   res_a2    => $site->{struct}->{$id_hsp}->{res_a2},
                                   chain_a2  => $site->{struct}->{$id_hsp}->{chain_a2},
                                   resseq_a2 => $site->{struct}->{$id_hsp}->{resseq_a2},
                                   icode_a2  => $site->{struct}->{$id_hsp}->{icode_a2},
                                   res3      => $site->{struct}->{$id_hsp}->{res3},
                                   acc       => $site->{struct}->{$id_hsp}->{acc},
                                   acc_s     => $site->{struct}->{$id_hsp}->{acc_s},
                                  };
                        push @{$structs}, $struct;
                    }
                    foreach $site_table (@{$site_tables}) {
                        $site_table->element($site->{id}, 'structure', $structs);
                    }
                    ++$prot_info->{nS};
                    foreach $site_counts (@{$site_countss}) {
                        $site_counts->{structure}->{n}->{$acc_site}++;
                    }
                    foreach $prot_counts (@{$prot_countss}) {
                        $prot_counts->{structure}->{n}->{$id_seq_a1}++;
                    }
                }

                # ppis
                toTables({
                          site          => $site,
                          type_ch       => 'PPI',
                          types_chem    => ['peptide'],
                          nKey          => 'nP',
                          iSiteKey      => 'ppi_site',
                          iKey          => 'ppis',
                          acc_site      => $acc_site,
                          id_seq_a1     => $id_seq_a1,
                          mechScore     => \$mechProt,
                          json          => $json,
                          results_type  => $results_type,
                          all_id_chem   => 1,
                          all_ch        => $all_ppis,
                          site_tables   => $site_tables,
                          prot_info     => $prot_info,
                          site_info     => $site_info,
                          site_countss  => $site_countss,
                          prot_countss  => $prot_countss,
                          intInfo       => \&ppiIntInfo,
                         });

                # pcis
                toTables({
                          site          => $site,
                          type_ch       => 'PCInqm',
                          types_chem    => [keys %{$site->{PCInqm}}],
                          nKey          => 'nC',
                          iSiteKey      => 'pci_site',
                          iKey          => 'pcis',
                          acc_site      => $acc_site,
                          id_seq_a1     => $id_seq_a1,
                          mechScore     => \$mechChem,
                          json          => $json,
                          results_type  => $results_type,
                          all_id_chem   => 0, # only the best contact hit for each chemical type
                          all_ch        => 0,
                          site_tables   => $site_tables,
                          prot_info     => $prot_info,
                          site_info     => $site_info,
                          site_countss  => $site_countss,
                          prot_countss  => $prot_countss,
                          intInfo       => \&pciIntInfo,
                         });

                # pdis
                toTables({
                          site          => $site,
                          type_ch       => 'PDInqm',
                          types_chem    => [keys %{$site->{PDInqm}}],
                          nKey          => 'nD',
                          iSiteKey      => 'pdi_site',
                          iKey          => 'pdis',
                          acc_site      => $acc_site,
                          id_seq_a1     => $id_seq_a1,
                          mechScore     => \$mechDNA,
                          json          => $json,
                          results_type  => $results_type,
                          all_id_chem   => 0, # only the best contact hit for DNA
                          all_ch        => 0,
                          site_tables   => $site_tables,
                          prot_info     => $prot_info,
                          site_info     => $site_info,
                          site_countss  => $site_countss,
                          prot_countss  => $prot_countss,
                          intInfo       => \&pciIntInfo,
                         });

                # mechismo scores
                $mechScore = $mechProt + $mechChem + $mechDNA;
                $site->{mechProt}  = $mechProt;
                $site->{mechChem}  = $mechChem;
                $site->{mechDNA}   = $mechDNA;
                $site->{mechScore} = $mechScore;
                foreach $site_table (@{$site_tables}) {
                    $site_table->element($site->{id}, 'mechProt',  $mechProt);
                    $site_table->element($site->{id}, 'mechChem',  $mechChem);
                    $site_table->element($site->{id}, 'mechDNA',   $mechDNA);
                    $site_table->element($site->{id}, 'mechScore', $mechScore);
                }
                $prot_info->{mechScore} += $mechScore;
            }
        }
    }

    foreach $prot_table (@{$prot_tables}) {
        $prot_table->add_row($id_seq_a1);
        $prot_table->element($id_seq_a1, 'id_seq',        $id_seq_a1);
        $prot_table->element($id_seq_a1, 'name',          $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{name});
        $prot_table->element($id_seq_a1, 'primary_id',    $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{primary_id});
        $prot_table->element($id_seq_a1, 'user_input',    $aliases);
        $prot_table->element($id_seq_a1, 'taxa',          [$seq_a1->taxa]);
        $prot_table->element($id_seq_a1, 'description',   $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{desc});
        $prot_table->element($id_seq_a1, 'nSites',        $prot_info->{nSites});
        $prot_table->element($id_seq_a1, 'nMismatch',     $prot_info->{nMismatch});
        $prot_table->element($id_seq_a1, 'minB62',        $prot_info->{minB62});
        $prot_table->element($id_seq_a1, 'maxB62',        $prot_info->{maxB62});
        $prot_table->element($id_seq_a1, 'nDi',           $prot_info->{nDi});
        $prot_table->element($id_seq_a1, 'nS',            $prot_info->{nS});
        $prot_table->element($id_seq_a1, 'nP',            $prot_info->{nP});
        $prot_table->element($id_seq_a1, 'nC',            $prot_info->{nC});
        $prot_table->element($id_seq_a1, 'nD',            $prot_info->{nD});
        $prot_table->element($id_seq_a1, 'maxNegativeIE', $prot_info->{maxMegativeIE});
        $prot_table->element($id_seq_a1, 'maxPositiveIE', $prot_info->{maxPositiveIE});
        $prot_table->element($id_seq_a1, 'mechScore',     $prot_info->{mechScore});
    }
}

sub toTables {
    my($args) = @_;

    my $site          = $args->{site};
    my $type_ch       = $args->{type_ch};
    my $types_chem    = $args->{types_chem};
    my $nKey          = $args->{nKey};
    my $iSiteKey      = $args->{iSiteKey};
    my $iKey          = $args->{iKey};
    my $acc_site      = $args->{acc_site};
    my $id_seq_a1     = $args->{id_seq_a1};
    my $mechScore     = $args->{mechScore};
    my $json          = $args->{json};
    my $results_type  = $args->{results_type};
    my $all_id_chem   = $args->{all_id_chem};
    my $all_ch        = $args->{all_ch};
    my $site_tables   = $args->{site_tables};
    my $prot_info     = $args->{prot_info};
    my $site_info     = $args->{site_info};
    my $site_countss  = $args->{site_countss};
    my $prot_countss  = $args->{prot_countss};
    my $intInfo       = $args->{intInfo};

    my $nAll;
    my $type_chem;
    my $n;
    my $site_table;
    my $site_counts;
    my $prot_counts;
    my $ids_ch_this;
    my $ids_ch;
    my $ids_ch1;
    my $ids_ch2;
    my $id_ch;
    my $ch;
    my $id_chem; # this will = id_seq_b1 for PPIs
    my $ints;
    my $absScore;

    $nAll = 0;
    $ids_ch = [];
    foreach $type_chem (@{$types_chem}) {
        $n = scalar keys %{$site->{$type_ch}->{$type_chem}};
        if($n > 0) {
            $ids_ch1 = [];
            foreach $id_chem (keys %{$site->{$type_ch}->{$type_chem}}) {
                $ids_ch2 = [sort {$json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$b}->pcid <=> $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$a}->pcid} keys %{$site->{$type_ch}->{$type_chem}->{$id_chem}}];
                if($all_ch) {
                    foreach $id_ch (@{$ids_ch2}) {
                        push @{$ids_ch1}, [$id_chem, $id_ch];
                    }
                }
                else {
                    push @{$ids_ch1}, [$id_chem, $ids_ch2->[0]];
                }
            }
            $ids_ch1 = [sort {$json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$b->[1]}->pcid <=> $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$a->[1]}->pcid} @{$ids_ch1}];
            if($all_id_chem) {
                $nAll += $n;
                foreach $id_ch (@{$ids_ch1}) {
                    ($id_chem, $id_ch) = @{$id_ch};
                    #print join("\t", 'SITE', $site->{id}, $type_chem, $id_chem, $type_ch, $id_ch, defined($site_info->{ch_to_interface_sites}->{$id_ch}) ? 'YES' : 'NO'), "\n";
                    push @{$ids_ch}, [$id_ch, $type_chem, $id_chem];
                }
            }
            else {
                $nAll++;
                $id_ch = $ids_ch1->[0];
                ($id_chem, $id_ch) = @{$id_ch};
                #print join("\t", 'SITE', $site->{id}, $type_chem, $id_chem, $type_ch, $id_ch, defined($site_info->{ch_to_interface_sites}->{$id_ch}) ? 'YES' : 'NO'), "\n";
                push @{$ids_ch}, [$id_ch, $type_chem, $id_chem];
            }
        }
    }

    if(@{$ids_ch} > 0) {
        $ids_ch = [sort {$json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$b->[0]}->pcid <=> $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$a->[0]}->pcid} @{$ids_ch}];
        $ints = [];

        foreach $id_ch (@{$ids_ch}) {
            ($id_ch, $type_chem, $id_chem) = @{$id_ch};
            $ch = $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch};

            push @{$ints}, $intInfo->({
                                       json         => $json,
                                       site         => $site,
                                       results_type => $results_type,
                                       id_ch        => $id_ch,
                                       type_ch      => $type_ch,
                                       type_chem    => $type_chem,
                                       id_chem      => $id_chem,
                                       id_seq_a1    => $id_seq_a1,
                                      });

            $absScore = abs($site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie});
            ($absScore > ${$mechScore}) and (${$mechScore} = $absScore);
            ($site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie} < $prot_info->{maxNegativeIE}) and ($prot_info->{maxNegativeIE} = $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie});
            ($site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie} > $prot_info->{maxPositiveIE}) and ($prot_info->{maxPositiveIE} = $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie});
        }

        foreach $site_table (@{$site_tables}) {
            $site_table->element($site->{id}, $iKey, $ints);
            #print join("\t", 'SITE', $site_table, $site->{id}, $iKey, $ints), "\n";
        }
        ++${$mechScore}; # add one just for being in an interface
    }

    foreach $site_table (@{$site_tables}) {
        $site_table->element($site->{id}, $nKey, $nAll);
    }
    if($nAll > 0) {
        ++$prot_info->{$nKey};
        foreach $site_counts (@{$site_countss}) {
            $site_counts->{$iSiteKey}->{n}->{$acc_site}++;
        }
        foreach $prot_counts (@{$prot_countss}) {
            $prot_counts->{$iSiteKey}->{n}->{$id_seq_a1}++;
        }
    }
}

sub ppiIntInfo {
    my($args) = @_;

    my $json         = $args->{json};
    my $site         = $args->{site};
    my $results_type = $args->{results_type};
    my $id_ch        = $args->{id_ch};
    my $type_ch      = $args->{type_ch};
    my $type_chem    = $args->{type_chem};
    my $id_chem      = $args->{id_chem};
    my $id_seq_a1    = $args->{id_seq_a1};

    my $ch;
    my $int;

    $ch = $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch};

    $int = {
            # common to all interactions
            id_ch         => $id_ch,
            pcid          => $ch->pcid,
            conf          => $ch->conf,
            ie            => $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie},
            ie_class      => $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie_class},
            idcode        => $ch->idcode,
            assembly      => $ch->contact->frag_inst1->assembly,
            model_a       => $ch->contact->frag_inst1->model,
            model_b       => $ch->contact->frag_inst2->model,
            pcid_a        => $ch->pcid_a,
            e_value_a     => $ch->e_value_a,
            rc            => $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{rc}, # residue contacts

            # just for PPIs
            id_seq_b1     => $id_chem,
            primary_id_b1 => $json->{results}->{$results_type}->{seqs}->{$id_chem}->{primary_id},
            name_b1       => $json->{results}->{$results_type}->{seqs}->{$id_chem}->{name},
            pcid_b        => $ch->pcid_b,
            e_value_b     => $ch->e_value_b,
            homo          => $ch->{homo},
            intev         => _intev($json, $ch->pcid, $id_seq_a1, $id_chem),
           };

    return $int;
}

sub pciIntInfo {
    my($args) = @_;

    my $json         = $args->{json};
    my $site         = $args->{site};
    my $results_type = $args->{results_type};
    my $id_ch        = $args->{id_ch};
    my $type_ch      = $args->{type_ch};
    my $type_chem    = $args->{type_chem};
    my $id_chem      = $args->{id_chem};

    my $ch;
    my $int;

    $ch = $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch};
    $int = {
            # common to all interactions
            id_ch         => $id_ch,
            pcid          => $ch->pcid,
            conf          => $ch->conf,
            ie            => $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie},
            ie_class      => $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie_class},
            idcode        => $ch->idcode,
            assembly      => $ch->contact->frag_inst1->assembly,
            model_a       => $ch->contact->frag_inst1->model,
            model_b       => $ch->contact->frag_inst2->model,
            pcid_a        => $ch->pcid_a,
            e_value_a     => $ch->e_value_a,
            rc            => $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{rc}, # residue contacts

            # just for PCIs
            type_chem     => $type_chem,
            id_chem       => $id_chem,
           };

    return $int;
}

# FIXME - refactor: extract function for ppi_table, pci_table and pdi_table

=head2 ppi_table

 usage   :
 function: get tables of protein-protein interactions
 args    :
 returns :

=cut

sub ppi_table {
    my($self, $json, $ppi_table, $id_row, $results_type, $site_info) = @_;

    my $type_ch = 'PPI';
    my $seq_a1;
    my $id_seq_a1;
    my $pos_a1;
    my $site;
    my $type_chem;
    my $ids_ch;
    my $id_ch;
    my $ch;
    my $ids_ch_b1;
    my $id_seq_b1;
    my $ppis;
    my $intev;
    my $n_posns;

    $seq_a1 = $self;
    $id_seq_a1 = $seq_a1->id;
    foreach $pos_a1 (keys %{$site_info->{sites}}) {
        foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
            foreach $type_chem (keys %{$site->{$type_ch}}) { # should only be 'peptide'
                $ids_ch = [];
                foreach $id_seq_b1 (keys %{$site->{$type_ch}->{$type_chem}}) {
                    $ids_ch_b1 = [sort {$json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$b}->pcid <=> $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$a}->pcid} keys %{$site->{$type_ch}->{$type_chem}->{$id_seq_b1}}];

                    # get all contact hits for each interactor
                    push @{$ids_ch}, @{$ids_ch_b1};
                }

                if(@{$ids_ch} > 0) {
                    $ids_ch = [sort {$json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$b}->pcid <=> $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$a}->pcid} @{$ids_ch}]; # FIXME - refactor: extract function
                    $ppis = [];
                    foreach $id_ch (@{$ids_ch}) {
                        ++${$id_row};
                        $ch = $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch};
                        $id_seq_b1 = $ch->id_seq_b1;

                        $ppi_table->add_row(${$id_row});
                        $ppi_table->element(${$id_row}, 'id_ch',         $id_ch);
                        $ppi_table->element(${$id_row}, 'id_seq_a1',     $id_seq_a1);
                        $ppi_table->element(${$id_row}, 'name_a1',       $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{name});
                        $ppi_table->element(${$id_row}, 'primary_id_a1', $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{primary_id});
                        $ppi_table->element(${$id_row}, 'pos_a1',        $pos_a1);
                        $ppi_table->element(${$id_row}, 'site',          $site->{label});
                        $ppi_table->element(${$id_row}, 'start_a1',      $ch->start_a1);
                        $ppi_table->element(${$id_row}, 'end_a1',        $ch->end_a1);
                        $ppi_table->element(${$id_row}, 'id_seq_b1',     $id_seq_b1);
                        $ppi_table->element(${$id_row}, 'name_b1',       $json->{results}->{$results_type}->{seqs}->{$id_seq_b1}->{name});
                        $ppi_table->element(${$id_row}, 'primary_id_b1', $json->{results}->{$results_type}->{seqs}->{$id_seq_b1}->{primary_id});
                        $ppi_table->element(${$id_row}, 'start_b1',      $ch->start_b1);
                        $ppi_table->element(${$id_row}, 'end_b1',        $ch->end_b1);
                        $ppi_table->element(${$id_row}, 'intev',         _intev($json, $ch->pcid, $id_seq_a1, $id_seq_b1));
                        $ppi_table->element(${$id_row}, 'idcode',        $ch->contact->frag_inst1->frag->idcode);
                        $ppi_table->element(${$id_row}, 'pdb_desc',      $json->{temporary}->{pdbs}->{$ch->contact->frag_inst1->frag->idcode}); # inefficient but easier to put this in every row that needs it
                        $ppi_table->element(${$id_row}, 'homo',          $ch->contact->homo);
                        $ppi_table->element(${$id_row}, 'pcid',          $ch->pcid);
                        $ppi_table->element(${$id_row}, 'e_value',       $ch->e_value);
                        $ppi_table->element(${$id_row}, 'conf',          $ch->conf);
                        $ppi_table->element(${$id_row}, 'ie',            $site->{$type_ch}->{$type_chem}->{$id_seq_b1}->{$id_ch}->{ie});
                        $ppi_table->element(${$id_row}, 'ie_class',      $site->{$type_ch}->{$type_chem}->{$id_seq_b1}->{$id_ch}->{ie_class});
                        $ppi_table->element(${$id_row}, 'sswitch',       $site->{$type_ch}->{$type_chem}->{$id_seq_b1}->{$id_ch}->{sswitch}); # currently only relevant for phosphosites
                    }
                }
            }
        }
    }

    foreach $type_chem (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}}) {
        foreach $id_seq_b1 (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}}) {
            foreach $id_ch (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}->{$id_seq_b1}}) {
                $ch = $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch};
                $n_posns = $site_info->{ch_to_interface_sites}->{$id_ch};
                $n_posns = defined($n_posns) ? scalar keys %{$n_posns} : 0;
                if($n_posns == 0) {
                    ++${$id_row};

                    $ppi_table->add_row(${$id_row});
                    $ppi_table->element(${$id_row}, 'id_ch',         $id_ch);
                    $ppi_table->element(${$id_row}, 'id_seq_a1',     $id_seq_a1);
                    $ppi_table->element(${$id_row}, 'name_a1',       $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{name});
                    $ppi_table->element(${$id_row}, 'primary_id_a1', $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{primary_id});
                    $ppi_table->element(${$id_row}, 'site',          '(none)');
                    $ppi_table->element(${$id_row}, 'start_a1',      $ch->start_a1);
                    $ppi_table->element(${$id_row}, 'end_a1',        $ch->end_a1);
                    $ppi_table->element(${$id_row}, 'id_seq_b1',     $id_seq_b1);
                    $ppi_table->element(${$id_row}, 'name_b1',       $json->{results}->{$results_type}->{seqs}->{$id_seq_b1}->{name});
                    $ppi_table->element(${$id_row}, 'primary_id_b1', $json->{results}->{$results_type}->{seqs}->{$id_seq_b1}->{primary_id});
                    $ppi_table->element(${$id_row}, 'start_b1',      $ch->start_b1);
                    $ppi_table->element(${$id_row}, 'end_b1',        $ch->end_b1);
                    $ppi_table->element(${$id_row}, 'intev',         _intev($json, $ch->{pcid}, $id_seq_a1, $id_seq_b1));
                    $ppi_table->element(${$id_row}, 'idcode',        $ch->idcode);
                    $ppi_table->element(${$id_row}, 'pdb_desc',      $json->{temporary}->{pdbs}->{$ch->idcode}); # inefficient but easier to put this in every row that needs it
                    $ppi_table->element(${$id_row}, 'homo',          $ch->contact->homo);
                    $ppi_table->element(${$id_row}, 'pcid',          $ch->pcid);
                    $ppi_table->element(${$id_row}, 'e_value',       $ch->e_value);
                    $ppi_table->element(${$id_row}, 'conf',          $ch->conf);
                }
            }
        }
    }
}

sub _intev {
    my($json, $pcid, $id_seq_a1, $id_seq_b1) = @_;

    my $intev;
    my $string;

    $intev = [];
    if(defined($json->{temporary}->{known_ints}->{$id_seq_a1}->{$id_seq_b1})) {
        foreach $string (@{$json->{temporary}->{known_ints}->{$id_seq_a1}->{$id_seq_b1}}) {
            push @{$intev}, {method => 'string', idString1 => $string->[0], idString2 => $string->[1], score => $string->[2]};
        }
    }

    if($pcid > $json->{params}->{processed}->{min_pcid_known}) {
        unshift @{$intev}, {method => 'structure'};
    }
    elsif(@{$intev} == 0) {
        push @{$intev}, {method => 'inferred'};
    }

    return $intev;
}

sub _intev_v01 {
    my($json, $pcid, $id_seq_a1, $id_seq_b1) = @_;

    my $intev;
    my $pmids;
    my $pmid;
    my $id_seq_a2;
    my $id_seq_b2;

    $intev = [];
    $pmids = {};
    if(defined($json->{temporary}->{known_ints_by_uniref}->{$id_seq_a1}->{peptide}->{$id_seq_b1})) {
        foreach $id_seq_a2 (keys %{$json->{temporary}->{known_ints_by_uniref}->{$id_seq_a1}->{peptide}->{$id_seq_b1}}) {
            foreach $id_seq_b2 (keys %{$json->{temporary}->{known_ints_by_uniref}->{$id_seq_a1}->{peptide}->{$id_seq_b1}->{$id_seq_a2}}) {
                foreach $pmid (keys %{$json->{temporary}->{known_ints}->{$id_seq_a2}->{$id_seq_b2}}) {
                    defined($pmids->{$pmid}) and next;
                    $pmids->{$pmid}++;
                    push @{$intev}, {
                                     pmid    => $pmid,
                                     n_seqs  => $json->{temporary}->{known_ints}->{$id_seq_a2}->{$id_seq_b2}->{$pmid}->[0],
                                     htp     => $json->{temporary}->{known_ints}->{$id_seq_a2}->{$id_seq_b2}->{$pmid}->[1],
                                     hq      => $json->{temporary}->{known_ints}->{$id_seq_a2}->{$id_seq_b2}->{$pmid}->[2],
                                     dp      => $json->{temporary}->{known_ints}->{$id_seq_a2}->{$id_seq_b2}->{$pmid}->[3],
                                     sources => [sort keys %{$json->{temporary}->{known_ints}->{$id_seq_a2}->{$id_seq_b2}->{$pmid}->[4]}],
                                     methods => [sort keys %{$json->{temporary}->{known_ints}->{$id_seq_a2}->{$id_seq_b2}->{$pmid}->[5]}],
                                     method  => '', # FIXME - set this from 'methods'
                                    };
                }
            }
        }
    }
    if($pcid > $json->{params}->{processed}->{min_pcid_known}) {
        unshift @{$intev}, {pmid => 0, method => 'structure'};
    }
    elsif(@{$intev} == 0) {
        push @{$intev}, {pmid => 0, method => 'inferred'};
    }

    return $intev;
}

=head2 pci_table

 usage   :
 function: get table of protein-chemical interactions
 args    :
 returns :

=cut

sub pci_table {
    my($self, $json, $pci_table, $id_row, $results_type, $site_info) = @_;

    my $type_ch = 'PCInqm';
    my $seq_a1;
    my $id_seq_a1;
    my $pos_a1;
    my $site;
    my $type_chem;
    my $ids_ch;
    my $id_ch;
    my $ch;
    my $ids_ch_b1;
    my $id_seq_b1;
    my $ppis;
    my $intev;
    my $n_posns;

    $seq_a1 = $self;
    $id_seq_a1 = $seq_a1->id;
    foreach $pos_a1 (keys %{$site_info->{sites}}) {
        foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
            foreach $type_chem (keys %{$site->{$type_ch}}) {
                $ids_ch = [];
                foreach $id_seq_b1 (keys %{$site->{$type_ch}->{$type_chem}}) {
                    $ids_ch_b1 = [sort {$json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$b}->pcid <=> $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$a}->pcid} keys %{$site->{$type_ch}->{$type_chem}->{$id_seq_b1}}];

                    # get all contact hits for each interactor
                    push @{$ids_ch}, @{$ids_ch_b1};
                }

                if(@{$ids_ch} > 0) {
                    $ids_ch = [sort {$json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$b}->pcid <=> $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$a}->pcid} @{$ids_ch}]; # FIXME - refactor: extract function
                    $ppis = [];
                    foreach $id_ch (@{$ids_ch}) {
                        ++${$id_row};
                        $ch = $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch};
                        $id_seq_b1 = $ch->id_seq_b1;

                        # common to all interaction types
                        $pci_table->add_row(${$id_row});
                        $pci_table->element(${$id_row}, 'id_fh',         $id_ch); # FIXME - should be a contact hit not a fragment hit
                        $pci_table->element(${$id_row}, 'id_seq_a1',     $id_seq_a1);
                        $pci_table->element(${$id_row}, 'name_a1',       $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{name});
                        $pci_table->element(${$id_row}, 'primary_id_a1', $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{primary_id});
                        $pci_table->element(${$id_row}, 'pos_a1',        $pos_a1);
                        $pci_table->element(${$id_row}, 'site',          $site->{label});
                        $pci_table->element(${$id_row}, 'start_a1',      $ch->start_a1);
                        $pci_table->element(${$id_row}, 'end_a1',        $ch->end_a1);
                        $pci_table->element(${$id_row}, 'idcode',        $ch->contact->frag_inst1->frag->idcode);
                        $pci_table->element(${$id_row}, 'pdb_desc',      $json->{temporary}->{pdbs}->{$ch->contact->frag_inst1->frag->idcode}); # inefficient but easier to put this in every row that needs it
                        $pci_table->element(${$id_row}, 'pcid',          $ch->pcid);
                        $pci_table->element(${$id_row}, 'e_value',       $ch->e_value);
                        $pci_table->element(${$id_row}, 'conf',          $ch->conf);
                        $pci_table->element(${$id_row}, 'ie',            $site->{$type_ch}->{$type_chem}->{$id_seq_b1}->{$id_ch}->{ie});
                        $pci_table->element(${$id_row}, 'ie_class',      $site->{$type_ch}->{$type_chem}->{$id_seq_b1}->{$id_ch}->{ie_class});

                        # unique to PCIs
                        $pci_table->element(${$id_row}, 'id_seq_a2',     $ch->id_seq_a2);
                        $pci_table->element(${$id_row}, 'start_a2',      $ch->start_a2);
                        $pci_table->element(${$id_row}, 'end_a2',        $ch->end_a2);
                        $pci_table->element(${$id_row}, 'type_chem',     $type_chem);
                        $pci_table->element(${$id_row}, 'id_chem',       $id_seq_b1);
                    }
                }
            }
        }
    }

    # interactions with no sites
    foreach $type_chem (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}}) {
        foreach $id_seq_b1 (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}}) {
            foreach $id_ch (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}->{$id_seq_b1}}) {
                $ch = $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch};
                $n_posns = $site_info->{ch_to_interface_sites}->{$id_ch};
                $n_posns = defined($n_posns) ? scalar keys %{$n_posns} : 0;
                if($n_posns == 0) {
                    ++${$id_row};

                    # common to all interaction types
                    $pci_table->add_row(${$id_row});
                    $pci_table->element(${$id_row}, 'id_fh',         $id_ch); # FIXME - contact hit not fragment hit
                    $pci_table->element(${$id_row}, 'id_seq_a1',     $id_seq_a1);
                    $pci_table->element(${$id_row}, 'name_a1',       $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{name});
                    $pci_table->element(${$id_row}, 'primary_id_a1', $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{primary_id});
                    $pci_table->element(${$id_row}, 'site',          '(none)');
                    $pci_table->element(${$id_row}, 'start_a1',      $ch->start_a1);
                    $pci_table->element(${$id_row}, 'end_a1',        $ch->end_a1);
                    $pci_table->element(${$id_row}, 'idcode',        $ch->idcode);
                    $pci_table->element(${$id_row}, 'pdb_desc',      $json->{temporary}->{pdbs}->{$ch->idcode}); # inefficient but easier to put this in every row that needs it
                    $pci_table->element(${$id_row}, 'pcid',          $ch->pcid);
                    $pci_table->element(${$id_row}, 'e_value',       $ch->e_value);
                    $pci_table->element(${$id_row}, 'conf',          $ch->conf);

                    # unique to PCIs
                    $pci_table->element(${$id_row}, 'id_seq_a2',     $ch->id_seq_a2); # FIXME - should a2 info be in other int tables too?
                    $pci_table->element(${$id_row}, 'start_a2',      $ch->start_a2);
                    $pci_table->element(${$id_row}, 'end_a2',        $ch->end_a2);
                    $pci_table->element(${$id_row}, 'type_chem',     $type_chem);
                    $pci_table->element(${$id_row}, 'id_chem',       $id_seq_b1);
                }
            }
        }
    }
}

=head2 pdi_table

 usage   :
 function: get table of protein-DNA/RNA interactions
 args    :
 returns :

=cut

sub pdi_table {
    my($self, $json, $pdi_table, $id_row, $results_type, $site_info) = @_;

    my $type_ch = 'PDInqm';
    my $seq_a1;
    my $id_seq_a1;
    my $pos_a1;
    my $site;
    my $type_chem;
    my $ids_ch;
    my $id_ch;
    my $ch;
    my $ids_ch_b1;
    my $id_seq_b1;
    my $ppis;
    my $intev;
    my $n_posns;

    $seq_a1 = $self;
    $id_seq_a1 = $seq_a1->id;
    foreach $pos_a1 (keys %{$site_info->{sites}}) {
        foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
            foreach $type_chem (keys %{$site->{$type_ch}}) {
                $ids_ch = [];
                foreach $id_seq_b1 (keys %{$site->{$type_ch}->{$type_chem}}) {
                    $ids_ch_b1 = [sort {$json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$b}->pcid <=> $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$a}->pcid} keys %{$site->{$type_ch}->{$type_chem}->{$id_seq_b1}}];

                    # get all contact hits for each interactor
                    push @{$ids_ch}, @{$ids_ch_b1};
                }

                if(@{$ids_ch} > 0) {
                    $ids_ch = [sort {$json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$b}->pcid <=> $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$a}->pcid} @{$ids_ch}]; # FIXME - refactor: extract function
                    $ppis = [];
                    foreach $id_ch (@{$ids_ch}) {
                        ++${$id_row};
                        $ch = $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch};
                        $id_seq_b1 = $ch->id_seq_b1;

                        # common to all interaction types
                        $pdi_table->add_row(${$id_row});
                        $pdi_table->element(${$id_row}, 'id_fh',         $id_ch); # FIXME - should be a contact hit not a fragment hit
                        $pdi_table->element(${$id_row}, 'id_seq_a1',     $id_seq_a1);
                        $pdi_table->element(${$id_row}, 'name_a1',       $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{name});
                        $pdi_table->element(${$id_row}, 'primary_id_a1', $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{primary_id});
                        $pdi_table->element(${$id_row}, 'pos_a1',        $pos_a1);
                        $pdi_table->element(${$id_row}, 'site',          $site->{label});
                        $pdi_table->element(${$id_row}, 'start_a1',      $ch->start_a1);
                        $pdi_table->element(${$id_row}, 'end_a1',        $ch->end_a1);
                        $pdi_table->element(${$id_row}, 'idcode',        $ch->contact->frag_inst1->frag->idcode);
                        $pdi_table->element(${$id_row}, 'pdb_desc',      $json->{temporary}->{pdbs}->{$ch->contact->frag_inst1->frag->idcode}); # inefficient but easier to put this in every row that needs it
                        $pdi_table->element(${$id_row}, 'pcid',          $ch->pcid);
                        $pdi_table->element(${$id_row}, 'e_value',       $ch->e_value);
                        $pdi_table->element(${$id_row}, 'conf',          $ch->conf);
                        $pdi_table->element(${$id_row}, 'ie',            $site->{$type_ch}->{$type_chem}->{$id_seq_b1}->{$id_ch}->{ie});
                        $pdi_table->element(${$id_row}, 'ie_class',      $site->{$type_ch}->{$type_chem}->{$id_seq_b1}->{$id_ch}->{ie_class});

                        # unique to PCIs and PDIs
                        $pdi_table->element(${$id_row}, 'id_seq_a2',     $ch->id_seq_a2);
                        $pdi_table->element(${$id_row}, 'start_a2',      $ch->start_a2);
                        $pdi_table->element(${$id_row}, 'end_a2',        $ch->end_a2);
                        $pdi_table->element(${$id_row}, 'type_chem',     $type_chem);
                        $pdi_table->element(${$id_row}, 'id_chem',       $id_seq_b1);
                    }
                }
            }
        }
    }

    # interactions with no sites
    foreach $type_chem (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}}) {
        foreach $id_seq_b1 (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}}) {
            foreach $id_ch (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}->{$id_seq_b1}}) {
                $ch = $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch};
                $n_posns = $site_info->{ch_to_interface_sites}->{$id_ch};
                $n_posns = defined($n_posns) ? scalar keys %{$n_posns} : 0;
                if($n_posns == 0) {
                    ++${$id_row};

                    # common to all interaction types
                    $pdi_table->add_row(${$id_row});
                    $pdi_table->element(${$id_row}, 'id_fh',         $id_ch); # FIXME - contact hit not fragment hit
                    $pdi_table->element(${$id_row}, 'id_seq_a1',     $id_seq_a1);
                    $pdi_table->element(${$id_row}, 'name_a1',       $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{name});
                    $pdi_table->element(${$id_row}, 'primary_id_a1', $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{primary_id});
                    $pdi_table->element(${$id_row}, 'site',          '(none)');
                    $pdi_table->element(${$id_row}, 'start_a1',      $ch->start_a1);
                    $pdi_table->element(${$id_row}, 'end_a1',        $ch->end_a1);
                    $pdi_table->element(${$id_row}, 'idcode',        $ch->idcode);
                    $pdi_table->element(${$id_row}, 'pdb_desc',      $json->{temporary}->{pdbs}->{$ch->idcode}); # inefficient but easier to put this in every row that needs it
                    $pdi_table->element(${$id_row}, 'pcid',          $ch->pcid);
                    $pdi_table->element(${$id_row}, 'e_value',       $ch->e_value);
                    $pdi_table->element(${$id_row}, 'conf',          $ch->conf);

                    # unique to PCIs
                    $pdi_table->element(${$id_row}, 'id_seq_a2',     $ch->id_seq_a2); # FIXME - should a2 info be in other int tables too?
                    $pdi_table->element(${$id_row}, 'start_a2',      $ch->start_a2);
                    $pdi_table->element(${$id_row}, 'end_a2',        $ch->end_a2);
                    $pdi_table->element(${$id_row}, 'type_chem',     $type_chem);
                    $pdi_table->element(${$id_row}, 'id_chem',       $id_seq_b1);
                }
            }
        }
    }
}

=head2 struct_table

 usage   :
 function: get table of structures, whether or not they involve interactions
 args    :
 returns :

=cut

sub struct_table {
    my($self, $json, $struct_table, $id_row, $results_type, $site_info) = @_;

    my $seq_a1;
    my $id_seq_a1;
    my $pos_a1;
    my $site;
    my $id_hsp;
    my $hsp;

    $seq_a1 = $self;
    $id_seq_a1 = $seq_a1->id;
    foreach $pos_a1 (keys %{$site_info->{sites}}) {
        foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
            foreach $id_hsp (sort {$a <=> $b} keys %{$site->{struct}}) {
                ++${$id_row};

                $hsp = $json->{temporary}->{hsps}->{$id_hsp};

                $struct_table->add_row(${$id_row});
                $struct_table->element(${$id_row}, 'id_hsp',        $id_hsp);
                $struct_table->element(${$id_row}, 'id_seq_a1',     $id_seq_a1);
                $struct_table->element(${$id_row}, 'name_a1',       $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{name});
                $struct_table->element(${$id_row}, 'primary_id_a1', $json->{results}->{$results_type}->{seqs}->{$id_seq_a1}->{primary_id});
                $struct_table->element(${$id_row}, 'pos_a1',        $pos_a1);
                $struct_table->element(${$id_row}, 'site',          $site->{label});

                $struct_table->element(${$id_row}, 'start_a1',      $hsp->start1);
                $struct_table->element(${$id_row}, 'end_a1',        $hsp->end1);
                $struct_table->element(${$id_row}, 'id_seq_a2',     $hsp->id_seq2);
                $struct_table->element(${$id_row}, 'start_a2',      $hsp->start2);
                $struct_table->element(${$id_row}, 'end_a2',        $hsp->end2);
                $struct_table->element(${$id_row}, 'idcode',        $site->{struct}->{$id_hsp}->{idcode});
                $struct_table->element(${$id_row}, 'pdb_desc',      $json->{temporary}->{pdbs}->{$site->{struct}->{$id_hsp}->{idcode}}); # inefficient but easier to put this in every row that needs it
                $struct_table->element(${$id_row}, 'pcid',          $hsp->pcid);
                $struct_table->element(${$id_row}, 'e_value',       $hsp->e_value);
            }
        }
    }
}

=head2 d3_network

 usage   :
 function: generate a network in d3 format
 args    :
 returns :

=cut

sub d3_network {
    my($self, $json, $networks, $results_type, $network_site_counts, $site_info) = @_;

    my $id_search;
    my $search_root;
    my $network;
    my $seq_a1;
    my $id_seq_a1;
    my $seq_a1_json;
    my $name_a1;
    my $status_a1;
    my $nodes_a1;
    my $node_a1;
    my $id_seq_b1;
    my $name_b1;
    my $status_b1;
    my $seq_b1;
    my $nodes_b1;
    my $node_b1;
    my $posns;
    my $ies;
    my $id_ch;
    my $pos_a1;
    my $site;
    my $edge;
    my $type_ch;
    my $type_chem;
    my $id_chem;
    my $id_fh;
    my $type;
    my $key;
    my $id_node_a1;
    my $id_node_b1;
    my $id_edge;
    my $i;
    my $n_sites;

    $id_search = $json->{params}->{given}->{id_search};
    $search_root = defined($id_search) ? "/search/id/$id_search/" : '';

    $seq_a1 = $self;
    $id_seq_a1 = $seq_a1->id;

    $name_a1 = $json->{results}->{search}->{seqs}->{$id_seq_a1}->{name};
    $status_a1 = $json->{results}->{search}->{seqs}->{$id_seq_a1}->{status};
    $nodes_a1 = [];
    foreach $network (@{$networks}) {
        $node_a1 = $network->add_node($id_seq_a1, $name_a1, $status_a1);
        push @{$nodes_a1}, $node_a1;
        # NOTE: n_sites_on, _out and _in set later for query proteins - see Fist::NonDB::Seqs->_finalise_results
    }

    foreach $type_ch (qw(PPI PCInqm PDInqm)) { # FIXME - merge this with prot_and_site_tables somehow?
        if(defined($json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1})) {
            foreach $type_chem (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}}) {
                foreach $id_chem (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}}) {
                    ($id_node_b1, $name_b1, $status_b1) = _node_name($json, $results_type, $type_ch, $type_chem, $id_chem);

                    $posns = {};
                    $ies = [];
                    foreach $id_ch (keys %{$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}->{$id_chem}}) {
                        if(defined($site_info->{ch_to_interface_sites}->{$id_ch})) {
                            foreach $pos_a1 (keys %{$site_info->{ch_to_interface_sites}->{$id_ch}}) {
                                $posns->{$pos_a1}++;
                                foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
                                    push @{$ies}, {ie => $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie}, ie_class => $site->{$type_ch}->{$type_chem}->{$id_chem}->{$id_ch}->{ie_class}};
                                }
                            }
                        }
                    }
                    $posns = [sort {$a <=> $b} keys %{$posns}];

                    $n_sites = {};
                    foreach $pos_a1 (@{$posns}) {
                        if(defined($site_info->{sites}->{$pos_a1}->{sites})) {
                            foreach $site (@{$site_info->{sites}->{$pos_a1}->{sites}}) {
                                $n_sites->{$site->{id}}++;
                                $network_site_counts->{$id_seq_a1}->{out}->{$site->{id}}++;
                                $network_site_counts->{$id_node_b1}->{in}->{$site->{id}}++;
                            }
                        }
                    }
                    $n_sites = scalar keys %{$n_sites};

                    $nodes_b1 = [];
                    foreach $network (@{$networks}) {
                        $node_b1 = $network->add_node($id_node_b1, $name_b1, $status_b1);
                        push @{$nodes_b1}, $node_b1;
                    }
                    for($i = 0; $i < @{$networks}; $i++) {
                        $network = $networks->[$i];
                        $edge = $network->add_edge($nodes_a1->[$i], $nodes_b1->[$i], $n_sites, [@{$ies}]); # a new copy of ies each time
                    }
                }
            }
        }
    }
}

sub _node_name {
    my($json, $results_type, $type_ch, $type_chem, $id_chem) = @_;

    my $id;
    my $name;
    my $status;

    if($type_ch eq 'PPI') {
        $id = $id_chem;
        $name = $json->{results}->{$results_type}->{seqs}->{$id_chem}->{name};
        $status = defined($json->{results}->{search}->{query_seqs}->{$id_chem}) ? 'query' : 'friend';
    }
    elsif($type_ch =~ /\APPI/) {
        $id = 'peptide';
        $name = 'peptide';
        $status = 'peptide';
    }
    elsif($type_ch =~ /\APCI/) {
        $id = $type_chem;
        $name = $type_chem;
        $status = 'chemical';
    }
    elsif($type_ch =~ /\APDI/) {
        $id = $type_chem;
        $name = $type_chem;
        $status = 'nucleic';
    }
    else {
        $id = 'UNK';
        $name = 'UNK';
        $status = 'UNK';
    }

    return($id, $name, $status);
}


=head2 various internal functions for saving things to the json hash

 usage   :
 function:
 args    :
 returns :

=cut

sub _json_add_pci {
    my($json, $key, $id_seq_a1, $type_chem, $id_chem, $id_fh, $conf) = @_;

    $json->{temporary}->{$key}->{$id_seq_a1}->{$type_chem}->{$id_chem}->{$id_fh} = $conf;
}

sub _json_add_contact_hit {
    my($json, $idcode, $pdbTitle, $id_seq_a1, $type_chem, $id_seq_b1, $id_ch, $ch, $mat_conf, $results_type) = @_;

    my $type_ch;

    $type_ch = $ch->type;

    #print join("\t", 'ADD', $id_seq_a1, $id_ch, $type_ch, $type_chem, $id_seq_b1), "\n";

    $json->{results}->{$results_type}->{counts}->{contact_hits}->{$type_ch}->{$id_ch}++;
    if(!$json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}->{$id_seq_b1}->{$id_ch}) {
        if($type_ch =~ /^PPI/) {
            $ch->conf($mat_conf->confidence('PP', $ch->pcid));
        }
        elsif($type_ch =~ /^PCI/) {
            $ch->conf($mat_conf->confidence('CH', $ch->pcid));
        }
        elsif($type_ch =~ /^PDI/) {
            $ch->conf($mat_conf->confidence('NU', $ch->pcid));
        }

        $json->{temporary}->{contact_hits}->{by_id}->{$type_ch}->{$id_ch} = $ch;
        $json->{temporary}->{contact_hits}->{by_seq}->{$type_ch}->{$id_seq_a1}->{$type_chem}->{$id_seq_b1}->{$id_ch}++;
        _json_add_pdb($json, $idcode, $pdbTitle, $results_type);
    }
}

sub json_add_seq {
    my($json, $id_seq, $name, $primary_id, $desc, $status, $results_type) = @_;

    if(!defined($json->{results}->{$results_type}->{seqs}->{$id_seq})) {
        $json->{results}->{$results_type}->{seqs}->{$id_seq} = {
                                                                name       => $name,
                                                                primary_id => $primary_id,
                                                                desc       => $desc,
                                                                status     => $status,
                                                               };
    }

    if($status eq 'query') {
        # might have been found earlier as a friend
        $json->{results}->{$results_type}->{seqs}->{$id_seq}->{status} = $status;
        $json->{results}->{$results_type}->{query_seqs}->{$id_seq}++;
    }
}

sub _json_add_pdb {
    my($json, $idcode, $pdbTitle, $results_type) = @_;

    defined($results_type) or Carp::cluck('$results_type undefined');
    if(!defined($json->{temporary}->{pdbs}->{$idcode})) {
        $json->{temporary}->{pdbs}->{$idcode} = $pdbTitle;
        $json->{results}->{$results_type}->{counts}->{pdbs}->{$idcode}++;
    }

    return 1;
}

sub _json_add_frag {
    my($json, $frag, $id_seq, $results_type, $dbh) = @_;

    my $id_frag;
    my $idcode;
    my $pdbTitle;

    $id_frag = $frag->id;

    if(!defined($json->{temporary}->{frags}->{$id_frag})) {
        $json->{temporary}->{frags}->{$id_frag} = $frag;
        ($idcode, $pdbTitle) = _get_frag_pdb($dbh, $id_frag);
        _json_add_pdb($json, $idcode, $pdbTitle, $results_type);
    }
    $json->{temporary}->{seq_to_frag}->{id_seq} = $id_frag;

    return 1;
}

sub _get_frag_pdb {
    my($dbh, $id) = @_;

    my $query;
    my $sth;
    my $table;
    my $idcode;
    my $title;

    $query = <<END;
SELECT pdb.idcode,
       pdb.title
FROM   Frag AS f,
       Pdb  AS pdb
WHERE  f.id = ?
AND    pdb.idcode = f.idcode
END
    $sth = $dbh->prepare($query);
    $sth->execute($id);
    $table = $sth->fetchall_arrayref;
    ($idcode, $title) = @{$table->[0]};

    return($idcode, $title);
}

sub _json_add_hsp {
    my($json, $hsp) = @_;

    $json->{temporary}->{hsps}->{$hsp->id} = $hsp;
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
             primary_id    => $self->primary_id,
             name          => $self->name,
             seq           => $self->seq,
             len           => $self->len,
             chemical_type => $self->chemical_type,
             source        => $self->source,
             description   => $self->description,
             ids_taxa      => $self->ids_taxa,
             url_in_source => $self->url_in_source,
            };

    return $json;
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
               defined($self->primary_id) ? $self->primary_id : '',
               defined($self->name) ? $self->name : '',
               $self->seq,
               $self->len,
               $self->chemical_type,
               $self->source,
               defined($self->description) ? $self->description : '',
              ),
          "\n",
         );
}

=head2 output_fasta

 usage   : $self->output_fasta(\*STDOUT, 'use_primary_id')
 function: output the sequence in fasta format
 args    : a file handle and a flag to request primary_id to be output instead of id
 returns : 1 for success, 0 for error

=cut

sub output_fasta {
    my($self, $fh, $use_primary_id) = @_;

    my $seq;
    my $id;
    my $desc;
    my $taxa;
    my $taxon;

    $id = defined($use_primary_id) ? $self->primary_id : $self->id;

    $taxa = {};
    foreach $taxon ($self->taxa) {
        $taxa->{$taxon->id}++;
    }
    $taxa = join ',', sort {$a cmp $b} keys %{$taxa};

    $desc = sprintf(
                    "fist_id=%d, source='%s', taxon='%s', primary_id='%s', name='%s', desc='%s'",
                    $self->id,
                    defined($self->source) ? $self->source : '',
                    $taxa,
                    defined($self->primary_id) ? $self->primary_id : '',
                    defined($self->name) ? $self->name : '',
                    defined($self->description) ? $self->description : '',
                   );

    print $fh ">$id $desc\n";

    $seq = $self->seq;
    while($seq =~ /(\S{1,60})/g) {
        print $fh $1, "\n";
    }

    return 1;
}

1;
