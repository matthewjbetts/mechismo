package Fist::Interface::Frag;

use Moose::Role;

=head1 NAME

 Fist::Interface::Frag

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

=head2 id_seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'id_seq';

=head2 pdb

 usage   :
 function:
 args    :
 returns :

=cut

requires 'pdb';

=head2 idcode

 usage   :
 function:
 args    :
 returns :

=cut

sub idcode {
    my($self) = @_;

    return $self->pdb->idcode;
}

=head2 fullchain

 usage   :
 function:
 args    :
 returns :

=cut

requires 'fullchain';

=head2 description

 usage   :
 function:
 args    :
 returns :

=cut

requires 'description';

=head2 chemical_type

 usage   :
 function:
 args    :
 returns :

=cut

requires 'chemical_type';

=head2 dom

 usage   :
 function:
 args    :
 returns :

=cut

requires 'dom';

=head2 seq_groups

 usage   :
 function:
 args    :
 returns :

=cut

requires 'seq_groups';

=head2 frag_insts

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag_insts';

=head2 scops

 usage   :
 function:
 args    :
 returns :

=cut

requires 'scops';

=head2 scops

 usage   :
 function:
 args    :
 returns :

=cut

requires 'scops';

=head2 chain_segments

 usage   :
 function:
 args    :
 returns :

=cut

requires 'chain_segments';

=head2 doms

 usage   : used internally by roles that require a list of objects with fn, id and dom methods(eg. Fist::Utils::DomFile)
 function:
 args    :
 returns :

=cut

sub doms {
    my($self) = @_;

    return($self);
}

=head2 type_chem

 usage   :
 function:
 args    :
 returns :

=cut

sub type_chem {
     return('unknown');
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

=head2 fn

 usage   :
 function:
 args    :
 returns :

=cut

has 'fn' => (is => 'rw', isa => 'Str');

around 'fn' => sub {
    my($orig, $self, $fn) = @_;

    if(defined($fn)) {
        $fn = $self->$orig($fn);
    }
    else {
        if(!defined($fn = $self->$orig)) {
            $ENV{'DS'} and ($fn = sprintf "%s/pdb/%s/pdb%s.ent.gz", $ENV{DS}, substr($self->pdb->idcode, 1, 2), $self->pdb->idcode);
            $self->$orig($fn);
        }
    }

    return $fn;
};

=head2 jmol_str

 usage   :
 function: get string for selecting this fragment instance from the pdb within Jmol
 args    :
 returns : a string

=cut

sub jmol_str {
    my($self) = @_;

    my $str;
    my $chain_segment;

    $str = [];
    foreach $chain_segment ($self->chain_segments) {
        push @{$str}, sprintf("%d-%d:%s", $chain_segment->resseq_start, $chain_segment->resseq_end, $chain_segment->chain);
    }
    $str = (@{$str} > 1) ? join(' or ', @{$str}) : $str->[0];

    return $str;
};

=head2 schema

 usage   :
 function:
 args    :
 returns :

=cut

requires 'schema';

=head2 add_to_res_mappings

 usage   :
 function:
 args    :
 returns :

=cut

requires 'add_to_res_mappings';

=head1 ROLES

 with 'Fist::Utils::UniqueIdentifier';
 with 'Fist::Utils::Cache';
 with 'Fist::Utils::DomFile';
 with 'Fist::Utils::PdbSeq';
 with 'Fist::Utils::InterpretsFasta';
 with 'Fist::Utils::PdbFile';
 with 'Fist::Utils::Dssp';
 with 'Fist::Utils::Naccess';

=cut

with 'Fist::Utils::UniqueIdentifier';
with 'Fist::Utils::Cache';
#with 'Fist::Interface::Dom'; # FIXME - complains that Frag::NonDB::Frag doesn't provide the fn method for some reason...
with 'Fist::Utils::DomFile';
with 'Fist::Utils::PdbSeq';
with 'Fist::Utils::InterpretsFasta';
with 'Fist::Utils::PdbFile';
with 'Fist::Utils::Dssp';
with 'Fist::Utils::Naccess';

=head1 METHODS

=cut

=head2 BUILD

=cut

sub BUILD {
    my($self) = @_;

    $self->id;
}

requires 'add_to_frag_insts';
requires 'add_to_scops';
requires 'add_to_seq_groups';
requires 'add_to_chain_segments';
requires 'seq_groups_by_type';

=head2 label

 usage   :
 function:
 args    :
 returns :

=cut

sub label {
    my($self) = @_;

    my $label;

    ($label = join(':', $self->pdb->idcode, $self->dom)) =~ s/\s/_/g;

    return $label;
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
             idcode        => $self->idcode,
             id_seq        => $self->id_seq,
             dom           => $self->dom,
             description   => $self->description,
             chemical_type => $self->chemical_type,
             jmol_str      => $self->jmol_str,
             scops         => [$self->scops],
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

    print $fh join("\t", $self->id, $self->pdb->idcode, $self->id_seq, $self->fullchain, $self->description, $self->chemical_type, $self->dom), "\n";
}

=head2 overlap

 usage   : $overlap = $self->overlap($segment2)
 function: calculates how much the sequences of the fragments overlap
 args    : the second Frag object
 returns : a Fist::Utils::Overlap object, or undef if no overlap

=cut

sub overlap {
    my($self, $frag2) = @_;

    my $overlap;
    my $total_overlap;
    my $segment1;
    my $segment2;

    $total_overlap = undef;
    foreach $segment1 ($self->chain_segments) {
        foreach $segment2 ($frag2->chain_segments) {
            ($segment2->chain eq $segment1->chain) or next;
            defined($overlap = $segment1->overlap($segment2)) or next;

            if(defined($total_overlap)) {
                #$total_overlap = $total_overlap + $overlap; # FIXME - overloading doesn't work for some reason
                $total_overlap = Fist::Utils::Overlap::plus($total_overlap, $overlap);
            }
            else {
                $total_overlap = $overlap;
            }
        }
    }

    return $total_overlap;
}

=head2 interprets_seq

 usage   :
 function:
 args    :
 returns :

=cut

requires 'interprets_seq';

=head2 aln

 usage   :
 function:
 args    :
 returns :

=cut

requires 'aln';

=head2 _get_mapping

 usage   :
 function:
 args    :
 returns :

=cut

sub _get_mapping {
    my($self) = @_;

    Carp::cluck('not implemented');
}

=head2 fist_to_pdb

 usage   :
 function:
 args    :
 returns :

=cut

sub fist_to_pdb {
    my($self) = @_;

    my $fist_to_pdb;
    my $pdb_to_fist;

    ($fist_to_pdb, $pdb_to_fist) = $self->_get_mapping;

    return $fist_to_pdb;
}

=head2 pdb_to_fist

 usage   :
 function:
 args    :
 returns :

=cut

sub pdb_to_fist {
    my($self) = @_;

    my $fist_to_pdb;
    my $pdb_to_fist;

    ($fist_to_pdb, $pdb_to_fist) = $self->_get_mapping;

    return $pdb_to_fist;
}

=head2 fist

 usage   : $fist = $self->fist($chain, $resseq, $icode);
 function: gets the position in the fist sequence of the given chain, resseq and icode
 args    : resseq, chain, icode
 returns : position in the fist sequence

=cut

sub fist {
    my($self, $chain, $resseq, $icode) = @_;

    my $fist;

    $fist = $self->pdb_to_fist->{$chain}->{$resseq}->{$icode};

    return $fist;
}

1;

