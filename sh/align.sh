mkdir -p ./data/pfam/hmmalign/
/usr/bin/time -o ./data/pfam/hmmalign.time perl -I./lib ./script/hmmalign.pl --outdir ./data/pfam --fork hmmalign --n_jobs 8 --feat_source Pfam 1> ./data/pfam/hmmalign.out 2> ./data/pfam/hmmalign.err

mkdir -p ./data/align/frag/
/usr/bin/time -o ./data/align/frag/align.time perl -I./lib ./script/seqgroup_align.pl --type frag --outdir ./data/align/ --fork frag --n_jobs 8 1> ./data/align/frag/align.txt 2> ./data/align/frag/align.err

mkdir -p ./data/align/isoforms/
/usr/bin/time -o ./data/align/isoforms/align.time perl -I./lib ./script/seqgroup_align.pl --type isoforms --outdir ./data/align/ --fork isoforms --n_jobs 8 1> ./data/align/isoforms/align.txt 2> ./data/align/isoforms/align.err

mkdir -p ./data/align/uniref
/usr/bin/time -o ./data/align/uniref/align.time perl -I./lib ./script/seqgroup_align.pl --type 'uniref 100' --type 'uniref 90' --type 'uniref 50' --outdir ./data/align/ --fork uniref --n_jobs 8 1> ./data/align/uniref/align.txt 2> ./data/align/uniref/align.err
