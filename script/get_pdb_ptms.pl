#!/usr/bin/perl -w

use strict;

my @F;

use Fist::Schema;
use Dir::Self;
use Config::General;
use Fist::NonDB::Site;

my $modified_residues = {
                         SEP => {res => 'S', type => 'phosphorylation'},
                         TPO => {res => 'T', type => 'phosphorylation'},
                         PTR => {res => 'Y', type => 'phosphorylation'},
                         ALY => {res => 'K', type => 'acetylation'},
                        };

my $conf;
my $config;
my $schema;
my $dbh;
my $query;
my $sth;
my $table;
my $row;
my $frags;
my $frag;

my $id_frag;
my $idcode;
my $id_fist_seq;
my $id_uniprot_seq;
my $id_aln;
my $fist;
my $chain;
my $resseq;
my $icode,
my $modified_res;

my @fist_posns;
my $fist_pos;
my $apos;
my $uniprot_pos;
my $aln;
my $uniprot_res;
my $uniprot_seq;
my $fist_res;
my $type;
my $site;

$conf = Config::General->new(__DIR__ . "/../fist.conf");
%{$config} = $conf->getall;
$schema = Fist::Schema->connect($config->{"Model::FistDB"}->{connect_info}->{dsn}, $config->{"Model::FistDB"}->{connect_info}->{user}, $config->{"Model::FistDB"}->{connect_info}->{password});
$dbh = $schema->storage->dbh;

$query = sprintf "rm.res3 IN ('%s')", join("', '", keys %{$modified_residues});
$query = <<END;
SELECT a.id_frag,
       a.idcode,
       b.id_fist_seq,
       b.id_uniprot_seq,
       b.id_aln,
       a.fist,
       a.chain,
       a.resseq,
       a.icode,
       a.res3
FROM   (
        SELECT f.id                           id_frag,
               f.idcode                       idcode,
               frm.fist                       fist,
               frm.chain                      chain,
               frm.resseq                     resseq,
               REPLACE(frm.icode, "\0", "_")  icode,
               rm.res3                        res3
        FROM   Frag           AS f,
               FragResMapping AS frm,
               ResMapping     AS rm
        WHERE  frm.id_frag = f.id
        AND    rm.idcode = f.idcode
        AND    rm.chain = frm.chain
        AND    rm.resseq = frm.resseq
        AND    rm.icode = frm.icode
        AND    $query

        #AND    f.idcode = '3ifq'
       ) AS a

       LEFT JOIN

       (
        SELECT f.id           id_frag,
               s1.id          id_fist_seq,
               s2.id          id_uniprot_seq,
               a_to_g.id_aln  id_aln

        FROM   Frag             AS f,
               FragToSeqGroup   AS f_to_g,
               SeqGroup         AS g,
               AlignmentToGroup AS a_to_g,

               SeqToGroup       AS s1_to_g,
               Seq              AS s1,

               SeqToGroup       AS s2_to_g,
               Seq              AS s2

        WHERE  f_to_g.id_frag = f.id
        AND    g.id = f_to_g.id_group
        AND    g.type = 'frag'
        AND    a_to_g.id_group = g.id

        AND    s1_to_g.id_group = g.id
        AND    s1.id = s1_to_g.id_seq
        AND    s1.source = 'fist'

        AND    s2_to_g.id_group = g.id
        AND    s2.id = s2_to_g.id_seq
        AND    s2.source = 'uniprot-sprot'

        #AND    f.idcode = '3ifq'
       ) AS b

       ON b.id_frag = a.id_frag
END
$sth = $dbh->prepare($query);
$sth->execute;
$table = $sth->fetchall_arrayref;
$frags = {};
foreach $row (@{$table}) {
    (
     $id_frag,
     $idcode,
     $id_fist_seq,
     $id_uniprot_seq,
     $id_aln,
     $fist,
     $chain,
     $resseq,
     $icode,
     $modified_res,
    ) = @{$row};


    if(!defined($frag = $frags->{$id_frag})) {
        $frag = {
                 id             => $id_frag,
                 idcode         => $idcode,
                 id_fist_seq    => $id_fist_seq,
                 id_uniprot_seq => $id_uniprot_seq,
                 id_aln         => $id_aln,
                 fist_posns     => {},
                };
        $frags->{$id_frag} = $frag;
    }
    $frag->{fist_posns}->{$fist} = [$chain, $resseq, $icode, $modified_res];
}

foreach $frag (sort {$a->{id} <=> $b->{id}} values %{$frags}) {
    @fist_posns = sort {$a <=> $b} keys %{$frag->{fist_posns}};
    if(@fist_posns > 0) {
        if(!defined($id_uniprot_seq = $frag->{id_uniprot_seq})) {
            warn '# no uniprot sequence for frag ', $frag->{id}, '.';
            next;
        }

        if(!defined($id_fist_seq = $frag->{id_fist_seq})) {
            warn '# no fist sequence for frag ', $frag->{id}, '.';
            next;
        }

        $aln = $schema->resultset('Alignment')->search({id => $frag->{id_aln}})->first;

        foreach $fist_pos (@fist_posns) {
            ($chain, $resseq, $icode, $modified_res) = @{$frag->{fist_posns}->{$fist_pos}};

            # what residue type has been modified?
            if(defined($modified_residues->{$modified_res})) {
                $fist_res = $modified_residues->{$modified_res}->{res};
                $type = $modified_residues->{$modified_res}->{type};
            }
            else {
                warn "Error: do not recognise modified residue '$modified_res'.";
                next;
            }

            # fist pos -> aln pos
            if(!defined($apos = $aln->apos_from_pos($id_fist_seq, $fist_pos))) {
                warn "# no apos for fist pos $fist_pos in sequence $id_fist_seq alignment $id_aln.";
                next;
            }

            # aln pos -> uniprot pos
            if(!defined($uniprot_pos = $aln->pos_from_apos($id_uniprot_seq, $apos))) {
                warn "# no pos for apos $apos in sequence $id_uniprot_seq alignment $id_aln.";
                next;
            }

            # check that residue at this position is as expected
            $uniprot_seq = $schema->resultset('Seq')->search({id => $frag->{id_uniprot_seq}})->first;
            $uniprot_res = substr($uniprot_seq->seq, $uniprot_pos - 1, 1);
            if($uniprot_res ne $fist_res) {
                warn "# uniprot $uniprot_res$uniprot_pos is not the same residue as fist $fist_res$fist_pos ($modified_res) for fist seq $id_fist_seq, uniprot_seq $id_uniprot_seq.";
                next;
            }

            # create and output a new Site
            $site = Fist::NonDB::Site->new(
                                           source      => 'pdb',
                                           type        => $type,
                                           seq         => $uniprot_seq,
                                           pos         => $uniprot_pos,
                                           res1        => $uniprot_res,
                                           res2        => $uniprot_res,
                                           description => sprintf("PDB %s %s%s%s %s", $frag->{idcode}, $chain, $resseq, $icode, $modified_res),
                                          );
            $site->output_tsv(\*STDOUT);
        }
    }
}
