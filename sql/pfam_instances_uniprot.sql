SELECT s.name        name,
       s.primary_id  ac_uniprot,
       f.ac_src      ac_pfam,
       fi.start_seq  start_seq,
       fi.end_seq    end_seq,
       fi.e_value    e_value
FROM   FeatureInst AS fi,
       Feature     AS f,
       Seq         AS s
WHERE  f.id = fi.id_feature
AND    f.source = 'Pfam'
AND    s.id = fi.id_seq
AND    s.source = 'uniprot-sprot'
;
