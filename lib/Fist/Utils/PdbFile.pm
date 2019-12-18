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
 function: - generates a pdb file for the given STAMP format domain file.
           - dssp (and other progs) take a whole pdb file, so we need to write one
             out when running it on substructures (single chains, interactions, etc)
           - assigns a new chain id to each domain
           - pure-perl alternative to running the STAMP program 'transform' but
             does *not* apply transformations given in the domain file
           - includes HETATMs within the limits of the domains
 args    : none or $domfile (File::Temp object) - this will be generated if
           none is given
 returns : a File::Temp object and a hash of the mapping of chain, resseq and
           icode in the combined pdbfile to that of the individual domains

           $res_mapping->{$combined_chain}->{$combined_resseq}->{$combined_icode} = [$id_dom, $dom_chain, $dom_resseq, $dom_icode];

=cut

sub _parse_dom {
    my($str) = @_;

    my $domSub;
    my $dom;

    while($str =~ /(\S+)\s+(\S+)\s+(\S+)\s+to\s+(\S+)\s+(\S+)\s+(\S+)/g) {
        # NOTE: not considering STAMP's 'ALL' or 'CHAIN X' notation
        $domSub = {
                   start => {
                             cid    => $1,
                             resSeq => $2,
                             iCode  => $3,
                            },

                   end   => {
                             cid    => $4,
                             resSeq => $5,
                             iCode  => $6,
                            },
                  };
        push @{$dom}, $domSub;
    }

    return $dom;
}

sub _extract_dom {
    my($fn, $id_dom, $dom, $cidNew, $pdbfile, $res_mapping) = @_;

    # FIXME - use Carp for error messages

    my $fh;
    my $dom1;
    my $domSub;
    my $resName;
    my $cid;
    my $resSeq;
    my $iCode;
    my $resName_p;
    my $cid_p;
    my $resSeq_p;
    my $iCode_p;
    my $state;

    $dom1 = _parse_dom($dom);
    $cid_p = 'XXXXXXXX';
    $resSeq_p = 'XXXXXXXX';
    $iCode_p = 'XXXXXXXX';
    $resName_p = 'XXXXXXXX';
    # since subsections of pdbs can be given in any order,
    # am parsing the complete pdb for each. This might be slow...
    foreach $domSub (@{$dom1}) {
        if(!open($fh, "zcat $fn |")) {
            warn "Error: extract_dom: cannot open pipe from 'zcat $fn'";
            return 0;
        }

        $state = '';
        while(<$fh>) {
            if(/^ATOM/ or /^HETATM/) {
                ($resName = substr($_, 17, 3)) =~ s/\s+//g;
                ($cid = substr($_, 21, 1, $cidNew)) =~ s/\s+//g;
                ($resSeq = substr($_, 22, 4)) =~ s/\s+//g;
                ($iCode = substr($_, 26, 1)) =~ s/\s+//g;
                ($iCode eq '') and ($iCode = '_');

                ($resName eq 'HOH') and next;

                if(
                   ($cid eq $domSub->{start}->{cid}) and
                   ($resSeq eq $domSub->{start}->{resSeq}) and
                   ($iCode eq $domSub->{start}->{iCode})
                  ) {
                    # start and end may be the same residue
                    if(
                       ($cid eq $domSub->{end}->{cid}) and
                       ($resSeq eq $domSub->{end}->{resSeq}) and
                       ($iCode eq $domSub->{end}->{iCode})
                      ) {
                        $state = 'end';
                    }
                    else {
                        $state = 'in domain';
                    }
                }
                elsif(
                   ($cid eq $domSub->{end}->{cid}) and
                   ($resSeq eq $domSub->{end}->{resSeq}) and
                   ($iCode eq $domSub->{end}->{iCode})
                  ) {
                    ($state eq 'in domain') and ($state = 'end');
                }
                elsif($state eq 'end') {
                    last;
                }

                if($state ne '') {
                    if(($resName ne $resName_p) or ($cid ne $cid_p) or ($resSeq ne $resSeq_p) or ($iCode ne $iCode_p)) {
                        $res_mapping->{$cidNew}->{$resSeq}->{$iCode} = [$id_dom, $cid, $resSeq, $iCode];
                    }

                    $resName_p = $resName;
                    $cid_p = $cid;
                    $resSeq_p = $resSeq;
                    $iCode_p = $iCode;

                    print($pdbfile $_);
                }
            }
            elsif(/^ENDMDL/) {
                # FIXME - STAMP transform only considers the first MODEL in a pdb,
                # which is why I'm doing the same here. This could be changed to allow
                # the model to be selected, but that would require a change in STAMP
                # format domain descriptions
                last;
            }
        }
        close($fh);
    }

    return 1;
}

sub write_pdbfile {
    my($self, $domfile, $suffix) = @_;

    my $tempdir;
    my $pdbfile;
    my @cids;
    my $i;
    my $res_mapping;
    my $dom;

    defined($suffix) or ($suffix = '');

    $tempdir = $self->tempdir;
    $pdbfile = File::Temp->new(DIR => $tempdir, SUFFIX => $suffix, UNLINK => $self->cleanup);
    @cids = ("A".."Z", 0..9, "a".."z");
    $i = -1;
    $res_mapping = {};
    foreach $dom ($self->doms) {
        _extract_dom($dom->fn, $dom->id, $dom->dom, $cids[++$i], $pdbfile, $res_mapping);
    }

    return($pdbfile, $res_mapping);
}

;

1;
