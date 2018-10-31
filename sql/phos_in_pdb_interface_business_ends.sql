# phosphates in PDB, in an interface

# explicitly get the columns name here rather than implicitly for each select below
SELECT 'struct',

       'id_frag_inst1',
       'id_frag1',
       'fist1',  
       'chain1', 
       'resseq1',
       'icode1',
       'res1_1',
       'res3_1',

       'id_frag_inst2',
       'id_frag2',
       'fist2',
       'chain2',
       'resseq2',
       'icode2',
       'res1_2',
       'res3_2',

       'business',

       'len1',
       'seq1'
;

DROP TABLE IF EXISTS phos_in_pdb_interface;
CREATE TEMPORARY TABLE phos_in_pdb_interface (
       struct	      VARCHAR(10) NOT NULL,

       id_frag_inst1  INTEGER UNSIGNED NOT NULL,
       id_frag1       INTEGER UNSIGNED NOT NULL,
       fist1          SMALLINT UNSIGNED NOT NULL,
       chain1         BINARY(1) NOT NULL,
       resseq1        SMALLINT SIGNED NOT NULL,
       icode1         BINARY(1) NOT NULL,
       res1_1         CHAR(1) NOT NULL,
       res3_1         CHAR(3) NOT NULL,

       id_frag_inst2  INTEGER UNSIGNED NOT NULL,
       id_frag2       INTEGER UNSIGNED NOT NULL,
       fist2          SMALLINT UNSIGNED NOT NULL,
       chain2         BINARY(1) NOT NULL,
       resseq2        SMALLINT SIGNED NOT NULL,
       icode2         BINARY(1) NOT NULL,
       res1_2         CHAR(1) NOT NULL,
       res3_2         CHAR(3) NOT NULL,

       business       BOOLEAN NOT NULL DEFAULT FALSE,

       len1           SMALLINT UNSIGNED NOT NULL,
       seq1           TEXT
);

INSERT INTO phos_in_pdb_interface

SELECT CONCAT_WS('-', f1.idcode, fi1.assembly, fi1.model, fi2.model) struct,

       fi1.id        id_frag_inst1,
       frm1.id_frag  id_frag1,
       frm1.fist     fist1,
       frm1.chain    chain1,
       frm1.resseq   resseq1,
       frm1.icode    icode1,
       rm1.res1      res1_1,
       rm1.res3      res3_1,

       fi2.id        id_frag_inst2,
       frm2.id_frag  id_frag2,
       frm2.fist     fist2,
       frm2.chain    chain2,
       frm2.resseq   resseq2,
       frm2.icode    icode2,
       rm2.res1      res1_2,
       rm2.res3      res3_2,

       (rc.ss_unmod_salt OR rc.ss_unmod_hbond OR rc.ss_unmod_end)  business,

       s1.len        len1,
       s1.seq        seq1

FROM   ResMapping      AS rm1,
       Frag            AS f1,
       FragResMapping  AS frm1,
       FragInst        AS fi1,
       ResContact      AS rc,
       Contact         AS c,
       FragInst        AS fi2,
       FragResMapping  AS frm2,
       Frag            AS f2,
       ResMapping      AS rm2,

       FragToSeqGroup  AS f1_to_g1,
       SeqGroup        AS g1,
       SeqToGroup      AS s1_to_g1,
       Seq             AS s1

WHERE  rm1.res3 IN ('SEP', 'TPO', 'PTR')
AND    f1.idcode = rm1.idcode
AND    f1.fullchain IS TRUE
AND    frm1.id_frag = f1.id
AND    frm1.chain = rm1.chain
AND    frm1.resseq = rm1.resseq
AND    frm1.icode = rm1.icode
AND    fi1.id_frag = f1.id

AND    rc.id_frag_inst1 = fi1.id
AND    rc.chain1 = frm1.chain
AND    rc.resseq1 = frm1.resseq
AND    rc.icode1 = frm1.icode
AND    rc.SS IS TRUE
#AND    (rc.ss_unmod_salt IS TRUE OR rc.ss_unmod_hbond IS TRUE OR rc.ss_unmod_end IS TRUE) # marking these in the 'business' column rather than selecting them only

AND    fi2.id = rc.id_frag_inst2
AND    frm2.id_frag = fi2.id_frag
AND    frm2.chain = rc.chain2
AND    frm2.resseq = rc.resseq2
AND    frm2.icode = rc.icode2
AND    f2.id = fi2.id_frag
AND    f2.fullchain IS TRUE
AND    rm2.idcode = f2.idcode
AND    rm2.chain = frm2.chain
AND    rm2.resseq = frm2.resseq
AND    rm2.icode = frm2.icode

AND    c.id_frag_inst1 = rc.id_frag_inst1
AND    c.id_frag_inst2 = rc.id_frag_inst2
AND    c.isa_group IS FALSE
AND    c.crystal IS FALSE

AND    f1_to_g1.id_frag = f1.id
AND    g1.id = f1_to_g1.id_group
AND    g1.type = 'frag'
AND    s1_to_g1.id_group = g1.id
AND    s1.id = s1_to_g1.id_seq
AND    s1.source = 'fist'
;

SELECT * FROM phos_in_pdb_interface;

# - now get all the intra-chain contacts for the phos in pdb interfaces found above
# - need to look at the frag inst for frag1 that is in assembly 0.
# - intra-fraginst res contacts only stored in one direction so have to check both here.
# - is quicker to query twice rather than once with an 'or' for some reason.

