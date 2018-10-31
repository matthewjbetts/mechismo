package Fist::Utils::PdbFile;

use Moose::Role;
use File::Temp ();

=head1 NAME

 Fist::Utils::PdbFile - a Moose::Role

=cut

=head1 ACCESSORS

=cut

=head2 write_domfile

 usage   : writes a STAMP format domain file
 function: method required of classes that consume this role
 args    :
 returns : a File::Temp object

=cut

requires 'write_domfile';

=head1 METHODS

=cut

=head2 write_pdbfile

 usage   : $pdbfile = $self->write_pdbfile($domfile);
 function: runs the STAMP program 'transform' with options '-g' and '-o' to
           generate a pdb file
 args    : none or $domfile (File::Temp object) - this will be generated if
           none is given
 returns : a File::Temp object and a hash of the mapping of chain, resseq and
           icode in the combined pdbfile to that of the individual domains

           $res_mapping->{$combined_chain}->{$combined_resseq}->{$combined_icode} = [$id_dom, $dom_chain, $dom_resseq, $dom_icode];


 - dssp (and other progs) take a whole pdb file, so we need to write one
   out when running it on substructures (single chains, interactions, etc)

 - transform -g -o outputs a single pdb file but may change chain, resseq
   and icode

 - however, we want the values produced (eg. solvent accessibility)
   with reference to the original chain, resseq and icodes

 - without the -g and -o options to transform, would have to concat the
   resultant pdb files (one per domain) myself but this would not
   guarantee that chain, resseq and icode are unique for every residue

 - therefore I need to

   - parse resultant pdb file for translation of new chain, resseq and
     icode to old
     - get resseq, chain and icode for original domains
     - assume residues are in the same order in transformed file, and
       that none are missing and there are no extras

   - alternatively, align the sequence produced by dssp to the fist
     sequence(s) and get resseq, chain and icode from that

=cut

sub write_pdbfile {
    my($self, $domfile, $suffix) = @_;

    #my $transform = 'transform';

    my $transform;

    my $fh;
    my $ids_doms;
    my $id_dom;
    my $doms;
    my $tempdir;
    my $pdbfile;
    my $errfile;
    my $cmd;
    my $stat;
    my @errors;
    my $i;
    my $res_mapping;
    my $tempdir2;
    my $dn_tmp;
    my $fn_dom_pdb;
    my $fh_dom_pdb;
    my @cids;
    my $resName;
    my $cid;
    my $resSeq;
    my $iCode;
    my $resName_p;
    my $cid_p;
    my $resSeq_p;
    my $iCode_p;
    my $dom;
    my @data;

    # include HETATMs within the limits of the domains
    $transform = "transform -hetdom";

    $tempdir = $self->tempdir;

    # write a domain file
    defined($domfile) or ($domfile = $self->write_domfile);

    defined($suffix) or ($suffix = '');

    # use transform to output a pdb file per domain
    $errfile = File::Temp->new(DIR => $tempdir, UNLINK => $self->cleanup);
    $tempdir2 = File::Temp->newdir(DIR => $tempdir, UNLINK => $self->cleanup);
    $dn_tmp = $tempdir2->dirname;
    $cmd = "cd $dn_tmp; $transform -f $domfile 1> /dev/null 2> $errfile"; # 'cd' to be temp safe, because transform outputs to cwd

    $stat = $self->mysystem($cmd);
    $stat >>= 8;
    @errors = ();
    if($stat != 0) {
        push @errors, "'$cmd' failed with status $stat: '$!'";
        if(-s $errfile) {
            if(open($fh, $errfile)) {
                while(<$fh>) {
                    /^# WARNING: strange atom type/ and next;
                    push @errors, $_;
                }
                close($fh);
            }
            else {
                push @errors, "cannot open '$errfile' for reading.";
            }
        }
    }

    if(@errors > 0) {
        Carp::cluck("'$cmd' failed with errors: ", @errors);
        return undef;
    }

    # produce a pdb file for the domains
    $pdbfile = File::Temp->new(DIR => $tempdir, SUFFIX => $suffix, UNLINK => $self->cleanup);

    # read in each domain pdb
    #  - increment chain
    #  - output ATOM/HETATM lines with new chain
    #  - save mapping
    @cids = ("A".."Z", 0..9, "a".."z");
    $i = -1;
    $res_mapping = {};
    foreach $dom ($self->doms) {
        ++$i;
        $id_dom = $dom->id;
        $fn_dom_pdb = sprintf "%s/%s.pdb", $dn_tmp, $id_dom;
        if(!open($fh_dom_pdb, $fn_dom_pdb)) {
            Carp::cluck("cannot open '$fn_dom_pdb' for reading.");
            return undef;
        }
        $cid_p = 'XXXXXXXX';
        $resSeq_p = 'XXXXXXXX';
        $iCode_p = 'XXXXXXXX';
        $resName_p = 'XXXXXXXX';
        while(<$fh_dom_pdb>) {
            if(/^ATOM/ or /^HETATM/) {
                ($resName = substr($_, 17, 3)) =~ s/\s+//g;
                ($resSeq  = substr($_, 22, 4)) =~ s/\s+//g;
                ($iCode   = substr($_, 26, 1)) =~ s/\s+//g;
                ($cid = substr($_, 21, 1, $cids[$i])) =~ s/\s+//g;

                if(($resName ne $resName_p) or ($cid ne $cid_p) or ($resSeq ne $resSeq_p) or ($iCode ne $iCode_p)) {
                    $res_mapping->{$cids[$i]}->{$resSeq}->{$iCode} = [$id_dom, $cid, $resSeq, $iCode];
                }

                $resName_p = $resName;
                $cid_p = $cid;
                $resSeq_p = $resSeq;
                $iCode_p = $iCode;
            }
            print $pdbfile $_;
        }
        close($fh_dom_pdb);
    }

    return($pdbfile, $res_mapping);
}

1;
