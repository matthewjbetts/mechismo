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
my $min_lf_fist_default = 0.0;
my $min_lf_fist = $min_lf_fist_default;
my $ids = [];
my $sources = [];
my $taxa = [];

# other variables
my $conf;
my $config;
my $schema;
my $dbh;
my $query;
my $sth_seq;
my $sth_sifts;
my $sth_blast_fist;
my $sth_blast_seqres;
my $sth_pfam;

my $seqs;
my $seq;
my $row;
my $seq1;
my $seq2;

# parse command line
GetOptions(
	   'help'     => \$help,
           'id=i'     => $ids,
           'source=s' => $sources,
           'taxon=i'  => $taxa,
	  );

defined($help) and usage();

(@{$ids} > 0) or (@{$sources} > 0) or (@{$taxa} > 0) or usage("at least one of --id, --source or --taxon required");

sub usage {
    my($msg) = @_;

    my $prog;
    my $usage;

    ($prog = __FILE__) =~ s/.*\///;

    defined($msg) and warn("\nUsage problem: $msg\n");

    $usage = <<END;

Usage: $prog [options]

option          parameter  description                     default
--------------  ---------  ------------------------------  -------
--help          [none]     print this usage info and exit
--id [1]        integer    fist db sequence identifier     [all sequences with chemical_type = peptide]
--source [1,2]  string     source of sequences             [all sources]
--taxon [1,2]   integer    NCBI taxon ID of sequences      [all taxa]

1 - these options can be used more than once
2 - ignored if --id used

END

    die $usage;
}

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
#$schema->disable_query_cache;
$dbh = $schema->storage->dbh;

# uniprot to fist via sifts
$query = <<END;
SELECT a_to_g.id_aln,     # 00

       100.0,             # 01
       0,                 # 02
       0,                 # 03

       s1.id,             # 04
       s2.id,             # 05

       s1.len,            # 06 - len s1
       1,                 # 07 - start s1 # FIXME - take in to account N-terminal overhang
       s1.len,            # 08 - end s1   # FIXME - take in to account C-terminal overhang
       as1._edit_str,     # 09            # FIXME - take in to account N and C-terminal overhang

       s2.len,            # 10 - len s2
       1,                 # 11 - start s2 # FIXME - take in to account N-terminal overhang
       s2.len,            # 12 - end s2   # FIXME - take in to account C-terminal overhang
       as2._edit_str,     # 13            # FIXME - take in to account N and C-terminal overhang

       'sifts',           # 14
       ''                 # 15

FROM   Seq              AS s1,
       SeqToGroup       AS s1_to_g,
       SeqGroup         AS g,
       SeqToGroup       AS s2_to_g,
       Seq              AS s2,
       AlignmentToGroup AS a_to_g,
       AlignedSeq       AS as1,
       AlignedSeq       AS as2
WHERE  s1.id = ?
AND    s1_to_g.id_seq = s1.id
AND    g.id = s1_to_g.id_group
AND    g.type = 'frag'
AND    s2_to_g.id_group = g.id
AND    s2.id = s2_to_g.id_seq
AND    s2.source = 'fist'
AND    a_to_g.id_group = g.id
AND    as1.id_aln = a_to_g.id_aln
AND    as1.id_seq = s1.id
AND    as2.id_aln = a_to_g.id_aln
AND    as2.id_seq = s2.id
END
$sth_sifts = $dbh->prepare($query);

# uniprot to fist via blast
$query = <<END;
SELECT h.id_aln,

       h.pcid,
       h.score,
       h.e_value,

       s1.id,
       s2.id,

       s1.len,
       h.start1,
       h.end1,
       as1._edit_str,

       s2.len,
       h.start2,
       h.end2,
       as2._edit_str,

       'blast-fist',
       ''

FROM   Seq        AS s1,
       Hsp        AS h,
       Seq        AS s2,
       AlignedSeq AS as1,
       AlignedSeq AS as2

WHERE  s1.id = ?
AND    h.id_seq1 = s1.id
AND    s2.id = h.id_seq2
AND    s2.source = 'fist'
AND    as1.id_aln = h.id_aln
AND    as1.id_seq = s1.id
AND    as2.id_aln = h.id_aln
AND    as2.id_seq = s2.id
END
$sth_blast_fist = $dbh->prepare($query);

# FIXME - uniprot to fist via blast vs seqres
# FIXME - need to get query-fist alignment from query-seqres and seqres-fist alignments

# uniprot to fist via pfam
$query = <<END;
SELECT a_to_g.id_aln,

       0.0, # FIXME - calculate pcid from two aligned sequences
       0,
       GREATEST(fi1.e_value, fi2.e_value),

       s1.id,
       s2.id,

       s1.len,
       fi1.start_seq,
       fi1.end_seq,
       as1._edit_str,

       s2.len,
       fi2.start_seq,
       fi2.end_seq,
       as2._edit_str,

       'pfam',
       f.ac_src

FROM   Seq              AS s1,
       FeatureInst      AS fi1,
       Feature          AS f,
       FeatureInst      AS fi2,
       Seq              AS s2,
       SeqGroup         AS g,
       AlignmentToGroup AS a_to_g,
       AlignedSeq       AS as1,
       AlignedSeq       AS as2

