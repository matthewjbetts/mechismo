SELECT n.*,
       d.acc
FROM   FragNaccess AS n LEFT JOIN FragDssp AS d
ON     d.id_frag = n.id_frag
AND    d.chain   = n.chain
AND    d.resseq  = n.resseq
AND    d.icode   = n.icode
;
