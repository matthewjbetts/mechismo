SELECT ch1.id,
       ch2.id

FROM   ContactHit AS ch1,
       ContactHit AS ch2

WHERE  ch2.id > ch1.id

AND    ch2.id_seq_a1 = ch1.id_seq_a1
AND    ch2.start_a1 = ch1.start_a1
AND    ch2.end_a1 = ch1.end_a1

AND    ch2.id_seq_b1 = ch1.id_seq_b1
AND    ch2.start_b1 = ch1.start_b1
AND    ch2.end_b1 = ch1.end_b1

AND    ch2.id_seq_a2 = ch1.id_seq_a2
AND    ch2.start_a2 = ch1.start_a2
AND    ch2.end_a2 = ch1.end_a2

AND    ch2.id_seq_b2 = ch1.id_seq_b2
AND    ch2.start_b2 = ch1.start_b2
AND    ch2.end_b2 = ch1.end_b2

AND    ch2.id_frag_inst_a2 = ch1.id_frag_inst_a2
AND    ch2.id_frag_inst_b2 = ch1.id_frag_inst_b2
;

# mysql -u anonymous -D fistdb --skip-column-names --quick < ./sql/find_duplicated_contact_hits.sql 1> ./data/duplicated_contact_hits.txt
# perl -nae 'print"SELECT * FROM ContactHit WHERE id = $F[1];\nDELETE FROM ContactHit WHERE id = $F[1];\n\n";' ./data/duplicated_contact_hits.txt | mysql -p -D fistdb --skip-column-names > ./data/duplicated_contact_hits.removed.txt
