#!/bin/bash
idcode=$1

mysql -u anonymous -D fistdb --skip-column-names -e "SELECT CONCAT('/net/netfile1/ds-russell/pdb/', substr(f.idcode, 2, 2), '/pdb', f.idcode, '.ent.gz'), fi.id, CONCAT('{ ', f.dom, ' }') FROM Frag AS f, FragInst AS fi WHERE f.idcode = '${idcode}' AND f.fullchain IS TRUE AND fi.id_frag = f.id AND fi.assembly = 0" | perl -ne 's/\s+/ /g; print"$_\n";' > t/${idcode}.pdb.dom

mysql -u anonymous -D fistdb --skip-column-names -e "SELECT c.* FROM Frag AS fa2, FragInst AS fia2, Contact AS c, FragInst AS fib2, Frag AS fb2 WHERE fa2.idcode = '${idcode}' AND fa2.fullchain IS TRUE AND fia2.id_frag = fa2.id AND c.id_frag_inst1 = fia2.id AND fib2.id = c.id_frag_inst2 AND fb2.id = fib2.id_frag AND fb2.fullchain IS TRUE AND c.isa_group IS FALSE AND fia2.assembly = 0 ORDER BY c.id;" > t/${idcode}.pdb.Contact.tsv 

mysql -u anonymous -D fistdb --skip-column-names -e "SELECT rc.* FROM Frag AS fa2, FragInst AS fia2, ResContact AS rc, FragInst AS fib2, Frag AS fb2 WHERE fa2.idcode = '${idcode}' AND fa2.fullchain IS TRUE AND fia2.id_frag = fa2.id AND rc.id_frag_inst1 = fia2.id AND fib2.id = rc.id_frag_inst2 AND fb2.id = fib2.id_frag AND fb2.fullchain IS TRUE AND fia2.assembly = 0;" | perl -pe 's/\\0/ /g' > t/${idcode}.pdb.ResContact.tsv 

# intra-domain contacts
mysql -u anonymous -D fistdb --skip-column-names -e "SELECT rc.* FROM Frag AS fa2, FragInst AS fia2, ResContact AS rc WHERE fa2.idcode = '${idcode}' AND fa2.fullchain IS TRUE AND fia2.id_frag = fa2.id AND rc.id_frag_inst1 = fia2.id AND rc.id_frag_inst2 = 0 AND fia2.assembly = 0;" | perl -pe 's/\\0/ /g' >> t/${idcode}.pdb.ResContact.tsv 
perl -i -F'/\t/' -nae 'chomp(@F); ($F[1] == 0) and ($F[1] = $F[0]); print join("\t", @F), "\n";' t/${idcode}.pdb.ResContact.tsv 

# some Contacts in the db have no matching ResContact
perl -i -nae "BEGIN{open(I, 't/${idcode}.pdb.ResContact.tsv') or die; while(<I>){@F = split; \$S{\$F[0]}->{\$F[1]}++;}close(I);} defined(\$S{\$F[1]}->{\$F[2]}) and print;" t/${idcode}.pdb.Contact.tsv
