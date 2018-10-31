SELECT CONCAT_WS(':', f1.chemical_type, f2.chemical_type),
       COUNT(c.id) n
FROM   Contact  AS c,
       FragInst AS fi1,
       Frag     AS f1,
       FragInst AS fi2,
       Frag     AS f2
WHERE  c.isa_group IS FALSE
AND    c.crystal IS FALSE
AND    c.id_frag_inst2 >= c.id_frag_inst1
AND    fi1.id = c.id_frag_inst1
AND    f1.id = fi1.id_frag
AND    fi2.id = c.id_frag_inst2
AND    f2.id = fi2.id_frag
GROUP BY f1.chemical_type, f2.chemical_type

UNION

SELECT 'ppi-nr' type,
       COUNT(c.id)
FROM   Contact  AS c,
       FragInst AS fi1,
       Frag     AS f1,
       FragInst AS fi2,
       Frag     AS f2
WHERE  c.isa_group IS FALSE
AND    c.crystal IS FALSE
AND    c.id_frag_inst2 >= c.id_frag_inst1
AND    fi1.id = c.id_frag_inst1
AND    f1.id = fi1.id_frag
AND    fi2.id = c.id_frag_inst2
AND    f2.id = fi2.id_frag
AND    f1.chemical_type = 'peptide'
AND    f2.chemical_type = 'peptide'
AND    c.same_frag IS FALSE
AND    c.lf >= 0.9
AND    c.pcid >= 90
AND    c.full_jaccard >= 0.9

UNION

SELECT 'pdi' type,
       COUNT(c.id)
FROM   Contact  AS c,
       FragInst AS fi1,
       Frag     AS f1,
       FragInst AS fi2,
       Frag     AS f2
WHERE  c.isa_group IS FALSE
AND    c.crystal IS FALSE
AND    fi1.id = c.id_frag_inst1
AND    f1.id = fi1.id_frag
AND    fi2.id = c.id_frag_inst2
AND    f2.id = fi2.id_frag
AND    f1.chemical_type = 'peptide'
AND    f2.chemical_type = 'nucleotide'

UNION

SELECT 'pdi-nr' type,
       COUNT(DISTINCT(sgSeq.id)) n
FROM   Contact        AS c,
       FragInst       AS fi1,
       Frag           AS f1,
       FragInst       AS fi2,
       Frag           AS f2,
       FragToSeqGroup AS f1_to_sgFrag,
       SeqGroup       AS sgFrag,
       SeqToGroup     AS s1_to_sgFrag,
       Seq            AS s1,
       SeqToGroup     AS s1_to_sgSeq,
       SeqGroup       AS sgSeq
WHERE  c.isa_group IS FALSE
AND    c.crystal IS FALSE
AND    fi1.id = c.id_frag_inst1
AND    f1.id = fi1.id_frag
AND    fi2.id = c.id_frag_inst2
AND    f2.id = fi2.id_frag
AND    f1.chemical_type = 'peptide'
AND    f2.chemical_type = 'nucleotide'
AND    f1_to_sgFrag.id_frag = f1.id
AND    sgFrag.id = f1_to_sgFrag.id_group
AND    sgFrag.type = 'frag'
AND    s1_to_sgFrag.id_group = sgFrag.id
AND    s1.id = s1_to_sgFrag.id_seq
AND    s1.source = 'fist'
AND    s1_to_sgSeq.id_seq = s1.id
AND    sgSeq.id = s1_to_sgSeq.id_group
AND    sgSeq.type = 'fist lf=0.9 pcid=90.0'

UNION

SELECT 'pci' type,
       COUNT(id_frag) n
FROM   FragHetContact

UNION

SELECT 'pci-nr' type,
       COUNT(a.id) n
FROM
(
SELECT sgSeq.id,
       pc.type
FROM   FragHetContact AS fhc,
       FragToSeqGroup AS f1_to_sgFrag,
       SeqGroup       AS sgFrag,
       SeqToGroup     AS s1_to_sgFrag,
       Seq            AS s1,
       SeqToGroup     AS s1_to_sgSeq,
       SeqGroup       AS sgSeq,
       PdbChem        AS pc
WHERE  f1_to_sgFrag.id_frag = fhc.id_frag
AND    sgFrag.id = f1_to_sgFrag.id_group
AND    sgFrag.type = 'frag'
AND    s1_to_sgFrag.id_group = sgFrag.id
AND    s1.id = s1_to_sgFrag.id_seq
AND    s1.source = 'fist'
AND    s1_to_sgSeq.id_seq = s1.id
AND    sgSeq.id = s1_to_sgSeq.id_group
AND    sgSeq.type = 'fist lf=0.9 pcid=90.0'
AND    pc.id_chem = fhc.id_chem
GROUP BY sgSeq.id, pc.type
) AS a
;

