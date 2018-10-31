#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Dir::Self;
use Config::General;
use Carp;
use Fist::Schema;
use Fist::Utils::Overlap;

# options
my $help;
my $ids_contacts = [];
my $sources = [];

# other variables
my $sources_str;
my $conf;
my $config;
my $schema;
my $dbh;
my $query;
my $sth;
my $sth_fist;
my $sth_feat;
my $table;
my $table_fist;
my $feat_insts1;
my $feat_inst1;
my $feat_insts2;
my $feat_inst2;
my $row;
my $row_fist;
my $id_contact;
my $id_frag1;
my $id_frag_inst1;
my $id_frag2;
my $id_frag_inst2;
my $start_fist1;
my $end_fist1;
my $start_fist2;
my $end_fist2;
my $ac_feat1;
my $ac_feat2;
my $fists1;
my $fist1;
my $fists2;
my $fist2;
my $resres;
my $resres2;
my $n_resres;
my $n_resres_feat;
my $n;
my $t;
my $id_feat_contact;

# parse command line
GetOptions(
	   'help'     => \$help,
           'id=i'     => $ids_contacts,
           'source=s' => $sources,
	  );

defined($help) and usage();
(@{$sources} > 0) or usage('--source required');

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option        parameter  description                     default
------------  ---------  ------------------------------  -------
--help        [none]     print this usage info and exit
--id [1]      integer    id of contact                   [all]
--source [1]  string     source of features              [none]

1 - these options can be used more than once

END

    die $usage;
}

$sources_str = join "', '", @{$sources};

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$dbh = $schema->storage->dbh;

if(@{$ids_contacts} == 0) {
    $query = 'SELECT id FROM Contact WHERE isa_group IS FALSE';
    $sth = $dbh->prepare($query);
    $sth->execute;
    $table = $sth->fetchall_arrayref;
    foreach $row (@{$table}) {
        push @{$ids_contacts}, $row->[0];
    }
}

#printf "n_ids = %d\n", scalar @{$ids_contacts};
#die;

$query = <<END;
SELECT fi1.id_frag,
       c.id_frag_inst1,
       fi2.id_frag,
       c.id_frag_inst2,
       frm1.fist,
       frm2.fist

FROM   Contact        AS c,
       ResContact     AS rc,
       FragInst       AS fi1,
       FragInst       AS fi2,
       FragResMapping AS frm1,
       FragResMapping AS frm2

WHERE  c.id = ?

AND    rc.id_contact = c.id
AND    fi1.id = c.id_frag_inst1
AND    fi2.id = c.id_frag_inst2

AND    frm1.id_frag = fi1.id_frag
AND    frm1.chain = rc.chain1
AND    frm1.resseq = rc.resseq1
AND    frm1.icode = rc.icode1

AND    frm2.id_frag = fi2.id_frag
AND    frm2.chain = rc.chain2
AND    frm2.resseq = rc.resseq2
AND    frm2.icode = rc.icode2
END
$sth_fist = $dbh->prepare($query);

$query = <<END;
SELECT feati.id,
       feati.start_seq,
       feati.end_seq
FROM   FragToSeqGroup AS f_to_g,
       SeqGroup       AS g,
       SeqToGroup     AS s_to_g,
       Seq            AS s,
       FeatureInst    AS feati,
       Feature        AS feat
WHERE  f_to_g.id_frag = ?
AND    g.id = f_to_g.id_group
AND    g.type = 'frag'
AND    s_to_g.id_group = g.id
AND    s.id = s_to_g.id_seq
AND    s.source = 'fist'
AND    feati.id_seq = s.id
AND    feat.id = feati.id_feature
AND    feat.source IN ('$sources_str')
END
$sth_feat = $dbh->prepare($query);

