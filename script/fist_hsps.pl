#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Dir::Self;
use Config::General;
use Fist::Schema;

# options
my $help;
my $min_n_resres_default = 30;
my $min_n_resres = $min_n_resres_default;
my $dn_out_default = './data/';
my $dn_out = $dn_out_default;

# other variables
my $conf;
my $config;
my $schema;
my $seqs;
my $hsps;
my $contacts;

# parse command line
GetOptions(
	   'help'         => \$help,
           'min_resres=i' => \$min_n_resres,
           'outdir=s'     => \$dn_out,
	  );

defined($help) and usage();
($min_n_resres < 1) and ($min_n_resres = 1);

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option        parameter  description                                                 default
------------  ---------  ----------------------------------------------------------  -------
--help        [none]     print this usage info and exit
--min_resres  integer    minimum number of residues pairs per contact (must be > 0)  $min_n_resres_default
--outdir      string     directory for output files                                  $dn_out_default

END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

(-e $dn_out) or make_path($dn_out);
$dn_out = abs_path($dn_out) . '/';

$seqs = get_seqs($schema);
group_idseqs($schema, $seqs, $dn_out);
$hsps = inter_idseq_hsps($schema, $seqs, $dn_out);
$contacts = get_contacts($schema, $min_n_resres, $seqs);
get_contact_hsp_links($contacts, $hsps);

# FIXME - calculate jaccard indices within idseq groups

# FIXME - calculate jaccard indices between idseq groups
# - could group idseq groups by jaccard == 1 to reduce the number of calculations,
# but then would have to wait for the intra group jaccards to be calculated


sub get_seqs {
    my($schema) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $seqs;

    $dbh = $schema->storage->dbh;

    # get fist sequence ids
    $query = <<END;
SELECT id
FROM   Seq
WHERE  source = 'fist'
AND    chemical_type = 'peptide'
END
    $sth = $dbh->prepare($query);
    $sth->{mysql_use_result} = 1;
    $sth->execute();
    $seqs = {};
    while($row = $sth->fetchrow_arrayref) {
        $seqs->{$row->[0]} = 0; # the id of the seq group, to be set later
        #print "seq\t@{$row}\n";
    }
    print '# n_seqs = ', scalar keys %{$seqs}, "\n";

    return $seqs;
}

sub group_idseqs {
    my($schema, $seqs, $dn_out) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $idseqs;
    my $id_seq1;
    my $id_seq2;
    my $n_idseqs;
    my $n_groups;
    my $id_group;
    my $id_group_p;
    my @members;
    my @queue;
    my $group;

    $dbh = $schema->storage->dbh;

    # get identical sequences and best hsp between each pair of non-identical sequences
    $query = <<END;
SELECT Hsp.id_seq1,
       Hsp.id_seq2

FROM   Hsp,
       Seq AS s1,
       Seq AS s2

WHERE  Hsp.id_seq2 != Hsp.id_seq1

AND    Hsp.pcid >= 99.999999
AND    Hsp.start1 = 1
AND    Hsp.start2 = 1

AND    s1.id = Hsp.id_seq1
AND    s1.source = 'fist'
AND    s1.len = Hsp.end1

AND    s2.id = Hsp.id_seq2
AND    s2.source = 'fist'
AND    s2.len = Hsp.end2

#LIMIT 10
END

    $sth = $dbh->prepare($query);
    $sth->{mysql_use_result} = 1;
    $sth->execute();
    $idseqs = {};
    $n_idseqs = 0;

    while($row = $sth->fetchrow_arrayref) {
        ($id_seq1, $id_seq2) = @{$row};
        $idseqs->{$id_seq1}->{$id_seq2}++;
        ++$n_idseqs;
    }
    print "# n_idseqs = $n_idseqs\n";

    $n_groups = 0;
    $id_group = 0;
    foreach $id_seq1 (keys %{$seqs}) {
        #print "id_seq1\t$id_seq1\n";
        @members = ();
        @queue = ();

        if($seqs->{$id_seq1} == 0) {
            $seqs->{$id_seq1} = ++$id_group;
            while(defined($id_seq1)) {
                foreach $id_seq2 (keys %{$idseqs->{$id_seq1}}) {
                    if($seqs->{$id_seq2} == 0) {
                        $seqs->{$id_seq2} = $id_group;
                        push @queue, $id_seq2;
                    }
                }
                $id_seq1 = shift @queue;
            }
        }
    }
    $n_groups = $id_group;

    $id_group_p = -1;
    $group = [];
    foreach $id_seq1 (sort {$seqs->{$a} <=> $seqs->{$b}} keys %{$seqs}) {
        $id_group = $seqs->{$id_seq1};

        if($id_group != $id_group_p) {
            (@{$group} > 0) and print(join(' ', 'IDSEQS', $id_group_p, sort {$a <=> $b} @{$group}), "\n");
            $group = [];
        }
        push @{$group}, $id_seq1;

        $id_group_p = $id_group;
    }
    (@{$group} > 0) and print(join(' ', 'IDSEQS', $id_group_p, sort {$a <=> $b} @{$group}), "\n");

    print "# n_idseq_groups = $n_groups\n";
}

