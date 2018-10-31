#!/bin/bash
dn=./data/pdb/
mkdir -p ${dn}
/usr/bin/time -o ${dn}parse.time perl -I./lib ./script/parse_pdb.pl --outdir ./data/ --ecod $DS/ecod/ecod.latest.domains.txt --fork pdb --n_jobs 6 $DS/pdb 1> ${dn}parse.txt 2> ${dn}parse.err
cat ${dn}parse.time | mail -r matthew.betts@bioquant.uni-heidelberg.de -s 'parse_pdb.pl finished' matthew.betts@bioquant.uni-heidelberg.de
