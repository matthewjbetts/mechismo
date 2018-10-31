/usr/bin/time -o ./data/blast/sprot_varsplic-seqres/blast.time perl -I./lib ./script/blast.pl --outdir ./data/blast/ --fork sprot_varsplic-seqres --db ./data/blast/seqres --fasta ./data/uniprot/sprot/aa.fasta 1> ./data/blast/sprot_varsplic-seqres/blast.out 2> ./data/blast/sprot_varsplic-seqres/blast.err
cat ./data/blast/sprot_varsplic-seqres/blast.time | mail -r matthew.betts@bioquant.uni-heidelberg.de -s 'sprot_varsplic vs. seqres finished' matthew.betts@bioquant.uni-heidelberg.de
