#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use Dir::Self;
use Config::General;
use Fist::Schema;
use Fist::Utils::Overlap;

# options
my $help;
my $tolerance = 0.000001;
my $lf_default = 1;
my $lf = $lf_default;
my $pcid_default = 100;
my $pcid = $pcid_default;
my $same_frag_default = 0;
my $same_frag = $same_frag_default;
my $aln_jaccard_default = 1;
my $aln_jaccard = $aln_jaccard_default;
my $full_jaccard_default = 1;
my $full_jaccard = $full_jaccard_default;
my $min_n_resres_default = 30;
my $min_n_resres = $min_n_resres_default;

# other variables
my $conf;
my $config;
my $schema;
my $dbh;
my $sth;
my $query;
my $row;
my $frags;
my $frag_insts;
my $frag_to_seq;
my $id_parent;
my $id_child;

# parse command line
GetOptions(
	   'help'           => \$help,
           'lf=f'           => \$lf,
           'pcid=f'         => \$pcid,
           'same_frag=i'    => \$same_frag,
           'aln_jaccard=f'  => \$aln_jaccard,
           'full_jaccard=f' => \$full_jaccard,
           'min_resres=i'   => \$min_n_resres,
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

option          parameter  description                                                default
--------------  ---------  ---------------------------------------------------------  -------
--help          [none]     print this usage info and exit
--min_resres    integer    minimum number of residue pairs per contact (must be > 0)  $min_n_resres_default
--lf            float      length fraction                                            $lf_default
--pcid          float      percentage identity                                        $pcid_default
--same_frag     integer    groups are of same fragments or not                        $same_frag_default
--aln_jaccard   float      aligned jaccard index                                      $aln_jaccard_default
--full_jaccard  float      full jaccard index                                         $full_jaccard_default

END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});

$dbh = $schema->storage->dbh;

$frags = {};
$query = 'SELECT f.id, f.idcode, f.dom FROM Frag AS f';
$sth = $dbh->prepare($query);
$sth->execute;
while($row = $sth->fetchrow_arrayref) {
    $frags->{$row->[0]} = {id => $row->[0], idcode => $row->[1], dom => $row->[2]};
}

$frag_insts = {};
$query = 'SELECT fi.id, fi.assembly, fi.model, fi.id_frag FROM FragInst AS fi';
$sth = $dbh->prepare($query);
$sth->execute;
while($row = $sth->fetchrow_arrayref) {
    $frag_insts->{$row->[0]} = {
                                id       => $row->[0],
                                id_frag  => $row->[3],
                                fn       => pdb_fn($frags->{$row->[3]}->{idcode}, $row->[1], $row->[2]),
                               };
}

$frag_to_seq = {};
$query = <<END;
SELECT f_to_g.id_frag,
       s.id
FROM   FragToSeqGroup AS f_to_g,
       SeqGroup       AS g,
       SeqToGroup     AS s_to_g,
       Seq            AS s
WHERE  g.id = f_to_g.id_group
AND    g.type = 'frag'
AND    s_to_g.id_group = g.id
AND    s.id = s_to_g.id_seq
AND    s.source = 'fist'
END
$sth = $dbh->prepare($query);
$sth->execute;
while($row = $sth->fetchrow_arrayref) {
    $frag_to_seq->{$row->[0]} = $row->[1];
}

$query = <<END;
SELECT parent.id,
       parent.id_frag_inst1,
       parent.id_frag_inst2,

       child.id,
       child.id_frag_inst1,
       child.id_frag_inst2

FROM   Contact       AS parent,
       ContactMember AS member,
       Contact       AS child

WHERE  parent.isa_group IS TRUE
AND    parent.lf BETWEEN $lf - $tolerance AND $lf + $tolerance
AND    parent.pcid BETWEEN $pcid - $tolerance AND $pcid + $tolerance
AND    parent.same_frag = $same_frag
AND    parent.aln_jaccard BETWEEN $aln_jaccard - $tolerance AND $aln_jaccard + $tolerance
AND    parent.full_jaccard BETWEEN $full_jaccard - $tolerance AND $full_jaccard + $tolerance

AND    member.id_parent = parent.id

AND    child.id = member.id_child
AND    child.isa_group IS FALSE
END

$sth = $dbh->prepare($query);
$sth->{mysql_use_result} = 0;
$sth->execute;
$id_parent = 0;
$id_child = 0;
while($row = $sth->fetchrow_arrayref) {
    if($row->[0] != $id_parent) {
        # new contact group
        print '%% group id = ', $row->[0], ', jaccard = ', $full_jaccard, "\n";
        output_dom($frag_insts->{$row->[1]}, $frag_insts->{$row->[2]}, $frag_to_seq, $frags);
    }

    if($row->[3] != $id_child) {
        # new contact
        print '%% contact id = ', $row->[3], "\n";
        output_dom($frag_insts->{$row->[4]}, $frag_insts->{$row->[5]}, $frag_to_seq, $frags);
    }

    $id_parent = $row->[0];
    $id_child = $row->[3];
}

sub output_dom {
    my(
       $frag_inst1,
       $frag_inst2,
       $frag_to_seq,
       $frags,
      ) = @_;

    my $id_seq1;
    my $id_seq2;
    my $fn1;
    my $fn2;

    if(!defined($id_seq1 = $frag_to_seq->{$frag_inst1->{id_frag}})) {
        warn 'Error: no seq for frag ', $frag_inst1->{id_frag}, '.';
        return 0;
    }

    if(!defined($id_seq2 = $frag_to_seq->{$frag_inst2->{id_frag}})) {
        warn 'Error: no seq for frag ', $frag_inst2->{id_frag}, '.';
        return 0;
    }

    printf(
           "%s %s-%d-%d-%d { %s }\n%s %s-%d-%d-%d { %s }\n",

           $frag_inst1->{fn},
           $frags->{$frag_inst1->{id_frag}}->{idcode},
           $frag_inst1->{id_frag},
           $frag_inst1->{id},
           $id_seq1,
           $frags->{$frag_inst1->{id_frag}}->{dom},

           $frag_inst2->{fn},
           $frags->{$frag_inst2->{id_frag}}->{idcode},
           $frag_inst2->{id_frag},
           $frag_inst2->{id},
           $id_seq2,
           $frags->{$frag_inst2->{id_frag}}->{dom},
          );
}

sub pdb_fn {
    my($idcode, $assembly, $model) = @_;

    my $fn;

    $fn = 'UNK';

    if($ENV{'DS'}) {
        if($assembly == 0) {
            $fn = sprintf "%s/pdb/%s/pdb%s.ent.gz", $ENV{DS}, substr($idcode, 1, 2), $idcode;
        }
        else {
            $fn = sprintf "%s/pdb-biounit/%s/%s-%s-%s.pdb.gz", $ENV{DS}, substr($idcode, 1, 2), $idcode, $assembly, $model;
        }
    }

    return $fn;
}
