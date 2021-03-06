package Fist::Utils::Dssp;

use Moose::Role;
use Carp ();
use File::Temp ();

=head1 NAME

 Fist::Utils::Dssp - a Moose::Role

=cut

=head1 ACCESSORS

=cut

requires 'write_pdbfile';

=head1 ROLES

 with 'Fist::Utils::System';

=cut

with 'Fist::Utils::System';

=head1 METHODS

=cut

=head2 run_dssp

 usage   :
 function: runs DSSP
 args    :
 returns :

=cut

sub run_dssp {
    my($self, $pdbfile, $res_mapping) = @_;

    my $pdbfile_is_mine;
    my $dsspfile;
    my $errfile;
    my $cmd;
    my $stat;
    my @errors;
    my $type;
    my $id;
    my $fh;
    my $state;
    my @data;
    my $resSeq;
    my $iCode;
    my $cid;
    my $aa;
    my $ss;
    my $phi;
    my $psi;
    my $id_dom;
    my $cid_dom;
    my $resSeq_dom;
    my $iCode_dom;
    my $dssp_residues;

    $self->ca_only and return(undef);

    $pdbfile_is_mine = 0;
    if(!defined($pdbfile)) {
        ($pdbfile, $res_mapping) = $self->write_pdbfile;
        $pdbfile_is_mine = 1;
    }

    # run dssp
    $dsspfile = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    $errfile = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);
    #$cmd = "dssp -na $pdbfile $dsspfile 1> /dev/null 2> $errfile"; # '-na' because quicker not to calculate asa
    $cmd = "mkdssp -i $pdbfile -o $dsspfile 1> /dev/null 2> $errfile";
    $stat = $self->mysystem($cmd);
    $stat >>= 8;

    @errors = ();
    if(-s $errfile) {
        if(!open($fh, $errfile)) {
            Carp::cluck("cannot open '$errfile' for reading.");
            return undef;
        }
        while(<$fh>) {
            push @errors, $_;
        }
        close($fh);
    }

    if(@errors > 0) {
        $type = ref $self;
        $id = $self->id;
        Carp::cluck(join('', "'$cmd' failed for $type id=$id:\n", @errors));
        return undef;
    }

    if($stat != 0) {
        $type = ref $self;
        $id = $self->id;
        Carp::cluck("'$cmd' failed for $type id=$id with status $stat: '$!'");
        return undef;
    }


    # parse dssp file
    if(!open($fh, $dsspfile)) {
        Carp::cluck("cannot open '$dsspfile' for reading.");
        return undef;
    }
    $state = 'header';
    $dssp_residues = [];
    while(<$fh>) {
        if(/\A  #  RESIDUE/) {
            $state = 'columns';
        }
        elsif($state eq 'columns') {
            $state = 'residue';
        }

        if($state eq 'residue') {
            # From http://swift.cmbi.ru.nl/gv/dssp/ :
            #
            # HEADER    HYDROLASE   (SERINE PROTEINASE)         17-MAY-76   1EST
            # ...
            #   240  1  4  4  0 TOTAL NUMBER OF RESIDUES, NUMBER OF CHAINS,
            #                   NUMBER OF SS-BRIDGES(TOTAL,INTRACHAIN,INTERCHAIN)                .
            #  10891.0   ACCESSIBLE SURFACE OF PROTEIN (ANGSTROM**2)
            #   162 67.5   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(J)  ; PER 100 RESIDUES
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS IN     PARALLEL BRIDGES; PER 100 RESIDUES
            #    84 35.0   TOTAL NUMBER OF HYDROGEN BONDS IN ANTIPARALLEL BRIDGES; PER 100 RESIDUES
            # ...
            #    26 10.8   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+2)
            #    30 12.5   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+3)
            #    10  4.2   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+4)
            # ...
            #   #  RESIDUE AA STRUCTURE BP1 BP2  ACC   N-H-->O  O-->H-N  N-H-->O  O-->H-N
            #     2   17   V  B 3   +A  182   0A   8  180,-2.5 180,-1.9   1,-0.2 134,-0.1
            #                                    ...Next two lines wrapped as a pair...
            #                                     TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA
            #                                   -0.776 360.0   8.1 -84.5 125.5  -14.7   34.4   34.8
            # ....;....1....;....2....;....3....;....4....;....5....;....6....;....7..
            #     .-- sequential resnumber, including chain breaks as extra residues
            #     |    .-- original PDB resname, not nec. sequential, may contain letters
            #     |    |   .-- amino acid sequence in one letter code
            #     |    |   |  .-- secondary structure summary based on columns 19-38
            #     |    |   |  | xxxxxxxxxxxxxxxxxxxx recommend columns for secstruc details
            #     |    |   |  | .-- 3-turns/helix
            #     |    |   |  | |.-- 4-turns/helix
            #     |    |   |  | ||.-- 5-turns/helix
            #     |    |   |  | |||.-- geometrical bend
            #     |    |   |  | ||||.-- chirality
            #     |    |   |  | |||||.-- beta bridge label
            #     |    |   |  | ||||||.-- beta bridge label
            #     |    |   |  | |||||||   .-- beta bridge partner resnum
            #     |    |   |  | |||||||   |   .-- beta bridge partner resnum
            #     |    |   |  | |||||||   |   |.-- beta sheet label
            #     |    |   |  | |||||||   |   ||   .-- solvent accessibility
            #     |    |   |  | |||||||   |   ||   |
            #   #  RESIDUE AA STRUCTURE BP1 BP2  ACC
            #     |    |   |  | |||||||   |   ||   |
            #    35   47   I  E     +     0   0    2
            #    36   48   R  E >  S- K   0  39C  97
            #    37   49   Q  T 3  S+     0   0   86
            #    38   50   N  T 3  S+     0   0   34
            #    39   51   W  E <   -KL  36  98C   6
            #

            # 20200923 - output format appears to have changed:
            #
            # ==== Secondary Structure Definition by the program DSSP, CMBI version by M.L. Hekkelman/2010-10-21 ==== DATE=2020-09-23        .
            # REFERENCE W. KABSCH AND C.SANDER, BIOPOLYMERS 22 (1983) 2577-2637                                                              .
            # HEADER    OXYGEN TRANSPORT                        07-MAR-84   4HHB                                                             .
            # COMPND   2 MOLECULE: HEMOGLOBIN SUBUNIT ALPHA;                                                                                 .
            # SOURCE   2 ORGANISM_SCIENTIFIC: HOMO SAPIENS;                                                                                  .
            # AUTHOR    G.FERMI,M.F.PERUTZ                                                                                                   .
            #   574  4  0  0  0 TOTAL NUMBER OF RESIDUES, NUMBER OF CHAINS, NUMBER OF SS-BRIDGES(TOTAL,INTRACHAIN,INTERCHAIN)                .
            #  25759.5   ACCESSIBLE SURFACE OF PROTEIN (ANGSTROM**2)                                                                         .
            #   456 79.4   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(J)  , SAME NUMBER PER 100 RESIDUES                              .
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS IN     PARALLEL BRIDGES, SAME NUMBER PER 100 RESIDUES                              .
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS IN ANTIPARALLEL BRIDGES, SAME NUMBER PER 100 RESIDUES                              .
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-5), SAME NUMBER PER 100 RESIDUES                              .
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-4), SAME NUMBER PER 100 RESIDUES                              .
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-3), SAME NUMBER PER 100 RESIDUES                              .
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-2), SAME NUMBER PER 100 RESIDUES                              .
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I-1), SAME NUMBER PER 100 RESIDUES                              .
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+0), SAME NUMBER PER 100 RESIDUES                              .
            #     0  0.0   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+1), SAME NUMBER PER 100 RESIDUES                              .
            #    12  2.1   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+2), SAME NUMBER PER 100 RESIDUES                              .
            #    94 16.4   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+3), SAME NUMBER PER 100 RESIDUES                              .
            #   336 58.5   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+4), SAME NUMBER PER 100 RESIDUES                              .
            #    10  1.7   TOTAL NUMBER OF HYDROGEN BONDS OF TYPE O(I)-->H-N(I+5), SAME NUMBER PER 100 RESIDUES                              .
            #   1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30     *** HISTOGRAMS OF ***           .
            #   0  0  0  2  1  1  0  0  2  0  2  0  0  4  4  0  2  5  5  0  0  0  0  0  0  0  0  0  0  0    RESIDUES PER ALPHA HELIX         .
            #   0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0    PARALLEL BRIDGES PER LADDER      .
            #   0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0    ANTIPARALLEL BRIDGES PER LADDER  .
            #   0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0    LADDERS PER SHEET                .
            #   #  RESIDUE AA STRUCTURE BP1 BP2  ACC     N-H-->O    O-->H-N    N-H-->O    O-->H-N    TCO  KAPPA ALPHA  PHI   PSI    X-CA   Y-CA   Z-CA 
            #     1    1 A V              0   0  133      0, 0.0     2,-0.4     0, 0.0   127,-0.1   0.000 360.0 360.0 360.0 144.8    6.9   17.8    4.6
            #     2    2 A L        -     0   0   19     71,-0.1   122,-0.0     1,-0.1     0, 0.0  -0.791 360.0-141.9 -92.9 121.5   10.6   17.9    4.3
            #     3    3 A S     >  -     0   0   43     -2,-0.4     4,-2.8     1,-0.0     5,-0.2  -0.150  29.4-103.9 -60.8-176.0   12.3   19.9    7.1

            #print;

            @data = unpack 'a5a5a1a1a4a1a16a5a65a6a6', $_;

            ($resSeq = $data[1]) =~ s/\s+//g;
            ($iCode  = $data[2]) =~ s/\s+//g;
            ($cid    = $data[3]) =~ s/\s+//g;
            ($aa     = $data[4]) =~ s/\s+//g;
            ($ss     = $data[5]) =~ s/\s+//g;
            ($phi    = $data[9]) =~ s/\s+//g;
            ($psi    = $data[10]) =~ s/\s+//g;

            ($aa =~ /^\!/) and next; # DSSP chain break identifier
            ($iCode eq '') and ($iCode = '_');
            ($ss eq '') and ($ss = 'C');

            if(defined($res_mapping->{$cid})) {
                if(defined($res_mapping->{$cid}->{$resSeq})) {
                    if(defined($res_mapping->{$cid}->{$resSeq}->{$iCode})) {
                        ($id_dom, $cid_dom, $resSeq_dom, $iCode_dom) = @{$res_mapping->{$cid}->{$resSeq}->{$iCode}};
                        push @{$dssp_residues}, [$id_dom, $cid_dom, $resSeq_dom, $iCode_dom, $ss, $phi, $psi];
                    }
                    else {
                        Carp::cluck(join('-', $self->id, $cid, $resSeq, $iCode, "no iCode '$iCode' mapping"));
                        die $pdbfile;
                    }
                }
                else {
                    Carp::cluck(join('-', $self->id, $cid, $resSeq, $iCode, "no resSeq '$resSeq' mapping"));
                }
            }
            else {
                Carp::cluck(join('-', $self->id, $cid, $resSeq, $iCode, "no cid '$cid' mapping"));
            }
        }
    }
    close($fh);

    return $dssp_residues;
}

1;
