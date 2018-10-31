## number of predicted protein-chem interactions, at the three different confidence levels

SELECT COUNT(DISTINCT(id_seq)) n,
       CONCAT_WS('-', 'pcPred', 'Taxon', id_taxon, confidence),
       confidence
FROM
(
SELECT sa1_to_ta1.id_taxon,
       sa1.id id_seq,
       CASE
       WHEN a1a2.pcid >= 70 THEN 'High'
       WHEN a1a2.pcid >= 50 THEN 'Med'
       ELSE 'Low'
       END confidence
       
FROM   Seq            AS sa1,
       SeqToTaxon     AS sa1_to_ta1,
       Hsp            AS a1a2,
       Seq            AS sa2,
       SeqToGroup     AS sa2_to_gaf,
       FragToSeqGroup AS fa2_to_gaf,
       temp_phc       AS phc
WHERE  sa1.source = 'uniprot-sprot'
AND    sa1_to_ta1.id_seq = sa1.id
AND    sa1_to_ta1.id_taxon IN (272634, 224308, 83333, 559292, 6239, 7227, 10090, 9606)
AND    a1a2.id_seq1 = sa1.id
AND    sa2.id = a1a2.id_seq2
AND    sa2.source = 'fist'
AND    sa2_to_gaf.id_seq = sa2.id
AND    fa2_to_gaf.id_group = sa2_to_gaf.id_group
AND    phc.id_frag = fa2_to_gaf.id_frag

#LIMIT 10000
) AS a

GROUP BY a.id_taxon, a.confidence
;
