package Fist::Utils::Naccess;

use Moose::Role;
use Carp ();
use File::Temp ();

=head1 NAME

 Fist::Utils::Naccess - a Moose::Role

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

=head2 run_naccess

 usage   :
 function: runs naccess
 args    :
 returns :

=cut

sub run_naccess {
    my($self, $pdbfile, $res_mapping, $fn_vdw, $fn_std, $z) = @_;

    my $pdbfile_is_mine;
    my $pdbfile2;
    my $asafile;
    my $rsafile;
    my $logfile;
    my $errfile;
    my $cmd;
    my $stat;
    my @errors;
    my $type;
    my $id;
    my $fh;
    my $fh2;
    my $state;
    my $resName;
    my $resSeq;
    my $iCode;
    my $cid;
    my $aa;
    my $acc;
    my $acc_s;
    my $id_dom;
    my $cid_dom;
    my $resSeq_dom;
    my $iCode_dom;
    my $naccess_residues;
    my @F;

    $z = defined($z) ? sprintf("%.02f", $z) : '0.05';

    if(defined($pdbfile)) {
        $pdbfile_is_mine = 0;
        if($pdbfile !~ /\.pdb\Z/) {
            # naccess requires the suffix '.pdb' on the pdb file name
            if($pdbfile !~ /\.\S+\Z/) {
                $pdbfile2 = $pdbfile . '.pdb';
            }
            else {
                $pdbfile2 =~ s/\.\S+\Z/.pdb/;
            }
            $self->mysystem("cp $pdbfile $pdbfile2");
            $pdbfile = $pdbfile2;
        }
    }
    else {
        $pdbfile_is_mine = 1;
        ($pdbfile, $res_mapping) = $self->write_pdbfile(undef, '.pdb');
    }

    defined($pdbfile) or return(undef);

    # naccess generates output file names based on the given pdb file name
    ($asafile = $pdbfile) =~ s/\.\S+\Z/.asa/;
    ($rsafile = $pdbfile) =~ s/\.\S+\Z/.rsa/;
    ($logfile = $pdbfile) =~ s/\.\S+\Z/.log/;

    # run naccess
    $errfile = File::Temp->new(DIR => $self->tempdir, UNLINK => $self->cleanup);

    $cmd = $self->tempdir;

    #$cmd = sprintf "cd $cmd; naccess -h $pdbfile 1> /dev/null 2> $errfile";
    # where:
    # - 'cd' because naccess generates files in the cwd
    # - '-h' to include heteroatoms

    # the naccess bash helper script blocks when several instances
    # are running simultaneously... so doing this part myself
    $cmd = sprintf "cd $cmd; printf \"PDBFILE $pdbfile\nVDWFILE $fn_vdw\nSTDFILE $fn_std\nPROBE 1.40\nZSLICE $z\nHETATOMS\n\" | accall 1> /dev/null 2> $errfile";

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

    # parse rsa file
    if(!open($fh, $rsafile)) {
        Carp::cluck("cannot open '$rsafile' for reading.");
        return undef;
    }
    $state = 'header';
    $naccess_residues = [];
    while(<$fh>) {
        # REM  File of summed (Sum) and % (per.) accessibilities for 
        # REM RES _ NUM      All-atoms   Total-Side   Main-Chain    Non-polar    All polar
        # REM                ABS   REL    ABS   REL    ABS   REL    ABS   REL    ABS   REL
        #
        # 123 124 112341 123456712345612345671234561234567
        #
        # RES SER A 201   150.84 129.5  95.61 122.4  55.24 143.8  61.35 126.4  89.49 131.7
        # RES TPO A 202   213.15 -99.9 126.35 -99.9  86.81 -99.9 108.53 -99.9 104.63 -99.9
        # RES TYR A 203   160.34  75.4 146.00  82.3  14.35  40.5 127.43  93.4  32.91  43.2
        # RES PRO A 204   101.82  74.8  91.12  76.0  10.70  65.9  93.87  77.6   7.95  52.3
        # RES HIS A 205   104.47  57.1  88.29  60.0  16.18  45.2  60.40  62.2  44.07  51.4
        # RES SEP A 206    97.82 -99.9  28.96 -99.9  68.85 -99.9  33.57 -99.9  64.25 -99.9
        # RES PRO A 207   137.78 101.2 105.44  87.9  32.34 199.3 107.54  88.9  30.24 199.1
        # RES THR A 208   140.16 100.6 133.62 131.4   6.54  17.4 105.38 139.2  34.78  54.7
        # RES SER A 209   140.95 121.0  45.23  57.9  95.72 249.3  46.90  96.6  94.05 138.4
	if(s/^RES \S{3} (.)(.{4})(.)\s(.{7}).{6}(.{7})//) {
            ($cid, $resSeq, $iCode, $acc, $acc_s) = ($1, $2, $3, $4, $5);
            $cid =~ s/\s+//g;
            $resSeq =~ s/\s+//g;
            $iCode =~ s/\s+//g;
            $acc =~ s/\s+//g;
            $acc_s =~ s/\s+//g;

            if(defined($res_mapping->{$cid}->{$resSeq}->{$iCode})) {
                ($id_dom, $cid_dom, $resSeq_dom, $iCode_dom) = @{$res_mapping->{$cid}->{$resSeq}->{$iCode}};
                push @{$naccess_residues}, [$id_dom, $cid_dom, $resSeq_dom, $iCode_dom, $acc, $acc_s];
            }
            else {
                Carp::cluck(join('-', $self->id, $cid, $resSeq, $iCode, "no mapping to original domain identifiers"));
                next;
            }
	}
    }
    close($fh);

    if($self->cleanup) { # these files were not created by File::Temp
        unlink($asafile);
        unlink($rsafile);
        unlink($logfile);
    }

    return $naccess_residues;
}

1;
