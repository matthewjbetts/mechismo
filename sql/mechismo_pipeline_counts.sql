# - numbers of predicted interactions in uniref groups, at the three different confidence levels

## number of uniprot-sprot sequences
SELECT COUNT(id) n,
       'UniProt'
FROM   Seq
WHERE  source = 'uniprot-sprot'
;


## number of proteins in the eight species of interest
SELECT COUNT(s.id) n,
       CONCAT('Taxon-', t.id),
       t.scientific_name
FROM   Taxon      AS t,
       SeqToTaxon AS s_to_t,
       Seq        AS s
WHERE  t.id IN (272634, 224308, 83333, 559292, 6239, 7227, 10090, 9606)
AND    s_to_t.id_taxon = t.id
AND    s.id = s_to_t.id_seq
AND    s.source = 'uniprot-sprot'
GROUP BY t.id
;


## number of prot-prot and prot-DNA/RNA interactions in pdb/biounit
SELECT COUNT(c.id) n,
       CONCAT(
              REPLACE(REPLACE(f1.chemical_type, 'peptide', 'p'), 'nucleotide', 'd'),
              REPLACE(REPLACE(f2.chemical_type, 'peptide', 'p'), 'nucleotide', 'd')
             ),
       CONCAT(
              REPLACE(REPLACE(f1.chemical_type, 'peptide', 'P'), 'nucleotide', 'D'),
              REPLACE(REPLACE(f2.chemical_type, 'peptide', 'P'), 'nucleotide', 'D'),
              'I'
             )
FROM   Contact  AS c,
       FragInst AS fi1,
       Frag     AS f1,
       FragInst AS fi2,
       Frag     AS f2
WHERE  c.crystal IS FALSE
AND    c.isa_group IS FALSE
AND    fi1.id = c.id_frag_inst1
AND    f1.id = fi1.id_frag
AND    f1.chemical_type = 'peptide'
AND    fi2.id = c.id_frag_inst2
AND    f2.id = fi2.id_frag
AND    f2.chemical_type != 'unknown'
AND    ((f2.chemical_type != 'peptide') OR (fi2.id > fi1.id)) # do not count prot-prot in both directions
GROUP BY f1.chemical_type, f2.chemical_type;

## number of prot-chem interactions in pdb
#DROP TABLE IF EXISTS temp_phc;
#CREATE TABLE temp_phc (
#       id_frag      INTEGER UNSIGNED NOT NULL,
#
#       chem_chain   BINARY(1) NOT NULL,
#       chem_resseq  SMALLINT SIGNED NOT NULL,
#       chem_icode   BINARY(1) NOT NULL,
#       id_chem      CHAR(3) NOT NULL,
#
#       PRIMARY KEY (id_frag, chem_chain, chem_resseq, chem_icode, id_chem)
#);
#
#INSERT IGNORE INTO temp_phc (id_frag, chem_chain, chem_resseq, chem_icode, id_chem)
#
#SELECT f.id,
#       phc.chain2,
#       phc.resseq2,
#       phc.icode2,
#       phc.id_chem
#FROM   Frag              AS f,
#       FragResMapping    AS frm,
#       ProtHetatmContact AS phc
#WHERE  frm.id_frag = f.id
#AND    phc.idcode = f.idcode
#AND    phc.chain1 = frm.chain
#AND    phc.resseq1 = frm.resseq
#AND    phc.icode1 = frm.icode
#;

SELECT COUNT(id_frag) n,
       'pc',
       'PCI'
FROM   temp_phc
;

## NR protein-protein contacts (90% id across 90% of the length, with 90% identical res-res contacts)
SELECT CAST(COUNT(id) / 2 AS UNSIGNED) n,
       'pp90',
       'NR PPI'
FROM   Contact AS c
WHERE  c.isa_group IS TRUE
AND    c.same_frag = 0
AND    c.pcid >= 89.999999
AND    c.pcid <= 90.000001
AND    c.lf >= 0.899999
AND    c.lf < 0.900001
AND    c.full_jaccard >= 0.899999
AND    c.full_jaccard <= 0.900001
;

## NR protein-DNA/RNA
SELECT COUNT(DISTINCT(sg2.id)) n,
       'pd90',
       'NR PDI'
FROM   Contact        AS c,
       FragInst       AS fi1,
       Frag           AS f1,
       FragInst       AS fi2,
       Frag           AS f2,
       FragToSeqGroup AS f1_to_sg1,
       SeqGroup       AS sg1,
       SeqToGroup     AS s1_to_sg1,
       Seq            AS s1,
       SeqToGroup     AS s1_to_sg2,
       SeqGroup       AS sg2
