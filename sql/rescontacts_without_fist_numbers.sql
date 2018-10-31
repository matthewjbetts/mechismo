SET @id_contact = 161;

SELECT rc.id_contact,
       rc.id_frag_inst1,
       rc.id_frag_inst2,

       rc.id_fa1,
       rc.pdb_a1,
       rc.dom_a1,
       rc.chain1,
       rc.resSeq1,
       frma1.chain,
       frma1.resSeq,

       rc.id_fb1,
       rc.pdb_b1,
       rc.dom_b1,
       rc.chain2,
       rc.resSeq2,
       frmb1.chain,
       frmb1.resSeq

FROM   (
        SELECT c.id                                                   id_contact,

               fa1.id                                                 id_fa1,
               CONCAT_WS('-', fa1.idcode, fia1.assembly, fia1.model)  pdb_a1,
               fa1.dom                                                dom_a1,

               fb1.id                                                 id_fb1,
               CONCAT_WS('-', fb1.idcode, fib1.assembly, fib1.model)  pdb_b1,
               fb1.dom                                                dom_b1,

               rc.*

        FROM   Contact    AS c,
               FragInst   AS fia1,
               Frag       AS fa1,
               FragInst   AS fib1,
               Frag       AS fb1,
               ResContact AS rc
        WHERE  c.id = @id_contact
        AND    fia1.id = c.id_frag_inst1
        AND    fa1.id = fia1.id_frag
        AND    fib1.id = c.id_frag_inst2
        AND    fb1.id = fib1.id_frag
        AND    rc.id_frag_inst1 = c.id_frag_inst1
        AND    rc.id_frag_inst2 = c.id_frag_inst2
       ) AS rc

LEFT JOIN FragResMapping AS frma1 ON frma1.id_frag = rc.id_fa1 AND frma1.chain = rc.chain1 AND frma1.resSeq = rc.resSeq1 AND frma1.iCode = rc.iCode1
LEFT JOIN FragResMapping AS frmb1 ON frmb1.id_frag = rc.id_fb1 AND frmb1.chain = rc.chain2 AND frmb1.resSeq = rc.resSeq2 AND frmb1.iCode = rc.iCode2

WHERE (frma1.chain IS NULL OR frmb1.chain IS NULL)
;
