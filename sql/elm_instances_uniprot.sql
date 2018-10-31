SELECT s.name            name,
       s.primary_id      ac_uniprot,
       f.ac_src          ac_elm,
       f.regex           regex,
       fi.start_seq      start_seq,
       fi.end_seq        end_seq,
       fi.true_positive  true_positive
FROM   FeatureInst AS fi,
       Feature     AS f,
       Seq         AS s
WHERE  f.id = fi.id_feature
AND    f.source = 'elm'
AND    s.id = fi.id_seq
AND    s.source = 'uniprot-sprot'
;