WHERE  c.crystal IS FALSE
AND    c.isa_group IS FALSE
AND    fi1.id = c.id_frag_inst1
AND    f1.id = fi1.id_frag
AND    f1.chemical_type = 'peptide'
AND    fi2.id = c.id_frag_inst2
AND    f2.id = fi2.id_frag
AND    f2.chemical_type = 'nucleotide'
AND    f1_to_sg1.id_frag = f1.id
AND    sg1.id = f1_to_sg1.id_group
AND    sg1.type = 'frag'
AND    s1_to_sg1.id_group = sg1.id
AND    s1.id = s1_to_sg1.id_seq
AND    s1.source = 'fist'
AND    s1_to_sg2.id_seq = s1.id
AND    sg2.id = s1_to_sg2.id_group
AND    sg2.type = 'fist lf=0.9 pcid=90.0'
;

## NR prot-chem group
SELECT COUNT(a.id_group) n,
       'pc90',
       'NR PCI'
FROM
(
SELECT sg2.id  id_group,
       chem.id_chem
FROM   temp_phc       AS phc,
       FragToSeqGroup AS f1_to_sg1,
       SeqGroup       AS sg1,
       SeqToGroup     AS s1_to_sg1,
       Seq            AS s1,
       SeqToGroup     AS s1_to_sg2,
       SeqGroup       AS sg2,
       PdbChem        AS chem
WHERE  f1_to_sg1.id_frag = phc.id_frag
AND    sg1.id = f1_to_sg1.id_group
AND    sg1.type = 'frag'
AND    s1_to_sg1.id_group = sg1.id
AND    s1.id = s1_to_sg1.id_seq
AND    s1.source = 'fist'
AND    s1_to_sg2.id_seq = s1.id
AND    sg2.id = s1_to_sg2.id_group
AND    sg2.type = 'fist lf=0.9 pcid=90.0'
AND    chem.id_chem = phc.id_chem
GROUP BY sg2.id, chem.id_chem
) AS a
;

SELECT '';

## number of experimentally-determined interactions
SELECT COUNT(ui.id) n,
       'unint'
FROM   UnInt AS ui,
       Seq   AS s1,
       Seq   AS s2
WHERE  s1.id = ui.id_seq1
AND    s1.source = 'uniprot-sprot'
AND    s2.id = ui.id_seq2
AND    s2.source = 'uniprot-sprot'
;


## number of predicted interactions
SELECT COUNT(id) n,
       'ppPred' type,
       'ppPred'
FROM ContactHit

UNION

SELECT COUNT(id) n,
       type,
       REPLACE(type, 'ppPred', '')
FROM
(
SELECT id,
       CASE
       WHEN pcid_a >= 70 AND pcid_b >= 70 THEN 'ppPredHigh'
       WHEN pcid_a >= 50 AND pcid_b >= 50 THEN 'ppPredMed'
       ELSE 'ppPredLow'
       END type
FROM   ContactHit
) AS a

GROUP BY a.type
;

## number of predicted interactions per species
SELECT COUNT(id) n,
       type,
       `desc`

FROM
(
SELECT ch.id,

       CASE
       WHEN ch.pcid_a >= 70 AND ch.pcid_b >= 70 THEN CONCAT_WS('-', 'ppPred', 'Taxon', sa1_to_ta1.id_taxon, 'High')
       WHEN ch.pcid_a >= 50 AND ch.pcid_b >= 50 THEN CONCAT_WS('-', 'ppPred', 'Taxon', sa1_to_ta1.id_taxon, 'Med')
       ELSE CONCAT_WS('-', 'ppPred', 'Taxon', sa1_to_ta1.id_taxon, 'Low')
       END type,
       
       CASE
       WHEN ch.pcid_a >= 70 AND ch.pcid_b >= 70 THEN 'High'
       WHEN ch.pcid_a >= 50 AND ch.pcid_b >= 50 THEN 'Med'
       ELSE 'Low'
       END `desc`
       
FROM   ContactHit AS ch,
       SeqToTaxon AS sa1_to_ta1
WHERE  sa1_to_ta1.id_seq = ch.id_seq_a1
AND    sa1_to_ta1.id_taxon IN (272634, 224308, 83333, 559292, 6239, 7227, 10090, 9606)
) AS a

GROUP BY a.type
;

## number of predicted prot-prot interactions supported by known interactions at different uniref levels
# see mechismo_pipeline_counts_pred_support.sql

## FIXME - number of predicted protein-DNA/RNA interactions, at the three different confidence levels
## FIXME - number of predicted protein-chem interactions, at the three different confidence levels

## FIXME - number of interface residues

## FIXME - medulloblastoma
#           - number of SNVs
#           - number of non-synonymous mutations
#           - number in structure, at the three confidence levels
#           - number in interface, at the three confidence levels

