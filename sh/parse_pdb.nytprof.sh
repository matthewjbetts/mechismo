#!/bin/bash
idcode=$1
n=$2
dn=./temp/${idcode}/${n}/
fnPdb=$DS/pdb/${idcode:1:2}/pdb${idcode}.ent.gz
mkdir -p $dn
NYTPROF=file=${dn}nytprof.out perl -d:NYTProf -I./lib ./script/parse_pdb.pl --outdir $dn $fnPdb 1> ${dn}parse.out 2> ${dn}parse.err
nytprofhtml --file ${dn}nytprof.out --out ${dn}nytprof --no-flame &> ${dn}nytprofhtml.err
