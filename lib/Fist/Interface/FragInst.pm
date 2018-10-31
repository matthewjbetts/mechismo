package Fist::Interface::FragInst;

use Moose::Role;
use Fist::NonDB::Contact;

=head1 NAME

 Fist::Interface::FragInst

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

=head2 frag

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frag';

=head2 dom

 usage   : $dom = $self->dom
 function: get $self->frag->dom
 args    : none
 returns : dom as a string

=cut

sub dom {
    my($self) = @_;

    return $self->frag->dom;
}

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

=head2 assembly

 usage   :
 function:
 args    :
 returns :

=cut

requires 'assembly';

=head2 model

 usage   :
 function:
 args    :
 returns :

=cut

requires 'model';

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
            if($ENV{'DS'}) {
                if($self->assembly == 0) {
                    $fn = sprintf(
                                  "%s/pdb/%s/pdb%s.ent.gz",
                                  $ENV{DS},
                                  substr($self->frag->pdb->idcode, 1, 2),
                                  $self->frag->pdb->idcode,
                                 );
                }
                else {
                    $fn = sprintf(
                                  "%s/pdb-biounit/%s/%s-%s-%s.pdb.gz",
                                  $ENV{DS},
                                  substr($self->frag->pdb->idcode, 1, 2),
                                  $self->frag->pdb->idcode,
                                  $self->assembly,
                                  $self->model,
                                 );
                }
                $self->$orig($fn);
            }
        }
    }

    return $fn;
};

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
        $url = sprintf "static/data/pdb/%s/pdb%s.ent.gz", substr($self->frag->pdb->idcode, 1, 2), $self->frag->pdb->idcode;
    }
    else {
        $url = sprintf "static/data/pdb-biounit/%s/%s-%s-%s.pdb.gz", substr($self->frag->pdb->idcode, 1, 2), $self->frag->pdb->idcode, $self->assembly, $self->model;
    }

    return $url;
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
    foreach $chain_segment ($self->frag->chain_segments) {
        push @{$str}, sprintf("%d-%d:%s", $chain_segment->resseq_start, $chain_segment->resseq_end, $chain_segment->chain);
    }
    $str = (@{$str} > 1) ? join(' or ', @{$str}) : $str->[0];
    ($self->model > 0) and ($str = sprintf("model=%d and (%s)", $self->model, $str));

    return $str;
};

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

=head2 label

 usage   :
 function:
 args    :
 returns :

=cut

sub label {
    my($self) = @_;

    my $label;

    ($label = join(':', $self->frag->pdb->idcode, $self->assembly, $self->model, $self->frag->dom)) =~ s/\s/_/g;

    return $label;
}

=head2 res_contact_table

 usage   :
 function: gets intra-fragint residues in contact, with sidechain-sidechain etc info.
 args    :
 returns :

=cut

requires 'res_contact_table';

=head2 res_contact_table_list

 usage   :
 function: gets intra-fraginst residues in contact, with sidechain-sidechain etc
           info, as a list of lists (first element gives headings).
 args    :
 returns :

=cut

requires 'res_contact_table_list';

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
             id       => $self->id,
             id_frag  => $self->id_frag,
             assembly => $self->assembly,
             model    => $self->model,
             jmol_str => $self->jmol_str,
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

    print $fh join("\t", $self->id, $self->frag->id, $self->assembly, $self->model), "\n";
}

=head2 struct

 usage   : $struct = $frag_inst->struct
 function: join('-', $self->frag->pdb->idcode, $self->assembly, $self->model)
 args    : none
 returns : a string

=cut

sub struct {
    my($self) = @_;

    my $struct;

    $struct = join('-', $self->frag->pdb->idcode, $self->assembly, $self->model);

    return $struct;
}

1;
