SELECT fi.id,
       f.id_seq
FROM   Frag     AS f,
       FragInst AS fi
WHERE  f.chemical_type IN ('peptide', 'nucleotide')
AND    fi.id_frag = f.id
;

SELECT fi.id,
       CONCAT('CHEM:', f.chemical_type) # 'CHEM:' prefix to avoid numeric chemical names being mistaken for sequence identifiers
FROM   Frag     AS f,
       FragInst AS fi
WHERE  f.chemical_type NOT IN ('peptide', 'nucleotide')
AND    fi.id_frag = f.id
;
