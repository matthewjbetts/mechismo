package Fist::Interface::Alignment;

use Moose::Role;
use CHI;

=head1 NAME

 Fist::Interface::Alignment

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

=head2 method

 usage   :
 function:
 args    :
 returns :

=cut

requires 'method';

=head2 len

 usage   :
 function:
 args    :
 returns :

=cut

requires 'len';

=head2 aligned_seqs

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aligned_seqs';

=head2 aseq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aseq';

=head2 aseqs

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aseqs';

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';
 with 'Fist::Utils::Cache';

=cut

with 'Fist::Utils::UniqueIdentifier';
with 'Fist::Utils::Cache';

=head1 METHODS

=cut

requires 'add_to_aligned_seqs';

=head2 TO_JSON

 usage   :
 function:
 args    :
 returns :

=cut

sub TO_JSON {
    my($self) = @_;

    my $key;
    my $json;
    my $aseqs;
    my $aseq;

    $json = {
             id          => $self->id,
             method      => $self->method,
             len         => $self->len,
             aseqs       => {},
             id_line     => $self->id_line,
             pos_to_apos => $self->pos_to_apos,
             apos_to_pos => $self->apos_to_pos,
            };

    $aseqs = $self->aseqs;
    foreach $aseq (values %{$aseqs}) {
        $json->{aseqs}->{$aseq->id_seq} = $aseq->TO_JSON;
    }

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

    print $fh join("\t", $self->id, $self->method, $self->len), "\n";
}

=head2 output_fasta

 usage   :
 function:
 args    :
 returns :

=cut

sub output_fasta {
    my($self, $fh) = @_;

    my $aseq;
    my $str;

    foreach $aseq ($self->aligned_seqs) {
        print $fh '>', $aseq->id_seq, ' ', $aseq->start, '..', $aseq->end, "\n";
        $str = $aseq->aseq;
        while($str =~ /(\S{1,60})/g) {
            print $fh "$1\n";
        }
    }
}

=head2 pos_to_apos

 usage   :
 function:
 args    :
 returns :

=cut

has '_pos_to_apos' => (is => 'rw', isa => 'HashRef[Any]', default => sub {return {}});

sub pos_to_apos {
    my($self) = @_;

    defined($self->_pos_to_apos) or $self->calc_mapping();

    return $self->_pos_to_apos;
}

=head2 apos_from_pos

 usage   :
 function:
 args    :
 returns :

=cut

sub apos_from_pos {
    my($self, $id_seq, $pos) = @_;

    if($pos !~ /\A\d+\Z/) {
        Carp::cluck("position '$pos' is not an unsigned integer");
        return undef;
    }

    (defined($self->_pos_to_apos) and defined($self->_pos_to_apos->{$id_seq})) or $self->calc_mapping();

    return $self->_pos_to_apos->{$id_seq}->[$pos];
}

=head2 apos_to_pos

 usage   :
 function:
 args    :
 returns :

=cut

has '_apos_to_pos' => (is => 'rw', isa => 'HashRef[Any]', default => sub {return {}});

sub apos_to_pos {
    my($self) = @_;

    defined($self->_apos_to_pos) or $self->calc_mapping();

    return $self->_apos_to_pos;
}

=head2 pos_from_apos

 usage   :
 function:
 args    :
 returns :

=cut

sub pos_from_apos {
    my($self, $id_seq, $apos) = @_;

    if($apos !~ /\A\d+\Z/) {
        Carp::cluck("position '$apos' is not an unsigned integer");
        return undef;
    }

    (defined($self->_apos_to_pos) and defined($self->_apos_to_pos->{$id_seq})) or $self->calc_mapping();

    return $self->_apos_to_pos->{$id_seq}->[$apos];
}

# had previously split calc_mapping in two to save memory when mapping
# is only needed in one direction, but this doubled the time required...

=head2 calc_mapping

 usage   :
 function:
 args    :
 returns :

=cut

sub calc_mapping {
    my($self) = @_;

    my $cache_key;
    my $mapping;
    my $pos_to_apos;
    my $apos_to_pos;
    my $id_aln;
    my $aseq;
    my $apos_start;
    my $apos_end;
    my $pos_start;
    my $pos_end;
    my $edit;

    my $aas;
    my $aas_sub;
    my $len_sub;

    # FIXME - could do this on demand for each AlignedSeq

    $cache_key = $self->cache_key('mapping');
    if(defined($mapping = $self->cache->get($cache_key))) {
        ($pos_to_apos, $apos_to_pos) = @{$mapping};
    }
    else {
        $id_aln = $self->id;

        #print join("\t", __PACKAGE__, 'mapping', $id_aln), "\n";

        $pos_to_apos = {};
        $apos_to_pos = {};
        foreach $aseq ($self->aligned_seqs) {
            $pos_to_apos->{$aseq->id_seq} = [];
            $apos_to_pos->{$aseq->id_seq} = [];
            $apos_start = 0;
            $apos_end = 0;
            $pos_start = 0;
            $pos_end = $aseq->start - 1;
            foreach $edit (@{$aseq->edits}) {
                #print "EDIT: '$edit'\n";
                $apos_start = $apos_end + 1;
                $apos_end += abs($edit);
                if($edit > 0) {
                    $pos_start = $pos_end + 1;
                    $pos_end += $edit;
                    @{$pos_to_apos->{$aseq->id_seq}}[$pos_start..$pos_end] = ($apos_start..$apos_end);
                    @{$apos_to_pos->{$aseq->id_seq}}[$apos_start..$apos_end] = ($pos_start..$pos_end);
                }
            }
        }
        $mapping = [$pos_to_apos, $apos_to_pos];
        $self->cache->set($cache_key, $mapping);
    }
    $self->_pos_to_apos($pos_to_apos);
    $self->_apos_to_pos($apos_to_pos);

    return 1;
}

