## number of predicted prot-prot interactions supported by known interactions at different uniref levels
SELECT COUNT(id) n,
       type,
       `desc`

FROM
(
SELECT ch.id,

       CASE
       WHEN ch.pcid_a >= 70 AND ch.pcid_b >= 70 THEN CONCAT_WS('-', 'ppPred', 'Taxon', sa1_to_ta1.id_taxon, 'High', 'Known', 'Direct')
       WHEN ch.pcid_a >= 50 AND ch.pcid_b >= 50 THEN CONCAT_WS('-', 'ppPred', 'Taxon', sa1_to_ta1.id_taxon, 'Med', 'Known', 'Direct')
       ELSE CONCAT_WS('-', 'ppPred', 'Taxon', sa1_to_ta1.id_taxon, 'Low', 'Known', 'Direct')
       END type,
       
       'Direct' `desc`
       
FROM   ContactHit AS ch,
       SeqToTaxon AS sa1_to_ta1,
       UnInt      AS ui
WHERE  sa1_to_ta1.id_seq = ch.id_seq_a1
AND    sa1_to_ta1.id_taxon IN (272634, 224308, 83333, 559292, 6239, 7227, 10090, 9606)

AND    ui.id_seq1 = ch.id_seq_a1
AND    ui.id_seq2 = ch.id_seq_b1
GROUP BY ch.id, sa1_to_ta1.id_taxon
) AS a

GROUP BY a.type
;

SELECT COUNT(id) n,
       REPLACE(type, 'uniref ', 'UniRef'),
       REPLACE(`desc`, 'uniref ', 'UniRef')

FROM
(
SELECT ch.id,

       CASE
       WHEN ch.pcid_a >= 70 AND ch.pcid_b >= 70 THEN CONCAT_WS('-', 'ppPred', 'Taxon', sa1_to_ta1.id_taxon, 'High', 'Known', ga.type)
       WHEN ch.pcid_a >= 50 AND ch.pcid_b >= 50 THEN CONCAT_WS('-', 'ppPred', 'Taxon', sa1_to_ta1.id_taxon, 'Med', 'Known', ga.type)
       ELSE CONCAT_WS('-', 'ppPred', 'Taxon', sa1_to_ta1.id_taxon, 'Low', 'Known', ga.type)
       END type,
       
       ga.type `desc`
       
FROM   ContactHit AS ch,
       SeqToTaxon AS sa1_to_ta1,

       SeqToGroup AS a1_to_ga,
       SeqGroup   AS ga,
       SeqToGroup AS a3_to_ga,

       SeqToGroup AS b1_to_gb,
       SeqGroup   AS gb,
       SeqToGroup AS b3_to_gb,

       UnInt      AS ui

WHERE  sa1_to_ta1.id_seq = ch.id_seq_a1
AND    sa1_to_ta1.id_taxon IN (272634, 224308, 83333, 559292, 6239, 7227, 10090, 9606)

AND    a1_to_ga.id_seq = ch.id_seq_a1
AND    ga.id = a1_to_ga.id_group
AND    ga.type LIKE 'uniref%'
AND    a3_to_ga.id_group = ga.id

AND    b1_to_gb.id_seq = ch.id_seq_b1
AND    gb.id = b1_to_gb.id_group
AND    gb.type = ga.type
AND    b3_to_gb.id_group = gb.id

AND    ui.id_seq1 = a3_to_ga.id_seq
AND    ui.id_seq2 = b3_to_gb.id_seq
GROUP BY ch.id, sa1_to_ta1.id_taxon, ga.type

) AS a

GROUP BY a.type
;
