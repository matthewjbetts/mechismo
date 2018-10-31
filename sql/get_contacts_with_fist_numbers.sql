# PPIs and PDIs
SELECT c.id,             # 00
       c.id_frag_inst1,  # 01
       c.id_frag_inst2,  # 02
       c.crystal,        # 03
       c.n_res1,         # 04
       c.n_res2,         # 05
       c.n_clash,        # 06
       c.n_resres,       # 07
       frma1.fist fist1, # 08
       frmb1.fist fist2  # 09

FROM   Contact        AS c,   #FROM   (SELECT * FROM Contact LIMIT 10000)        AS c,
       ResContact     AS rc,

       FragInst       AS fia1,
       Frag           AS fa1,
       FragResMapping AS frma1,

       FragInst       AS fib1,
       Frag           AS fb1,
       FragResMapping AS frmb1

WHERE  c.id_frag_inst2 != c.id_frag_inst1
AND    rc.id_contact = c.id

AND    fia1.id = c.id_frag_inst1
AND    fa1.id = fia1.id_frag
AND    fa1.chemical_type = 'peptide'
AND    frma1.id_frag = fia1.id_frag
AND    frma1.chain = rc.chain1
AND    frma1.resSeq = rc.resSeq1
AND    frma1.iCode = rc.iCode1

AND    fib1.id = c.id_frag_inst2
AND    fb1.id = fib1.id_frag
AND    fb1.chemical_type IN ('peptide', 'nucleotide')
AND    frmb1.id_frag = fib1.id_frag
AND    frmb1.chain = rc.chain2
AND    frmb1.resSeq = rc.resSeq2
AND    frmb1.iCode = rc.iCode2
;

# PCIs
SELECT c.id,             # 00
       c.id_frag_inst1,  # 01
       c.id_frag_inst2,  # 02
       c.crystal,        # 03
       c.n_res1,         # 04
       c.n_res2,         # 05
       c.n_clash,        # 06
       c.n_resres,       # 07
       frma1.fist fist1, # 08
       1          fist2  # 09

FROM   Contact        AS c,   #FROM   (SELECT * FROM Contact LIMIT 10000)        AS c,
       ResContact     AS rc,

       FragInst       AS fia1,
       Frag           AS fa1,
       FragResMapping AS frma1,

       FragInst       AS fib1,
       Frag           AS fb1

WHERE  c.id_frag_inst2 != c.id_frag_inst1
AND    rc.id_frag_inst1 = c.id_frag_inst1
AND    rc.id_frag_inst2 = c.id_frag_inst2

AND    fia1.id = c.id_frag_inst1
AND    fa1.id = fia1.id_frag
AND    fa1.chemical_type = 'peptide'
AND    frma1.id_frag = fia1.id_frag
AND    frma1.chain = rc.chain1
AND    frma1.resSeq = rc.resSeq1
AND    frma1.iCode = rc.iCode1

AND    fib1.id = c.id_frag_inst2
AND    fb1.id = fib1.id_frag
AND    fb1.chemical_type NOT IN ('peptide', 'nucleotide')
;
