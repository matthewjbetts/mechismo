export JOBS_DN=./root/static/data/jobs/
/usr/bin/time -o ${JOBS_DN}${MECHISMO_V}.DDX3X.time perl -I./lib ./script/fist_search.pl --outdir ${JOBS_DN} --id ${MECHISMO_V}.DDX3X --stringency low < ./root/static/data/examples/DDX3X.txt 1> ${JOBS_DN}${MECHISMO_V}.DDX3X.out 2> ${JOBS_DN}${MECHISMO_V}.DDX3X.err
