SELECT fi.id,
       f.chemical_type
FROM   Frag     AS f,
       FragInst AS fi
WHERE  fi.id_frag = f.id
;
