#!/bin/bash
dn=./data/uniprot/sprot/
mkdir -p $dn
/usr/bin/time -o ${dn}parse.time perl -I./lib ./script/parse_uniprot.pl --outdir ${dn} --varsplic /net/netfile1/ds-russell/uniprot/knowledgebase/complete/uniprot_sprot_varsplic.fasta.gz /net/netfile1/ds-russell/uniprot/knowledgebase/complete/uniprot_sprot.dat.gz 1> ${dn}parse.txt 2> ${dn}parse.err
cat ${dn}parse.time | mail -r matthew.betts@bioquant.uni-heidelberg.de -s 'parse_uniprot.pl finished' matthew.betts@bioquant.uni-heidelberg.de
