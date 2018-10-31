SELECT f1.idcode,

       CONCAT_WS('.', e1.x, e1.h, e1.t, e1.f) ecodA,
       CONCAT_WS('.', e2.x, e2.h, e2.t, e2.f) ecodB,

       (CASE
         WHEN fi1.assembly = 0 THEN CONCAT("/net/netfile1/ds-russell/pdb/", SUBSTR(f1.idcode, 2, 2), "/pdb", f1.idcode, ".ent.gz")
         ELSE CONCAT("/net/netfile1/ds-russell/pdb-biounit/", SUBSTR(f1.idcode, 2, 2), "/", f1.idcode, "-", fi1.assembly, "-", fi1.model, ".pdb.gz")
       END) pdbA,

       (CASE
         WHEN fi2.assembly = 0 THEN CONCAT("/net/netfile1/ds-russell/pdb/", SUBSTR(f2.idcode, 2, 2), "/pdb", f2.idcode, ".ent.gz")
         ELSE CONCAT("/net/netfile1/ds-russell/pdb-biounit/", SUBSTR(f2.idcode, 2, 2), "/", f2.idcode, "-", fi2.assembly, "-", fi2.model, ".pdb.gz")
       END) pdbB,

       f1.dom domA,
       f2.dom domB,

       c.crystal,
       c.n_res1 n_resA,
       c.n_res2 n_resB,
       c.n_resres

FROM   Contact    AS c,
       FragInst   AS fi1,
       Frag       AS f1,
       FragToEcod AS f1_to_e1,
       Ecod       AS e1,
       FragInst   AS fi2,
       Frag       AS f2,
       FragToEcod AS f2_to_e2,
       Ecod       AS e2
WHERE  c.isa_group IS FALSE
AND    c.id_frag_inst2 > c.id_frag_inst1

AND    fi1.id = c.id_frag_inst1
AND    f1.id = fi1.id_frag
AND    f1_to_e1.id_frag = f1.id
AND    e1.id = f1_to_e1.id_ecod

AND    fi2.id = c.id_frag_inst2
AND    f2.id = fi2.id_frag
AND    f2_to_e2.id_frag = f2.id
AND    e2.id = f2_to_e2.id_ecod
;