sub inter_idseq_hsps {
    my($schema, $seqs, $dn_out) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $id_seq1;
    my $start1;
    my $end1;
    my $id_seq2;
    my $start2;
    my $end2;
    my $pcid;
    my $e_value;
    my $id_aln;
    my $id_group1;
    my $id_group2;
    my $hsps;
    my $n_hsps;
    my $n_total_hsps;
    my $dn_sub;

    $dbh = $schema->storage->dbh;

    $query = <<END;
SELECT Hsp.id_seq1,
       Hsp.start1,
       Hsp.end1,

       Hsp.id_seq2,
       Hsp.start2,
       Hsp.end2,

       Hsp.pcid,
       Hsp.e_value,
       Hsp.id_aln

FROM   Hsp,
       Seq AS s1,
       Seq AS s2

WHERE  Hsp.id_seq2 != Hsp.id_seq1

AND    s1.id = Hsp.id_seq1
AND    s1.source = 'fist'

AND    s2.id = Hsp.id_seq2
AND    s2.source = 'fist'

#LIMIT 10
END

    $sth = $dbh->prepare($query);
    $sth->{mysql_use_result} = 1;
    $sth->execute();
    # get the best hsp for each pair of groups of identical sequences
    $n_total_hsps = 0;
    $hsps = {};
    $n_total_hsps = 0;
    while($row = $sth->fetchrow_arrayref) {
        ($id_seq1, $start1, $end1, $id_seq2, $start2, $end2, $pcid, $e_value, $id_aln) = @{$row};
        $id_group1 = $seqs->{$id_seq1};
        $id_group2 = $seqs->{$id_seq2};

        if($id_group1 < $id_group2) { # only need one direction
            if(!defined($hsps->{$id_group1}->{$id_group2}) or ($e_value < $hsps->{$id_group1}->{$id_group2}->[0])) {
                $hsps->{$id_group1}->{$id_group2} = [$id_seq1, $id_seq2, $e_value, $pcid, $id_aln]; # can get everything else via id_aln
            }
        }

        ++$n_total_hsps;
    }

    $n_hsps = 0;
    foreach $id_group1 (keys %{$hsps}) {
        foreach $id_group2 (keys %{$hsps->{$id_group1}}) {
            print join("\t", 'HSP', $id_group1, $id_group2, @{$hsps->{$id_group1}->{$id_group2}}), "\n";
            ++$n_hsps;
        }
    }

    printf "# n_hsps = %d / %d (%.02f%%)\n", $n_hsps, $n_total_hsps, ($n_total_hsps > 0) ? (100 * $n_hsps / $n_total_hsps) : 0;

    return $hsps;
}