SELECT a.struct         struct,

       a.id_frag_inst1  id_frag_inst1,
       a.id_frag1       id_frag1,
       a.fist1          fist1,
       a.chain1         chain1,
       a.resseq1        resseq1,
       a.icode1         icode1,
       a.res1_1         res1_1,
       a.res3_1         res3_1,

       0                id_frag_inst2,
       0                id_frag2,
       frm2.fist        fist2,
       frm2.chain       chain2,
       frm2.resseq      resseq2,
       frm2.icode       icode2,
       rm2.res1         res1_2,
       rm2.res3         res3_2,

       (rc.ss_unmod_salt OR rc.ss_unmod_hbond OR rc.ss_unmod_end)  business,

       a.len1           len1,
       a.seq1           seq1

FROM   (
        SELECT struct,
               id_frag_inst1,
               id_frag1,
               fist1,
               chain1,
               resseq1,
               icode1,
               res1_1,
               res3_1,
               len1,
               seq1
        FROM   phos_in_pdb_interface
        GROUP BY struct, id_frag_inst1, id_frag1, fist1, chain1, resseq1, icode1, res1_1, res3_1, len1, seq1
       ) AS a,
       FragInst       AS fi1,
       ResContact     AS rc,
       Frag           AS f2,
       FragResMapping AS frm2,
       ResMapping     AS rm2
WHERE  fi1.id_frag = a.id_frag1
AND    fi1.assembly = 0
AND    fi1.model = 0
AND    rc.id_frag_inst1 = fi1.id
AND    rc.id_frag_inst2 = 0
AND    rc.ss IS TRUE
#AND    (rc.ss_unmod_salt IS TRUE OR rc.ss_unmod_hbond IS TRUE OR rc.ss_unmod_end IS TRUE) # marking these in the 'business' column rather than selecting them only
AND    f2.id = a.id_frag1
AND    frm2.id_frag = f2.id

AND    (rc.chain1 = a.chain1 AND rc.resseq1 = a.resseq1 AND rc.icode1 = a.icode1 AND frm2.chain = rc.chain2 AND frm2.resseq = rc.resseq2 AND frm2.icode = rc.icode2)
#AND    (rc.chain2 = a.chain1 AND rc.resseq2 = a.resseq1 AND rc.icode2 = a.icode1 AND frm2.chain = rc.chain1 AND frm2.resseq = rc.resseq1 AND frm2.icode = rc.icode1)

AND    rm2.idcode = f2.idcode
AND    rm2.chain = frm2.chain
AND    rm2.resseq = frm2.resseq
AND    rm2.icode = frm2.icode
;

SELECT a.struct         struct,

       a.id_frag_inst1  id_frag_inst1,
       a.id_frag1       id_frag1,
       a.fist1          fist1,
       a.chain1         chain1,
       a.resseq1        resseq1,
       a.icode1         icode1,
       a.res1_1         res1_1,
       a.res3_1         res3_1,

       0                id_frag_inst2,
       0                id_frag2,
       frm2.fist        fist2,
       frm2.chain       chain2,
       frm2.resseq      resseq2,
       frm2.icode       icode2,
       rm2.res1         res1_2,
       rm2.res3         res3_2,

       (rc.ss_unmod_salt OR rc.ss_unmod_hbond OR rc.ss_unmod_end)  business,

       a.len1           len1,
       a.seq1           seq1

FROM   (
        SELECT struct,
               id_frag_inst1,
               id_frag1,
               fist1,
               chain1,
               resseq1,
               icode1,
               res1_1,
               res3_1,
               len1,
               seq1
        FROM   phos_in_pdb_interface
        GROUP BY struct, id_frag_inst1, id_frag1, fist1, chain1, resseq1, icode1, res1_1, res3_1, len1, seq1
       ) AS a,
       FragInst       AS fi1,
       ResContact     AS rc,
       Frag           AS f2,
       FragResMapping AS frm2,
       ResMapping     AS rm2
WHERE  fi1.id_frag = a.id_frag1
AND    fi1.assembly = 0
AND    fi1.model = 0
AND    rc.id_frag_inst1 = fi1.id
AND    rc.id_frag_inst2 = 0
AND    rc.SS IS TRUE
#AND    (rc.ss_unmod_salt IS TRUE OR rc.ss_unmod_hbond IS TRUE OR rc.ss_unmod_end IS TRUE) # marking these in the 'business' column rather than selecting them only
AND    f2.id = a.id_frag1
AND    frm2.id_frag = f2.id

#AND    (rc.chain1 = a.chain1 AND rc.resseq1 = a.resseq1 AND rc.icode1 = a.icode1 AND frm2.chain = rc.chain2 AND frm2.resseq = rc.resseq2 AND frm2.icode = rc.icode2)
AND    (rc.chain2 = a.chain1 AND rc.resseq2 = a.resseq1 AND rc.icode2 = a.icode1 AND frm2.chain = rc.chain1 AND frm2.resseq = rc.resseq1 AND frm2.icode = rc.icode1)

AND    rm2.idcode = f2.idcode
AND    rm2.chain = frm2.chain
AND    rm2.resseq = frm2.resseq
AND    rm2.icode = frm2.icode
;

# FIXME - replace "\0" when outputting