WHERE  s1.id = ?
AND    fi1.id_seq = s1.id
AND    f.id = fi1.id_feature
AND    f.source = 'pfam'
AND    fi2.id_feature = f.id
AND    s2.id = fi2.id_seq
AND    s2.source = 'fist'
AND    g.type = 'pfam'
AND    g.ac = f.ac_src
AND    a_to_g.id_group = g.id
AND    as1.id_aln = a_to_g.id_aln
AND    as1.id_seq = s1.id
AND    as2.id_aln = a_to_g.id_aln
AND    as2.id_seq = s2.id
END
$sth_pfam = $dbh->prepare($query);


# get requested sequences
if(@{$ids} > 0) {
    $query = sprintf "SELECT id, name, primary_id FROM Seq WHERE id IN (%s)", join(',', @{$ids});
}
else {
    if(@{$taxa} > 0) {
        $query = sprintf "SELECT id, name, primary_id FROM Seq AS a, SeqToTaxon AS b WHERE b.id_seq = a.id AND a.source IN ('%s') AND b.id_taxon IN (%s)", join("','", @{$sources}), join(',', @{$taxa});
    }
    else {
        $query = sprintf "SELECT id, name, primary_id FROM Seq WHERE chemical_type = 'peptide' AND source IN ('%s')", join("','", @{$sources});
    }
}
$sth_seq = $dbh->prepare($query);
$sth_seq->{mysql_use_result} = 1;
$sth_seq->execute();
$seqs = [];
while($row = $sth_seq->fetchrow_arrayref) {
    push @{$seqs}, [@{$row}];
}

# get their matches to fist sequences
foreach $seq (@{$seqs}) {
    get_fist_matches($seq, $schema, $min_lf_fist, \&match_order, $sth_sifts, $sth_blast_fist, $sth_pfam);
}

sub match_order {
    my $sources = {
                   'sifts'        => 0,
                   'blast-fist'   => 1,
                   'blast-seqres' => 2,
                   'pfam'         => 3,
                  };
    my $cmp;

    if(($cmp = $sources->{$a->{source}} <=> $sources->{$b->{source}}) == 0) {
        $cmp = $a->{e_value} <=> $b->{e_value};
    }

    return $cmp;
}

sub get_fist_matches {
    my($seq, $schema, $min_lf_fist, $match_order, @sths_matches) = @_;

    my $id_query;
    my $ids_fist;
    my $sth;
    my $table;
    my $row;

    my $id_aln;

    my $pcid;
    my $score;
    my $e_value;

    my $start1;
    my $end1;
    my $len1;
    my $edits1;

    my $id_fist;

    my $start2;
    my $end2;
    my $len2;
    my $edits2;

    my $source;
    my $ac_src;

    my $lf_fist;
    my @sources;
    my $aln;

    $ids_fist = {};

    # get uniprot to fist
    foreach $sth (@sths_matches) {
        $sth->execute($seq->[0]);
        $table = $sth->fetchall_arrayref;
        foreach $row (@{$table}) {
            (
             $id_aln,

             $pcid,
             $score,
             $e_value,

             $id_query,
             $id_fist,

             $len1,
             $start1,
             $end1,
             $edits1,

             $len2,
             $start2,
             $end2,
             $edits2,

             $source,
             $ac_src,
            ) = @{$row};

            #print join("\t", 'RAW', @{$row}), "\n";

            $lf_fist = ($end2 - $start2 + 1) / $len2;
            ($lf_fist >= $min_lf_fist) or next;

            defined($ids_fist->{$id_fist}) or ($ids_fist->{$id_fist} = []);
            push @{$ids_fist->{$id_fist}}, {
                                            id_aln   => $id_aln,

                                            pcid     => $pcid,
                                            score    => $score,
                                            e_value  => $e_value,

                                            id_query => $id_query,
                                            id_fist  => $id_fist,

                                            len1     => $len1,
                                            start1   => $start1,
                                            end1     => $end1,
                                            edits1   => $edits1,

                                            len2     => $len2,
                                            start2   => $start2,
                                            end2     => $end2,
                                            edits2   => $edits2,

                                            source   => $source,
                                            ac_src   => $ac_src,
                                           };
        }
    }

    foreach $id_fist (sort {$a <=> $b} keys %{$ids_fist}) {
        @sources = sort $match_order @{$ids_fist->{$id_fist}};
        #print 'SOURCE';
        #foreach $source (@sources) {
        #    print "\t", $source->{source};
        #}
        #print "\n";
        $source = $sources[0]; # just using the best hit for every fist sequence

        if($source->{source} eq 'pfam') {
            # calculate pcid from aligned sequences
            $aln = $schema->resultset('Alignment')->find({id => $source->{id_aln}});
            $seq1 = $schema->resultset('Seq')->find({id => $source->{id_query}});
            $seq2 = $schema->resultset('Seq')->find({id => $source->{id_fist}});
            $source->{pcid} = $aln->pcid($source->{id_query}, $source->{id_fist}, $seq1, $seq2);
        }

        print(
              join(
                   "\t",
                   $source->{id_aln},

                   $source->{pcid},
                   $source->{score},
                   $source->{e_value},

                   $source->{id_query},
                   $source->{id_fist},

                   $source->{len1},
                   $source->{start1},
                   $source->{end1},
                   $source->{edits1},

                   $source->{len2},
                   $source->{start2},
                   $source->{end2},
                   $source->{edits2},

                   $source->{source},
                  ),
              "\n",
             );
    }
}
