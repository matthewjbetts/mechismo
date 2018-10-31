# get the length of the fist sequence of a chain segment
UPDATE Frag AS f,
       ChainSegment AS cs,
       ResMapping AS rm1,
       ResMapping AS rm2
SET    cs.fist_start = 1, # to be updated later
       cs.fist_len = rm2.fist - rm1.fist + 1
WHERE  cs.id_frag = f.id
AND    rm1.idcode = f.idcode
AND    rm1.chain = cs.chain
AND    rm1.resseq = cs.resseq_start
AND    rm1.icode = cs.icode_start
AND    rm2.idcode = f.idcode
AND    rm2.chain = cs.chain
AND    rm2.resseq = cs.resseq_end
AND    rm2.icode = cs.icode_end
;

# get start positions of chain segments in the fist sequences of fragments
# (which are not necessarily the same as in the full chain fist sequence)
UPDATE ChainSegment AS a,
       (
        SELECT cs1.id,
               SUM(cs2.fist_len) + 1 fist_start
        FROM   ChainSegment AS cs1,
               ChainSegment AS cs2
        WHERE  cs2.id_frag = cs1.id_frag
        AND    cs2.id < cs1.id
        GROUP BY cs1.id
       ) AS b
SET a.fist_start = b.fist_start
WHERE a.id = b.id
;
