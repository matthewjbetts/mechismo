## number of predicted protein-DNA/RNA interactions, at the three different confidence levels

SELECT COUNT(DISTINCT(id_seq)) n,
       CONCAT_WS('-', 'pdPred', 'Taxon', id_taxon, confidence),
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
       FragInst       AS fia2,
       Contact        AS c,
       FragInst       AS fib2,
       Frag           AS fb2
       #ResContact     AS rc

WHERE  sa1.source = 'uniprot-sprot'
AND    sa1_to_ta1.id_seq = sa1.id
AND    sa1_to_ta1.id_taxon IN (272634, 224308, 83333, 559292, 6239, 7227, 10090, 9606)
AND    a1a2.id_seq1 = sa1.id
AND    sa2.id = a1a2.id_seq2
AND    sa2.source = 'fist'
AND    sa2_to_gaf.id_seq = sa2.id
AND    fa2_to_gaf.id_group = sa2_to_gaf.id_group
AND    fia2.id_frag = fa2_to_gaf.id_frag
AND    c.id_frag_inst1 = fia2.id
AND    fib2.id = c.id_frag_inst2
AND    fb2.id = fib2.id_frag
AND    fb2.chemical_type = 'nucleotide'
#AND    rc.id_frag_inst1 = fia2.id
#AND    rc.id_frag_inst2 = fib2.id
#AND    ((rc.SM IS TRUE) OR (rc.SS IS TRUE))

#LIMIT 10000
) AS a

GROUP BY a.id_taxon, a.confidence
;
