#!/bin/bash
n=$1
lf=$2
pcid=$3
jaccard=$4
dn=./temp/${n}-${lf}-${pcid}-${jaccard}/
mkdir -p $dn
NYTPROF=file=${dn}nytprof.out perl -d:NYTProf -I./lib ./script/group_contacts.pl --outdir ${dn} --lf $lf --pcid $pcid --jaccard $jaccard 1> ${dn}stdout 2> ${dn}stderr
nytprofhtml --file ${dn}nytprof.out --out ${dn}nytprof --no-flame &> ${dn}nytprofhtml.err
echo "group_contacts.pl ${n}-${lf}-${pcid}-${jaccard} finished" | mail -r matthew.betts@bioquant.uni-heidelberg.de -s "group_contacts.pl ${n}-${lf}-${pcid}-${jaccard} finished" matthew.betts@bioquant.uni-heidelberg.de

