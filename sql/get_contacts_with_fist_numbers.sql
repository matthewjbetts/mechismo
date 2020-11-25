SELECT ppx.id,                          # 00
       ppx.id_frag_inst1,               # 01
       ppx.id_frag_inst2,               # 02
       ppx.crystal,                     # 03
       ppx.n_res1,                      # 04
       ppx.n_res2,                      # 05
       ppx.n_clash,                     # 06
       ppx.n_resres,                    # 07
       ppx.type,                        # 08
       frma1.fist AS fist1,             # 09
       COALESCE(frmb1.fist, 1) AS fist2 # 10 # '1' for frags with no fist sequence (i.e. chemicals)
FROM (
SELECT c.id,
       c.id_frag_inst1,
       c.id_frag_inst2,
       fia1.id_frag AS id_frag1,
       fib1.id_frag AS id_frag2,
       c.crystal,
       c.n_res1,
       c.n_res2,
       c.n_clash,
       c.n_resres,
       rc.chain1,
       rc.resseq1,
       rc.icode1,
       rc.chain2,
       rc.resseq2,
       rc.icode2,
       CASE
         WHEN fb1.chemical_type = 'peptide' THEN 'PPI'
         WHEN fb1.chemical_type = 'nucleotide' THEN 'PDI'
         ELSE 'PCI'
       END AS type
       
FROM Contact AS c
JOIN ResContact AS rc ON rc.id_contact = c.id

JOIN FragInst AS fia1 ON fia1.id = c.id_frag_inst1
JOIN Frag AS fa1 ON fa1.id = fia1.id_frag AND fa1.chemical_type = 'peptide'

JOIN FragInst AS fib1 ON fib1.id = c.id_frag_inst2
JOIN Frag AS fb1 ON fb1.id = fib1.id_frag AND fb1.chemical_type != 'SITE'

WHERE c.id_frag_inst2 != c.id_frag_inst1
) AS ppx

JOIN FragResMapping AS frma1
ON frma1.id_frag = ppx.id_frag1
AND frma1.chain = ppx.chain1
AND frma1.resSeq = ppx.resSeq1
AND frma1.iCode = ppx.iCode1

LEFT JOIN FragResMapping AS frmb1
ON frmb1.id_frag = ppx.id_frag2
AND frmb1.chain = ppx.chain2
AND frmb1.resSeq = ppx.resSeq2
AND frmb1.iCode = ppx.iCode2
;