$t = scalar @{$ids_contacts};
$n = 0;
$id_feat_contact = 0;
foreach $id_contact (@{$ids_contacts}) {
    #printf "# %d / %d (%.2f%%)\n", ++$n, $t, 100 * $n / $t;

    $sth_fist->execute($id_contact);
    $table_fist = $sth_fist->fetchall_arrayref;

    $fists1 = [];
    $fists2 = [];
    $resres = {};
    foreach $row_fist (@{$table_fist}) {
        #print join("\t", @{$row_fist}), "\n";
        ($id_frag1, $id_frag_inst1, $id_frag2, $id_frag_inst2, $fist1, $fist2) = @{$row_fist};

        $resres->{$fist1}->{$fist2}++;
        push @{$fists1}, $fist1;
        push @{$fists2}, $fist2;
    }
    #print join("\t", '# frags', $id_frag1, $id_frag2), "\n";

    # sort resres now to avoid multiple sorts later
    $resres2 = [];
    foreach $fist1 (sort {$a <=> $b} keys %{$resres}) {
        push @{$resres2}, [$fist1, sort {$a <=> $b} keys %{$resres->{$fist1}}];
    }
    $resres = $resres2;

    ((@{$fists1} > 0) and (@{$fists2} > 0)) or next;

    $fists1 = [sort {$a <=> $b} @{$fists1}];
    $start_fist1 = $fists1->[0];
    $end_fist1 = $fists1->[$#{$fists1}];

    $fists2 = [sort {$a <=> $b} @{$fists2}];
    $start_fist2 = $fists2->[0];
    $end_fist2 = $fists2->[$#{$fists2}];

    #print join("\t", '# fist_pos', $start_fist1, $end_fist1, $start_fist2, $end_fist2), "\n";

    $feat_insts1 = feature_overlaps($sth_feat, $id_frag1, $start_fist1, $end_fist1);
    $feat_insts2 = (($id_frag2 == $id_frag1) and ($start_fist2 == $start_fist1) and ($end_fist2 == $end_fist1))? $feat_insts1 : feature_overlaps($sth_feat, $id_frag2, $start_fist2, $end_fist2);

    #print join("\t", '# n_feat_insts', scalar @{$feat_insts1}, scalar @{$feat_insts2}), "\n";

    if((@{$feat_insts1} > 0) and (@{$feat_insts2} > 0)) {
        foreach $feat_inst1 (@{$feat_insts1}) {
            foreach $feat_inst2 (@{$feat_insts2}) {
                #$n_resres = n_resres($resres);
                $n_resres_feat = n_resres_feat($feat_inst1->{start_seq}, $feat_inst1->{end_seq}, $feat_inst2->{start_seq}, $feat_inst2->{end_seq}, $resres);
                ($n_resres_feat == 0) and next;

                print(
                      join(
                           "\t",
                           ++$id_feat_contact,

                           $id_frag_inst1,
                           $id_frag_inst2,

                           $feat_inst1->{id},
                           $feat_inst2->{id},

                           $n_resres_feat,
                          ),
                      "\n",
                     );
            }
        }
    }
}

sub feature_overlaps {
    my($sth, $id_frag, $start_fist, $end_fist) = @_;

    my $overlaps;
    my $table;
    my $row;
    my $id_feati;
    my $start_seq;
    my $end_seq;
    my $overlap;

    $sth->execute($id_frag);
    $overlaps = [];
    $table = $sth->fetchall_arrayref();
    #printf "# table_size = %d\n", scalar @{$table};
    foreach $row (@{$table}) {
        ($id_feati, $start_seq, $end_seq) = @{$row};
        $overlap = Fist::Utils::Overlap->new(start1 => $start_fist, end1 => $end_fist, start2 => $start_seq, end2 => $end_seq);

        #print join("\t", '# overlap', $start_fist, $end_fist, $start_seq, $end_seq, $overlap->overlap), "\n";

        if($overlap->overlap > 0) {
            push @{$overlaps}, {id => $id_feati, start_seq => $start_seq, end_seq => $end_seq, overlap => $overlap->overlap};
        }
    }

    return $overlaps;
}

sub n_resres {
    my($resres) = @_;

    my $n_resres;
    my $ref;
    my $row;
    my $fist1;

    $n_resres = 0;
    $ref = ref $resres;
    if($ref eq 'ARRAY') {
        foreach $row (@{$resres}) {
            $n_resres += (scalar(@{$row}) - 1); # '-1' because the first element gives fist1 position. Remaining elements give the fist2 positions with which it interacts
        }
    }
    elsif($ref eq 'HASH') {
        foreach $fist1 (keys %{$resres}) {
            $n_resres += scalar(keys(%{$resres->{$fist1}}));
        }
    }
    else {
        warn "Error: n_resres: cannot count resres type '$ref'.";
    }

    return $n_resres;
}

sub n_resres_feat {
    my($start1, $end1, $start2, $end2, $resres) = @_;

    my $n_resres_feat;
    my $ref;
    my $row;
    my $idx;
    my $fist1;
    my $fist2;

    $n_resres_feat = 0;
    $ref = ref $resres;
    if($ref eq 'ARRAY') {
        foreach $row (@{$resres}) {
            $fist1 = $row->[0];
            ($fist1 > $end1) and last;
            ($fist1 < $start1) and next;

            foreach $fist2 (@{$row}[1..$#{$row}]) {
                ($fist2 > $end2) and last;
                ($fist2 < $start2) and next;

                $n_resres_feat++;
            }
        }
    }
    elsif($ref eq 'HASH') {
        foreach $fist1 (sort {$a <=> $b} keys %{$resres}) {
            ($fist1 > $end1) and last;
            ($fist1 < $start1) and next;

            foreach $fist2 (sort {$a <=> $b} keys %{$resres->{$fist1}}) {
                ($fist2 > $end2) and last;
                ($fist2 < $start2) and next;

                $n_resres_feat++;
            }
        }
    }
    else {
        warn "Error: n_resres_feat: cannot count resres type '$ref'.";
    }

    return $n_resres_feat;
}
