## blast uniprot sprot and varsplic vs seqres
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  mkdir -p ./data/blast/sprot_varsplic-seqres/${id_taxon}
  /usr/bin/time -o ./data/blast/sprot_varsplic-seqres/${id_taxon}/blast.time perl -I./lib ./script/blast.pl --outdir ./data/blast/sprot_varsplic-seqres --fork $id_taxon --n_jobs 8 --db ./data/blast/seqres --fasta ./data/uniprot/sprot/${id_taxon}_aa.fasta 1> ./data/blast/sprot_varsplic-seqres/${id_taxon}/blast.out 2> ./data/blast/sprot_varsplic-seqres/${id_taxon}/blast.err
done
