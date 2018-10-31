package Fist::Interface::Pdb;

use Moose::Role;
use File::Temp;

=head1 NAME

 Fist::Interface::Pdb

=cut

=head1 ACCESSORS

=cut

=head2 idcode

 usage   : $self->idcode
 function: get/set the idCode. If the idCode is given, will set it to lower case
 args    : the 4-character idcode of the pdb (set) or nothing (get)
 returns : the 4-character idcode of the pdb

=cut

requires 'idcode';

=head2 title

 usage   : $self->title
 function:
 args    : the title of the pdb (set) or nothing (get)
 returns : the title of the pdb as a string

=cut

requires 'title';

=head2 resolution

 usage   : $self->resolution
 function:
 args    : the resolution of the pdb (set) or nothing (get)
 returns : the resolution of the pdb as a number

=cut

requires 'resolution';

=head2 depdate

 usage   : $self->depdate
 function:
 args    :
 returns :

=cut

requires 'depdate';

=head2 updated

 usage   : $self->updated
 function:
 args    :
 returns :

=cut

requires 'updated';

=head2 expdtas

 usage   :
 function:
 args    :
 returns :

=cut

requires 'expdtas';

=head2 frags

 usage   :
 function:
 args    :
 returns :

=cut

requires 'frags';

=head2 doms

 usage   :
 function:
 args    :
 returns :

=cut

sub doms {
    my($self) = @_;

    return $self->frags;
}

=head2 fn

 usage   :
 function: get/set the file name of the pdb. If no file name is given and it
           has not yet been set, one will be constructed from the idCode.
 args    :
 returns : the filename

=cut

has 'fn' => (is => 'rw', isa => 'Str');

around 'fn' => sub {
    my($orig, $self, $fn) = @_;

    if(defined($fn)) {
        $fn = $self->$orig($fn);
    }
    else {
        if(!defined($fn = $self->$orig)) {
            $ENV{'DS'} and ($fn = sprintf "%s/pdb/%s/pdb%s.ent.gz", $ENV{'DS'}, substr($self->idcode, 1, 2), $self->idcode);
            $self->$orig($fn);
        }
        return $fn;
    }
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

    my $url;

    $url = sprintf "static/data/pdb/%s/pdb%s.ent.gz", substr($self->idcode, 1, 2), $self->idcode;

    return $url;
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

 with 'Fist::Utils::System';
 with 'Fist::Utils::DomFile';
 with 'Fist::Utils::PdbSeq';
 with 'Fist::Utils::InterpretsFasta';

=cut

with 'Fist::Utils::System';
with 'Fist::Utils::DomFile';
with 'Fist::Utils::PdbSeq';
with 'Fist::Utils::InterpretsFasta';

=head1 METHODS

=cut

=head2 BUILD

=cut

sub BUILD {
    my($self) = @_;

    defined($self->idcode) and ($self->idcode(lc $self->idcode));
    $self->id;
}

requires 'add_to_frags';
requires 'add_to_expdtas';

sub get_contacts {
    my($self, $id_contact, $fn_contact, $fn_res_contact) = @_;

    my $cmd;
    my $tmp_dom;
    my $tmp_assemblies;
    my $tmp_out;
    my $frag;
    my $frag_inst;
    my $stat;

    # create temporary dom, FragInst and output files
    $tmp_dom = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup); # $self->write_domfile() only writes doms for the Frags, not all FragInsts
    $tmp_assemblies = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    foreach $frag ($self->frags) {
        foreach $frag_inst ($frag->frag_insts) {
            print $tmp_dom join(' ', $frag_inst->fn, $frag_inst->id, '{', $frag->dom, '}'), "\n";
            $frag_inst->output_tsv($tmp_assemblies);
        }
    }
    $tmp_out = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);

    $cmd = sprintf(
                   # FIXME - better way to give program name and path?
                   "mechismoContacts --intra --both_directions --id_contact %d --assemblies %s --contacts_out %s --res_contacts_out %s --append < %s 1> %s",
                   ${$id_contact},
                   $tmp_assemblies,
                   $fn_contact,
                   $fn_res_contact,
                   $tmp_dom,
                   $tmp_out,
                  );
    #print "$cmd\n";
    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    if($stat != 0) {
        Carp::cluck("'$cmd' command failed with status $stat for idcode ", $self->idcode, ': ', $!);
        return 0;
    }

    # update id_contact
    if(!open(INFO, $tmp_out)) {
        Carp::cluck("cannot open '$tmp_out' file for reading.");
        return 0;
    }
    while(<INFO>) {
        if(/^id_contact = (\d+)/) {
            ${$id_contact} = $1;
            last;
        }
    }
    close(INFO);

    #print 'id_contact = ', ${$id_contact}, "\n";

    return 1;
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
             idcode     => $self->idcode,
             title      => $self->title,
             depdate    => $self->depdate->ymd,
             updated    => $self->updated->ymd,
             resolution => $self->resolution,
             expdtas    => [$self->expdtas],
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

    print $fh join("\t", $self->idcode, $self->title, $self->resolution, $self->depdate->date, $self->updated->date), "\n";
}

1;