sub get_contacts {
    my($schema, $min_n_resres, $seqs) = @_;

    my $dbh;
    my $query;
    my $sth;
    my $row;
    my $id_contact;
    my $id_seq_A;
    my $id_seq_B;
    my $id_group_A;
    my $id_group_B;
    my $contacts;
    my $n_contacts;
    my $contact;

    $dbh = $schema->storage->dbh;

    # get contacts and group by idseq groups
    $query = <<END;
SELECT c.id,
       s1.id,
       s2.id

FROM   Contact        AS c,

       FragInst       AS fi1,
       FragToSeqGroup AS f1_to_sg1,
       SeqGroup       AS sg1,
       SeqToGroup     AS s1_to_sg1,
       Seq            AS s1,

       FragInst       AS fi2,
       FragToSeqGroup AS f2_to_sg2,
       SeqGroup       AS sg2,
       SeqToGroup     AS s2_to_sg2,
       Seq            AS s2

WHERE  c.isa_group        IS FALSE
AND    c.n_clash          = 0
AND    c.n_resres         >= $min_n_resres

AND    fi1.id             = c.id_frag_inst1
AND    f1_to_sg1.id_frag  = fi1.id_frag
AND    sg1.id             = f1_to_sg1.id_group
AND    sg1.type           = 'frag'
AND    s1_to_sg1.id_group = sg1.id
AND    s1.id              = s1_to_sg1.id_seq
AND    s1.source          = 'fist'

AND    fi2.id             = c.id_frag_inst2
AND    f2_to_sg2.id_frag  = fi2.id_frag
AND    sg2.id             = f2_to_sg2.id_group
AND    sg2.type           = 'frag'
AND    s2_to_sg2.id_group = sg2.id
AND    s2.id              = s2_to_sg2.id_seq
AND    s2.source          = 'fist'

#LIMIT 10
END
    $sth = $dbh->prepare($query);
    $sth->{mysql_use_result} = 1;
    $sth->execute();
    $contacts = {};
    $n_contacts = 0;
    while($row = $sth->fetchrow_arrayref) {
        ($id_contact, $id_seq_A, $id_seq_B) = @{$row};

        if(!defined($id_group_A = $seqs->{$id_seq_A})) {
            warn "Error: no group for seq $id_seq_A\n";
            next;
        }

        if(!defined($id_group_B = $seqs->{$id_seq_B})) {
            warn "Error: no group for seq $id_seq_B\n";
            next;
        }

        $contacts->{$id_group_A}->{$id_group_B}->{$id_contact}++;
        ++$n_contacts;
    }
    print "# n_contacts = $n_contacts\n";

    foreach $id_group_A (sort {$a <=> $b} keys %{$contacts}) {
        foreach $id_group_B (sort {$a <=> $b} keys %{$contacts->{$id_group_A}}) {
            print join(' ', 'CONTACTS', $id_group_A, $id_group_B, sort {$a <=> $b} keys %{$contacts->{$id_group_A}->{$id_group_B}}), "\n";
        }
    }

    return $contacts;
}

sub get_contact_hsp_links {
    my($contacts, $hsps) = @_;

    my $id_group_A1;
    my $hspA;
    my $id_group_B1;
    my $hspB;
    my $contacts1;
    my $id_group_A2;
    my $id_group_B2;
    my $contacts2;
    my $visited;

    $visited = {};
    foreach $id_group_A1 (keys %{$contacts}) {
        defined($hsps->{$id_group_A1}) or next;
        foreach $id_group_B1 (keys %{$contacts->{$id_group_A1}}) {
            defined($hsps->{$id_group_B1}) or next;

            $contacts1 = $contacts->{$id_group_A1}->{$id_group_B1};

            foreach $id_group_A2 (keys %{$hsps->{$id_group_A1}}) {
                defined($contacts->{$id_group_A2}) or next;

                $hspA = $hsps->{$id_group_A1}->{$id_group_A2};

                foreach $id_group_B2 (keys %{$hsps->{$id_group_B1}}) {
                    defined($contacts2 = $contacts->{$id_group_A2}->{$id_group_B2}) or next;

                    $hspB = $hsps->{$id_group_B1}->{$id_group_B2};

                    # FIXME - only store the pairs of pairs of groups in one direction?

                    print(
                          join(
                               "\t",
                               'HSPS',
                               $id_group_A1,
                               $id_group_B1,
                               $id_group_A2,
                               $id_group_B2,
                               @{$hspA},
                               @{$hspB},
                              ),
                          "\n",
                         );
                }
            }
        }
    }
}