sub calc_mapping_v01 {
    my($self) = @_;

    my $pos_to_apos_cache_key;
    my $apos_to_pos_cache_key;
    my $pos_to_apos;
    my $apos_to_pos;
    my $id_aln;
    my $aseq;
    my $aas;
    my $aas_sub;
    my $len_sub;
    my $apos_start;
    my $apos_end;
    my $pos_start;
    my $pos_end;

    $pos_to_apos_cache_key = $self->cache_key('pos_to_apos');
    $pos_to_apos = $self->cache->get($pos_to_apos_cache_key);

    $apos_to_pos_cache_key = $self->cache_key('apos_to_pos');
    $apos_to_pos = $self->cache->get($apos_to_pos_cache_key);

    if(!defined($pos_to_apos) or !defined($apos_to_pos)) {
        $id_aln = $self->id;

        #print join("\t", __PACKAGE__, 'mapping', $id_aln), "\n";

        $pos_to_apos = {};
        $apos_to_pos = {};
        foreach $aseq ($self->aligned_seqs) {
            $pos_to_apos->{$aseq->id_seq} = [];
            $apos_to_pos->{$aseq->id_seq} = [];

            $aas = [split /(-+)/, $aseq->aseq];
            $apos_start = 0;
            $apos_end = 0;
            $pos_start = 0;
            $pos_end = $aseq->start - 1;
            foreach $aas_sub (@{$aas}) {
                $len_sub = length($aas_sub);
                $apos_start = $apos_end + 1;
                $apos_end += $len_sub;
                if($aas_sub !~ /\A-/) { # FIXME - allow gap characters to be specified
                    $pos_start = $pos_end + 1;
                    $pos_end += $len_sub;
                    @{$pos_to_apos->{$aseq->id_seq}}[$pos_start..$pos_end] = ($apos_start..$apos_end);
                    @{$apos_to_pos->{$aseq->id_seq}}[$apos_start..$apos_end] = ($pos_start..$pos_end);
                }
            }
        }
        $self->cache->set($pos_to_apos_cache_key, $pos_to_apos);
        $self->cache->set($apos_to_pos_cache_key, $apos_to_pos);
    }
    $self->_pos_to_apos($pos_to_apos);
    $self->_apos_to_pos($apos_to_pos);

    return 1;
}

=head2 map_position

 usage   : $pos_in_seq2 = $alignment->map_position($id_seq1, $pos_in_seq1, $id_seq2);
 function: get the position in one sequence that is aligned to a particular position in another sequence
 args    : Seq.id of first sequence, position in first sequence, Seq.id of second sequence
 returns : - position in second sequence if it is present at this position
           - 0 if there is a gap in the second sequence at this position

=cut

sub map_position {
    my($self, $id_seq1, $pos1, $id_seq2) = @_;

    my $apos;
    my $pos2;

    #print join("\t", __PACKAGE__, 'map_position', $self->id, $pos1), "\n";

    if(!defined($apos = $self->apos_from_pos($id_seq1, $pos1))) {
        # warn "no apos for $id_seq1/$pos1 in alignment ", $self->id, '.';
        $pos2 = 0;
    }
    elsif(!defined($pos2 = $self->pos_from_apos($id_seq2, $apos))) {
        # warn "no pos for $id_seq2 at alignment ", $self->id, "/$apos.";
        $pos2 = 0;
    }

    return $pos2;
}

=head2 pcid

 usage   : $pcid = $alignment->pcid($id_seq1, $id_seq2);
 function: get percent identity between two aligned sequences
 args    : Seq.id of first sequence, Seq.id of second sequence
 returns : percent identity

=cut

sub pcid {
    my($self, $id_seq1, $id_seq2, $seq1, $seq2) = @_;

    my $pcid;
    my $aseq1;
    my $aseq2;
    my $pos;
    my $len;
    my $aa1;
    my $aa2;

    $pcid = 0.0;

    if(defined($aseq1 = $self->aseq($id_seq1)) and defined($aseq2 = $self->aseq($id_seq2))) {
        $aseq1 = $aseq1->aseq(undef, $seq1);
        $aseq2 = $aseq2->aseq(undef, $seq2);

        $len = $self->len;
        for($pos = 0; $pos < $len; $pos++) {
            $aa1 = substr($aseq1, $pos, 1);
            ($aa1 eq '-') and next;
            $aa2 = substr($aseq2, $pos, 1);
            ($aa2 eq $aa1) and $pcid++;
        }
        $pcid /= $len;
    }

    return $pcid;
}

=head2 id_line

 usage   :
 function:
 args    :
 returns :

=cut

sub id_line {
    my($self) = @_;

    my $count;
    my $i;
    my $aseq;
    my @aas;
    my $id_line;
    my $n_aas;
    my $state;

    $count = [];
    for($i = 0; $i < $self->len; $i++) {
        push @{$count}, {};
    }

    foreach $aseq ($self->aligned_seqs) {
        @aas = split //, $aseq->aseq;
        for($i = 0; $i < @aas; $i++) {
            $count->[$i]->{$aas[$i]}++;
        }
    }

    $id_line = [];
    for($i = 0; $i < @{$count}; $i++) {
        $n_aas = scalar keys %{$count->[$i]};
        $state = (($n_aas == 1) and !defined($count->[$i]->{'-'})) ? '+' : ' '; # FIXME - allow gap characters other than '-'
        push @{$id_line}, $state;
    }
    $id_line = join '', @{$id_line};

    return $id_line;
}

1;
