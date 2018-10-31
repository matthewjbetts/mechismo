###### construction ######

# edit fist.conf to set the host, dbname, dbuser and dbpassword

# create the db and user
./script/create_db.pl bq_mbetts fist.conf

# load the schema
mysql -p -D [dbname] < sql/schema.sql


###### Testing and Profiling ######
# start the built-in server (mainly used for testing)
perl -I./lib ./script/fist_server.pl
# then point your browser at http://localhost:3000/

# profile the built-in server
export NYTPROF=sigexit=1
export DBIC_TRACE=1 # to see SQL statements executed
perl -d:NYTProf -I./lib ./script/fist_server.pl 1> fist_server.stdout 2> fist_server.stderr
nytprofhtml &> nytprofhtml.err

#name=nytprof
#NYTPROF=file=${name}.out perl -d:NYTProf -I./lib ./script/fist_server.pl 1> ${name}.stdout 2> ${name}.stderr
#nytprofhtml --file ${name}.out --out ${name}html &> ${name}_html.err

# Testing

# either:
perl Makefile.PL
make test

# or:
prove -l -r ./t

# Individual tests, eg:
prove -l t/schema/schema.t
perl -I./lib t/schema/schema.t

# re-run examples on the cluster
perl -ne 'chomp; print "UPDATE Job SET queue_name = \"mechismo_cluster\", status = \"queued\" WHERE id_search = \"$_\";\n";' /net/netfile2/ag-russell/mechismo/jobs/ids_of_examples.txt | mysql -p -D fistdb
ssh appl9
cd $GH/work/fist/branches/cluster
perl -e '$type = "long"; for($i = 1; $i <= 20; $i++){$id = sprintf "%03d", $i; open(PBS, ">cluster_queue.$type.$id.pbs") or die; print PBS "#PBS -N queue$id\n#PBS -m n\ncd \$GH/work/fist/branches/cluster/Fist/\nperl -I./lib ./script/fist_queue.pl --type $type --pid queue.pid\n"; close(PBS);}'
ls *.pbs | pbs_siesta.pl --wait 0
# qdel pbs fist_queue.pl jobs when mechismo jobs have finished


###### deploying the server ######

# copy the helper script to the proper location, ensure it is triggered on reboot, and start the app 
sudo cp ./script/fist_fastcgi.init /etc/init.d/fist
sudo /sbin/chkconfig --add fist
sudo /etc/init.d/fist restart


# set up virtual host in /etc/httpd/conf/httpd.conf
cat << EOF >> /etc/httpd/conf/httpd.conf

<VirtualHost *:80>
  ServerName mechismo.russelllab.org

  ####### Redirect to temporary error page ######
  #RewriteEngine on
  #RewriteRule ^/ http://www.russelllab.org/powercut/ [R=302]
  ##RewriteRule ^/(.*) http://www.russelllab.org/powercut/ [R=302]
  ###############################################

  Alias /static /var/www/catalyst_apps/mechismo/root/static
  <Directory /var/www/catalyst_apps/mechismo/root/static>
    allow from all
  </Directory>
  <Location "/static">
    SetHandler default-handler
  </Location>

  FastCgiExternalServer /net/netfile2/ag-russell/mechismo/processes/mechismo.fcgi -socket /net/netfile2/ag-russell/mechismo/processes/mechismo.socket -idle-timeout 300
  Alias / /net/netfile2/ag-russell/mechismo/processes/mechismo.fcgi/

  AddEncoding gzip .gz
  <FilesMatch "\.gz$">
    ForceType text/plain
    Header set Content-Encoding: gzip
  </FilesMatch>
</VirtualHost>

EOF

# FIXME - make graceful reload conditional on successful configtest 
sudo /etc/init.d/httpd/configtest
sudo /etc/init.d/httpd/graceful


####### Data Generation and Import ######

# FIXME - make sure all code is installed on all computers to be used (inc. all cluster nodes)

mysql -p -e 'CREATE DATABASE m2b;'
mysql -p -D m2b < sql/schema.sql
mkdir ./data

## Taxa
/usr/bin/time -o ./data/parse_taxa.time perl -I./lib/ ./script/parse_taxa.pl $DS/ncbi-taxonomy/names.dmp $DS/ncbi-taxonomy/nodes.dmp > ./data/Taxon.tsv
/usr/bin/time -o ./data/import_taxa.time perl -e 'print"Fist::IO::Taxon\tdata/Taxon.tsv\n"' | perl -I./lib ./script/import_tsv.pl 
gzip ./data/Taxon.tsv


## Structures
mkdir -p ./data/pdb
/usr/bin/time -o ./data/pdb/parse.time perl -I./lib ./script/parse_pdb.pl --outdir ./data/ --ecod $DS/ecod/ecod.latest.domains.txt --pbs pdb --n_jobs 1000 $DS/pdb 1> ./data/pdb/parse.txt 2> ./data/pdb/parse.err
# FIXME - check for PBS errors, re-run any affected files

# import
# NOTE: fist and seqres sequences are stored non-redundantly by the mapping method below
ls ./data/pdb/*/Ecod.tsv | head -1 | perl -ne '/.*\/(\S+)\.tsv/ and print"Fist::IO::$1\t$_";' > ./data/pdb/import.inp # Ecod.tsv was repeated for each job but only need to import once
ls ./data/pdb/*/Pdb.tsv | perl -ne '/(\d+)\/(\S+?)\./ and print"Fist::IO::$2\t$_";' >> ./data/pdb/import.inp
ls ./data/pdb/*/Expdta.tsv | perl -ne '/(\d+)\/(\S+?)\./ and print"Fist::IO::$2\t$_";' >> ./data/pdb/import.inp
ls ./data/pdb/*/Seq.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::Seq\t$_\tid={name=$1}\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/Frag.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::Frag\t$_\tid=$1,id_seq={name=$1}\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/ChainSegment.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::ChainSegment\t$_\tid=$1,id_frag=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/SeqToTaxon.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::SeqToTaxon\t$_\tid_seq={name=$1}\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/SeqGroup.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::SeqGroup\t$_\tid=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/SeqToGroup.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::SeqToGroup\t$_\tid_seq={name=$1},id_group=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/FragToSeqGroup.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::FragToSeqGroup\t$_\tid_frag=$1,id_group=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/FragDssp.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::FragDssp\t$_\tid_frag=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/FragNaccess.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::FragNaccess\t$_\tid_frag=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/FragToEcod.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::FragToEcod\t$_\tid_frag=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/FragResMapping.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::FragResMapping\t$_\tid_frag=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/FragInst.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::FragInst\t$_\tid=$1,id_frag=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/Contact.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::Contact\t$_\tid=$1,id_frag_inst=$1\n";' >> ./data/pdb/import.inp
ls ./data/pdb/*/ResContact.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::ResContact\t$_\tid_contact=$1\n";' >> ./data/pdb/import.inp
/usr/bin/time -o ./data/pdb/import.time perl -I./lib ./script/import_tsv.pl < ./data/pdb/import.inp &> ./data/pdb/import.err

# archive the text files


## UniProt (sprot and varsplic)
mkdir -p ./data/uniprot/sprot
/usr/bin/time -o ./data/uniprot/sprot/parse.time perl -I./lib ./script/parse_uniprot.pl --outdir ./data/uniprot/sprot/ --varsplic /net/netfile1/ds-russell/uniprot/knowledgebase/complete/uniprot_sprot_varsplic.fasta.gz /net/netfile1/ds-russell/uniprot/knowledgebase/complete/uniprot_sprot.dat.gz 1> ./data/uniprot/sprot/parse.txt 2> ./data/uniprot/sprot/parse.err

# import - need to map sequence ids to new ids so as not to clash with ids already in db
echo -e "Fist::IO::Seq\t./data/uniprot/sprot/Seq.tsv\tid=01" > ./data/uniprot/sprot/import.inp
echo -e "Fist::IO::SeqToTaxon\t./data/uniprot/sprot/SeqToTaxon.tsv\tid_seq=01" >> ./data/uniprot/sprot/import.inp
echo -e "Fist::IO::SeqGroup\t./data/uniprot/sprot/SeqGroup.tsv\tid=01" >> ./data/uniprot/sprot/import.inp
echo -e "Fist::IO::SeqToGroup\t./data/uniprot/sprot/SeqToGroup.tsv\tid_group=01,id_seq=01" >> ./data/uniprot/sprot/import.inp
echo -e "Fist::IO::Alias\t./data/uniprot/sprot/Alias.tsv\tid_seq=01" >> ./data/uniprot/sprot/import.inp
echo -e "Fist::IO::Feature\t./data/uniprot/sprot/Feature.tsv\tid=01" >> ./data/uniprot/sprot/import.inp
echo -e "Fist::IO::FeatureInst\t./data/uniprot/sprot/FeatureInst.tsv\tid=01,id_feature=01,id_seq=01" >> ./data/uniprot/sprot/import.inp
echo -e "Fist::IO::PmidToFeatureInst\t./data/uniprot/sprot/PmidToFeatureInst.tsv\tid_feature_inst=01" >> ./data/uniprot/sprot/import.inp
/usr/bin/time -o ./data/uniprot/sprot/import.time perl -I./lib ./script/import_tsv.pl < ./data/uniprot/sprot/import.inp &> ./data/uniprot/sprot/import.err

# archive the text files

## NOTE: need to extract seqs from db, as below, rather than using Seq.tsv files generated
## above, since the ids in those are only unique to the specific fork / pbs job, and not
## overall, and the import also stores fist and seqres sequences non-redundantly


## extract fasta format fist and seqres sequences with database ids
/usr/bin/time -o ./data/pdb/fist_aa.time perl -I./lib ./script/get_fasta.pl --chemical_type peptide --source fist > data/pdb/fist_aa.fasta
/usr/bin/time -o ./data/pdb/seqres_aa.time perl -I./lib ./script/get_fasta.pl --chemical_type peptide --source seqres > data/pdb/seqres_aa.fasta


## extract fasta format fist nucleotide sequences with database ids
/usr/bin/time -o ./data/pdb/fist_aa.time perl -I./lib ./script/get_fasta.pl --chemical_type nucleotide --source fist > data/pdb/fist_na.fasta


## get mapping of uniprot accessions to other identifiers
/usr/bin/time -o ./data/uniprot/id_mapping.time zcat /net/netfile1/ds-russell/uniprot/knowledgebase/idmapping/idmapping.dat.gz | perl -I./lib script/uniprot_mapping.pl 1> ./data/uniprot/id_mapping.tsv 2> ./data/uniprot/id_mapping.err
/usr/bin/time -o ./data/uniprot/id_mapping.import.time perl -e 'print"Fist::IO::Alias\t./data/uniprot/id_mapping.tsv\tid_seq=DB\n";' | perl -I./lib ./script/import_tsv.pl &> ./data/uniprot/id_mapping.import.err
gzip ./data/uniprot/id_mapping.tsv


## extract fasta format sprot and varsplic sequences with database ids for the taxa of interest
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  /usr/bin/time -o ./data/uniprot/sprot/${id_taxon}_aa.time perl -I./lib ./script/get_fasta.pl --chemical_type peptide --source 'uniprot-sprot' --source varsplic --taxon $id_taxon > data/uniprot/sprot/${id_taxon}_aa.fasta &
done


## use SIFTS mapping to add uniprot accessions to fragment seq groups
mkdir -p ./data/sifts
/usr/bin/time -o ./data/sifts/sifts.time perl -I./lib ./script/parse_sifts.pl < /net/netfile1/ds-russell/sifts/text/pdb_chain_uniprot.lst 1> ./data/sifts/sifts.tsv 2> ./data/sifts/parse.err
/usr/bin/time -o ./data/sifts/import.time perl -e 'print"Fist::IO::SeqToGroup\tdata/sifts/sifts.tsv\n";' | perl -I./lib ./script/import_tsv.pl &> ./data/sifts/import.err


## blast dbs of Frag fist and seqres aa sequences
mkdir -p ./data/blast/
formatdb -t fist -i data/pdb/fist_aa.fasta -p T -n ./data/blast/fist
formatdb -t seqres -i data/pdb/seqres_aa.fasta -p T -n ./data/blast/seqres
formatdb -t fist -i data/pdb/fist_na.fasta -p F -n ./data/blast/fist_na


## blast fist vs fist
mkdir -p ./data/blast/fist-fist
/usr/bin/time -o ./data/blast/fist-fist/blast.time perl -I./lib ./script/blast.pl --program blastp --outdir ./data/blast/ --pbs fist-fist --n_jobs 30 --db ./data/blast/fist --fasta data/pdb/fist_aa.fasta --no_self 1> ./data/blast/fist-fist/blast.out 2> ./data/blast/fist-fist/blast.err

mkdir -p ./data/blast/fist_na-fist_na
/usr/bin/time -o ./data/blast/fist_na-fist_na/blast.time perl -I./lib ./script/blast.pl --program blastn --outdir ./data/blast/fist_na-fist_na --db ./data/blast/fist_na --fasta data/pdb/fist_na.fasta --no_self 1> ./data/blast/fist_na-fist_na/blast.out 2> ./data/blast/fist_na-fist_na/blast.err


## blast uniprot sprot and varsplic vs fist
#for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
#do
#  mkdir -p ./data/blast/sprot_varsplic-fist/${id_taxon}
#  /usr/bin/time -o ./data/blast/sprot_varsplic-fist/${id_taxon}/blast.time perl -I./lib ./script/blast.pl --program blastp --outdir ./data/blast/sprot_varsplic-fist --pbs $id_taxon --n_jobs 100 --db ./data/blast/fist --fasta ./data/uniprot/sprot/${id_taxon}_aa.fasta 1> ./data/blast/sprot_varsplic-fist/${id_taxon}/blast.out 2> ./data/blast/sprot_varsplic-fist/${id_taxon}/blast.err &
#done

mkdir -p ./data/blast/sprot_varsplic-fist/
/usr/bin/time -o ./data/blast/sprot_varsplic-fist/blast.time perl -I./lib ./script/blast.pl --program blastp --outdir ./data/blast/ --pbs sprot_varsplic-fist --n_jobs 30 --db ./data/blast/fist \
--fasta ./data/uniprot/sprot/272634_aa.fasta \
--fasta ./data/uniprot/sprot/224308_aa.fasta \
--fasta ./data/uniprot/sprot/83333_aa.fasta \
--fasta ./data/uniprot/sprot/559292_aa.fasta \
--fasta ./data/uniprot/sprot/6239_aa.fasta \
--fasta ./data/uniprot/sprot/7227_aa.fasta \
--fasta ./data/uniprot/sprot/10090_aa.fasta \
--fasta ./data/uniprot/sprot/9606_aa.fasta \
1> ./data/blast/sprot_varsplic-fist/blast.out 2> ./data/blast/sprot_varsplic-fist/blast.err &


## blast uniprot sprot and varsplic vs seqres
#for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
#do
#  mkdir -p ./data/blast/sprot_varsplic-seqres/${id_taxon}
#  /usr/bin/time -o ./data/blast/sprot_varsplic-seqres/${id_taxon}/blast.time perl -I./lib ./script/blast.pl --program blastp --outdir ./data/blast/sprot_varsplic-seqres --pbs $id_taxon --n_jobs 100 --db ./data/blast/seqres --fasta ./data/uniprot/sprot/${id_taxon}_aa.fasta 1> ./data/blast/sprot_varsplic-seqres/${id_taxon}/blast.out 2> ./data/blast/sprot_varsplic-seqres/${id_taxon}/blast.err &
#done

mkdir -p ./data/blast/sprot_varsplic-seqres/${id_taxon}
/usr/bin/time -o ./data/blast/sprot_varsplic-seqres/blast.time perl -I./lib ./script/blast.pl --program blastp --outdir ./data/blast/ --pbs sprot_varsplic-seqres --n_jobs 30 --db ./data/blast/seqres \
--fasta ./data/uniprot/sprot/272634_aa.fasta \
--fasta ./data/uniprot/sprot/224308_aa.fasta \
--fasta ./data/uniprot/sprot/83333_aa.fasta \
--fasta ./data/uniprot/sprot/559292_aa.fasta \
--fasta ./data/uniprot/sprot/6239_aa.fasta \
--fasta ./data/uniprot/sprot/7227_aa.fasta \
--fasta ./data/uniprot/sprot/10090_aa.fasta \
--fasta ./data/uniprot/sprot/9606_aa.fasta \
1> ./data/blast/sprot_varsplic-seqres/blast.out 2> ./data/blast/sprot_varsplic-seqres/blast.err &


## import blast results
find ./data/blast/{fist-fist,fist_na-fist_na,sprot_varsplic-fist,sprot_varsplic-seqres} -name Alignment.tsv | perl -ne 'chomp; /blast\/(\S+)\// and print "Fist::IO::Alignment\t$_\tid=$1\n";' > ./data/blast/import.inp
find ./data/blast/{fist-fist,fist_na-fist_na,sprot_varsplic-fist,sprot_varsplic-seqres} -name AlignedSeq.tsv | perl -ne 'chomp; /blast\/(\S+)\// and print "Fist::IO::AlignedSeq\t$_\tid_aln=$1,id_seq=DB\n";' >> ./data/blast/import.inp
find ./data/blast/{fist-fist,fist_na-fist_na,sprot_varsplic-fist,sprot_varsplic-seqres} -name Hsp.tsv | perl -ne 'chomp; /blast\/(\S+)\// and print "Fist::IO::Hsp\t$_\tid=$1,id_seq=DB,id_aln=$1\n";' >> ./data/blast/import.inp
/usr/bin/time -o ./data/blast/import.time perl -I./lib ./script/import_tsv.pl < ./data/blast/import.inp &> ./data/blast/import.err


# archive text files


## iupred

# add iupred long feature to db
# FIXME - standardise adding of features, eg. from a file including iupred, pfam, etc
mysql -p -D m2b -e 'INSERT INTO Feature (source, ac_src, description) VALUES("iupred", "long", "iupred long disorder over a sliding window of size 11")'

# run iupred on all fist sequences
mkdir -p ./data/iupred/fist/
/usr/bin/time -o ./data/iupred/fist/iupred.time perl -I./lib ./script/iupred.pl --outdir ./data/iupred/ --fork fist --source fist --source varsplic 1> ./data/iupred/fist/iupred.out 2> ./data/iupred/fist/iupred.err

# run iupred on uniprot-sprot sequences from species of interest
mkdir -p ./data/iupred/uniprot/sprot_varsplic/
/usr/bin/time -o ./data/iupred/uniprot/sprot_varsplic/iupred.time perl -I./lib ./script/iupred.pl --outdir ./data/iupred/uniprot --fork sprot_varsplic --source 'uniprot-sprot' --source varsplic --taxon 272634 --taxon 224308 --taxon 83333 --taxon 559292 --taxon 6239 --taxon 7227 --taxon 10090 --taxon 9606 1> ./data/iupred/uniprot/sprot_varsplic/iupred.out 2> ./data/iupred/uniprot/sprot_varsplic/iupred.err

# import fist iupred and other iupred at the same time
ls ./data/iupred/fist/*/FeatureInst.tsv ./data/iupred/uniprot/sprot_varsplic/*/FeatureInst.tsv | perl -ne 'chomp; /data\/iupred\/(\S+)\/FeatureInst\.tsv/ and print"Fist::IO::FeatureInst\t$_\tid=$1,id_seq=DB,id_feature=DB\n";' > ./data/iupred/import.inp
/usr/bin/time -o ./data/iupred/import.time perl -I./lib ./script/import_tsv.pl < ./data/iupred/import.inp &> ./data/iupred/import.err


## Pfam

# add Pfam domains as features
mkdir -p ./data/pfam/
zless $DS/Pfam/Pfam-A.hmm.gz | perl -ne 'if(/^NAME  (\S+)/){$id = $1;}elsif(/^ACC   (\S+)/){$ac = $1; $ac =~ s/\.\d+\Z//;}elsif(/^DESC  (.*)\s*\Z/){$de .= "$1 ";}elsif(/^\/{2}/){print join("\t", "Pfam", $ac, $id, $de), "\n"; $de = "";}' > ./data/pfam/pfam.tsv
mysql -p -D m2b -e 'LOAD DATA LOCAL INFILE "./data/pfam/pfam.tsv" INTO TABLE Feature (source, ac_src, id_src, description);'

# find Pfam domains in fist sequences
mkdir -p ./data/pfam/fist
/usr/bin/time -o ./data/pfam/fist/hmmscan.time perl -I./lib script/hmmscan.pl --cut_ga --outdir ./data/pfam/ --pbs fist --n_jobs 30 --source fist 1> ./data/pfam/fist/hmmscan.out 2> ./data/pfam/fist/hmmscan.err

# find Pfam domains in UniProt sequences from species of interest
# (UniProt entries do not give the positions of Pfam domains
# for some reason... so have to run hmmscan myself.)
mkdir -p ./data/pfam/uniprot/sprot_varsplic
/usr/bin/time -o ./data/pfam/uniprot/sprot_varsplic/hmmscan.time perl -I./lib script/hmmscan.pl --cut_ga --outdir ./data/pfam/uniprot/ --pbs sprot_varsplic --n_jobs 30 --source 'uniprot-sprot' --source 'varsplic' --taxon 272634 --taxon 224308 --taxon 83333 --taxon 559292 --taxon 6239 --taxon 7227 --taxon 10090 --taxon 9606 1> ./data/pfam/uniprot/sprot_varsplic/hmmscan.out 2> ./data/pfam/uniprot/sprot_varsplic/hmmscan.err


# import
find ./data/pfam/ -name FeatureInst.tsv | perl -ne 'chomp; /data\/pfam\/(\S+)\/FeatureInst\.tsv/ and print"Fist::IO::FeatureInst\t$_\tid=$1,id_seq=DB,id_feature=DB\n";' > ./data/pfam/import.inp
/usr/bin/time -o ./data/pfam/import.time perl -I./lib ./script/import_tsv.pl < ./data/pfam/import.inp &> ./data/pfam/import.err

# archive

## align subsequences that match to each pfam domain
mkdir -p ./data/pfam/hmmalign/
/usr/bin/time -o ./data/pfam/hmmalign.time perl -I./lib ./script/hmmalign.pl --outdir ./data/pfam --pbs hmmalign --n_jobs 200 --feat_source Pfam 1> ./data/pfam/hmmalign.out 2> ./data/pfam/hmmalign.err

# import
ls ./data/pfam/hmmalign/*/SeqGroup.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::SeqGroup\t$_\tid=$1\n";' > ./data/pfam/hmmalign/import.inp
ls ./data/pfam/hmmalign/*/SeqToGroup.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::SeqToGroup\t$_\tid_seq=DB,id_group=$1\n";' >> ./data/pfam/hmmalign/import.inp
ls ./data/pfam/hmmalign/*/Alignment.tsv | perl -ne 'chomp; /(\d+)/ and print "Fist::IO::Alignment\t$_\tid=$1\n";' >> ./data/pfam/hmmalign/import.inp
ls ./data/pfam/hmmalign/*/AlignedSeq.tsv | perl -ne 'chomp; /(\d+)/ and print "Fist::IO::AlignedSeq\t$_\tid_aln=$1,id_seq=DB\n";' >> ./data/pfam/hmmalign/import.inp
ls ./data/pfam/hmmalign/*/AlignmentToGroup.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::AlignmentToGroup\t$_\tid_aln=$1,id_group=$1\n";' >> ./data/pfam/hmmalign/import.inp
/usr/bin/time -o ./data/pfam/hmmalign/import.time perl -I./lib/ ./script/import_tsv.pl < ./data/pfam/hmmalign/import.inp &> ./data/pfam/hmmalign/import.err


## parse and import uniref
for level in 100 90 50
do
  mkdir -p ./data/uniref/${level}/
  /usr/bin/time -o ./data/uniref/${level}/parse.time perl -I./lib ./script/parse_uniref.pl --outdir ./data/uniref/${level}/ ${level} /net/netfile1/ds-russell/uniprot/uniref/uniref${level}/uniref${level}.xml.gz 1> ./data/uniref/${level}/parse.txt 2> ./data/uniref/${level}/parse.err &
done

ls ./data/uniref/*/SeqGroup.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::SeqGroup\t$_\tid=$1\n";' > ./data/uniref/import.inp
ls ./data/uniref/*/SeqToGroup.tsv | perl -ne 'chomp; /(\d+)/ and print"Fist::IO::SeqToGroup\t$_\tid_seq=DB,id_group=$1\n";' >> ./data/uniref/import.inp
/usr/bin/time -o ./data/uniref/import.time perl -I./lib ./script/import_tsv.pl < ./data/uniref/import.inp &> ./data/uniref/import.err


###### REDO ######

## align fragment seq groups
# FIXME - muscle fails silently on sequences >~ 10000 aa long
mkdir -p ./data/align/frag/
#/usr/bin/time -o ./data/align/frag/align.time perl -I./lib ./script/seqgroup_align.pl --type frag --outdir ./data/align/ --pbs frag --n_jobs 50 1> ./data/align/frag/align.txt 2> ./data/align/frag/align.err
/usr/bin/time -o ./data/align/frag/align.time perl -I./lib ./script/seqgroup_align.pl --type frag --outdir ./data/align/frag 1> ./data/align/frag/align.txt 2> ./data/align/frag/align.err

# delete existing alignments of fragment seq groups from db
# upload new alignments
# FIXME - redo contact hits
# FIXME - delete old contact hits from db
# FIXME - upload new contact hits
# FIXME - run Francesco's searches
# FIXME - re-run searches

###################


## align isoform seq groups
# FIXME - muscle fails silently on sequences >~ 10000 aa long
mkdir -p ./data/align/isoforms/
/usr/bin/time -o ./data/align/isoforms/align.time perl -I./lib ./script/seqgroup_align.pl --type isoforms --outdir ./data/align/ --pbs isoforms --n_jobs 50 1> ./data/align/isoforms/align.txt 2> ./data/align/isoforms/align.err


## align uniref sequence groups
# FIXME - muscle fails silently on sequences >~ 10000 aa long
mkdir -p ./data/align/uniref
/usr/bin/time -o ./data/align/uniref/align.time perl -I./lib ./script/seqgroup_align.pl --type 'uniref 100' --type 'uniref 90' --type 'uniref 50' --outdir ./data/align/ --pbs uniref --n_jobs 50 1> ./data/align/uniref/align.txt 2> ./data/align/uniref/align.err


## import seq group alignments
## (more efficient to import them all at the same time)
ls ./data/align/{frag,isoforms,uniref}/*/Alignment.tsv | perl -ne 'chomp;/.*\/(\S+)\/(\d+)/ and print"Fist::IO::Alignment\t$_\tid=$1$2\n";' > ./data/align/import.inp
ls ./data/align/{frag,isoforms,uniref}/*/AlignedSeq.tsv | perl -ne 'chomp;/.*\/(\S+)\/(\d+)/ and print"Fist::IO::AlignedSeq\t$_\tid_aln=$1$2,id_seq=DB\n";' >> ./data/align/import.inp
ls ./data/align/{frag,isoforms,uniref}/*/AlignmentToGroup.tsv | perl -ne 'chomp;/.*\/(\S+)\/(\d+)/ and print"Fist::IO::AlignmentToGroup\t$_\tid_aln=$1$2,id_group=DB\n";' >> ./data/align/import.inp
/usr/bin/time -o ./data/align/import.time perl -I./lib/ ./script/import_tsv.pl < ./data/align/import.inp &> ./data/align/import.err


## group similar sequences
# NOTE: pcid of 00 is implicit e-value threshold of 1e-4, the e value threshold when running blast (above)

lf=0.9
for pcid in 90 70 50 00
do
  mkdir -p ./data/seq_groups/fist_lf${lf}_pcid${pcid}/
  /usr/bin/time -o ./data/seq_groups/fist_lf${lf}_pcid${pcid}/group.time perl -I./lib ./script/group_sequences.pl --source fist --lf ${lf} --pcid ${pcid} --outdir ./data/seq_groups/fist_lf${lf}_pcid${pcid}/ &> ./data/seq_groups/fist_lf${lf}_pcid${pcid}/group.err &
done

# 'lf 0.5, pcid 50' for later marking of (pseudo)homodimeric contacts
lf=0.5
for pcid in 50
do
  mkdir -p ./data/seq_groups/fist_lf${lf}_pcid${pcid}/
  /usr/bin/time -o ./data/seq_groups/fist_lf${lf}_pcid${pcid}/group.time perl -I./lib ./script/group_sequences.pl --source fist --lf ${lf} --pcid ${pcid} --outdir ./data/seq_groups/fist_lf${lf}_pcid${pcid}/ &> ./data/seq_groups/fist_lf${lf}_pcid${pcid}/group.err &
done

## FIXME - also group by ecod domains


# NOTE: fist sequences are stored non-redundantly (if imported by the
# method used above), so no need to form 'fist lf=1.0 pcid=100.0' groups

# import
ls ./data/seq_groups/fist_lf*_pcid*/SeqGroup.tsv | perl -ne 'chomp; /(lf\S+_pcid\d+)/ and print"Fist::IO::SeqGroup\t$_\tid=$1\n";' > ./data/seq_groups/import.inp
ls ./data/seq_groups/fist_lf*_pcid*/SeqToGroup.tsv | perl -ne 'chomp; /(lf\S+_pcid\d+)/ and print"Fist::IO::SeqToGroup\t$_\tid_seq=DB,id_group=$1\n";' >> ./data/seq_groups/import.inp
/usr/bin/time -o ./data/seq_groups/import.time perl -I./lib ./script/import_tsv.pl < ./data/seq_groups/import.inp &> ./data/seq_groups/import.err


## mark homodimeric contacts (this depends on SeqGroup.type IN ('frag', 'fist lf=0.5 pcid=50.0')
/usr/bin/time -o ./data/pdb/homo.time perl -I./lib ./script/contacts_homo.pl &> ./data/pdb/homo.err


## group PPI, PDI and PCI contacts
/usr/bin/time -o ./data/fist_vs_fist_aseqs.time mysql -u anonymous -D m2b --quick --skip-column-names < sql/get_fist_vs_fist_aseqs.sql 2> ./data/fist_vs_fist_aseqs.err | gzip > ./data/fist_vs_fist_aseqs.tsv.gz &
/usr/bin/time -o ./data/frag_inst_to_fist.time mysql -u anonymous -D m2b --quick --skip-column-names < sql/get_frag_inst_to_fist.sql 2> ./data/frag_inst_to_fist.err | gzip > ./data/frag_inst_to_fist.tsv.gz &
/usr/bin/time -o ./data/frag_inst_chem_type.time mysql -u anonymous -D m2b --quick --skip-column-names < sql/get_frag_inst_chem_type.sql 2> ./data/frag_inst_chem_type.err | gzip > ./data/frag_inst_chem_type.tsv.gz &
/usr/bin/time -o ./data/contacts_with_fist_numbers.time mysql -u anonymous -D m2b --quick --skip-column-names < sql/get_contacts_with_fist_numbers.sql | ./script/contacts_with_fist_numbers_one_per_line.pl 1> > ./data/contacts_with_fist_numbers.tsv 2> ./data/contacts_with_fist_numbers.err &
gzip ./data/contacts_with_fist_numbers.tsv



# FIXME - compile groupContacts for cluster OSs
# create PBS jobs
mkdir -p ./data/contact_groups

perl -e 'BEGIN{$d = qx(pwd); chomp($d); $d .= "/"; $d2 = "data/contact_groups/";}foreach $th ([1.0, 1.0, 1.0], [0.0, 0.8, 0.8], [0.0, 0.0, 0.8]){$id = sprintf "%.1f-%.1f-%.1f", @{$th}; $fn = "${d}${d2}${id}.pbs"; open(PBS, ">$fn") or die $fn; print "$fn\n"; printf PBS "#PBS -N gc${id}\n#PBS -o ${d}${d2}${id}.stdout\n#PBS -e ${d}${d2}${id}.stderr\n#PBS -l nodes=1:ppn=1\n#PBS -l mem=40gb\n#PBS -m ae\n#PBS -M matthew.betts\@bioquant.uni-heidelberg.de\n/usr/bin/time -o ${d}${d2}${id}.time ${d}c/mechismoGroupContacts --contacts ${d}data/contacts_with_fist_numbers.tsv.gz --hsps ${d}data/fist_vs_fist_aseqs.tsv.gz --dom_to_seq ${d}data/frag_inst_to_fist.tsv.gz --pcid %.1f --lf %.1f --jaccard %.1f --contact_group ${d}${d2}${id}.ContactGroup.tsv --contact_to_group ${d}${d2}${id}.ContactToGroup.tsv\n\n", @{$th}; close(PBS);}'


# now submit on cluster

# ensure id_group is in ascending order (needed for id_mapping with offsets to work).
# could output this way from mechismoGroupContacts but is nice to see jaccard
# sub groups immediately after contacts grouped by sequence
ls data/contact_groups/*.ContactGroup.tsv | perl -ne 'chomp; system("sort -n -k +1 -o $_ $_");'
ls data/contact_groups/*.ContactToGroup.tsv | perl -ne 'chomp; system("sort -n -k +2 -o $_ $_");'


# import
ls ./data/contact_groups/*.ContactGroup.tsv | perl -ne 'chomp; /.*\/(\S+)\.ContactGroup.tsv/ and print"Fist::IO::ContactGroup\t$_\tid=$1\n";' > ./data/contact_groups/import.inp
ls ./data/contact_groups/*.ContactToGroup.tsv | perl -ne 'chomp; /.*\/(\S+)\.ContactToGroup.tsv/ and print"Fist::IO::ContactToGroup\t$_\tid_group=$1,id_contact=DB\n";' >> ./data/contact_groups/import.inp
/usr/bin/time -o ./data/contact_groups/import.time perl -I./lib ./script/import_tsv.pl < ./data/contact_groups/import.inp &> ./data/contact_groups/import.err


# now extract just the jaccard groups, not the ones that use only sequence matching (which are included in the above output)
# FIXME - mechismoGroupContacts could output these to separate files, or other progs could ignore the ones they don't need, or
# I could extract from the db
ls ./data/contact_groups/*.ContactGroup.tsv | perl -ne 'chomp; $f1 = $_; ($f2 = $f1) =~ s/ContactGroup/ContactToGroup/; ($f3 = $f1) =~ s/ContactGroup/only.ContactToGroup/; open(I, $f1) or die; %S = (); while(<I>){chomp; @F = split /\t/; /jaccard/ and $S{$F[0]}++;}close(I); open(O, ">$f3") or die; open(I, $f2) or die; while(<I>){@F = split; defined($S{$F[1]}) and print(O $_);}close(I);close(O);'


# archive
gzip ./data/contact_groups/*.{ContactGroup,ContactToGroup}.tsv


## measure interface overlap in known structures (aka. how bad is only using distance between atoms as the definition of an interface?)
perl -I./lib ./script/known_structures_interface_overlap.pl 2> ./data/known_structures_interface_overlap.err | gzip > ./data/known_structures_interface_overlap.tsv.gz &


########## TESTING mechismoGroupContacts, AND GROUPING WITH OTHER IDs ##########

# test runs: 
./c/mechismoGroupContacts --contacts ./data/contacts_with_fist_numbers.1000.tsv.gz --hsps ./data/fist_vs_fist_aseqs.1000.tsv.gz --dom_to_seq ./data/frag_inst_to_fist.1000.tsv.gz
./c/mechismoGroupContacts --contacts ./data/contacts_with_fist_numbers.cg531629.tsv.gz --hsps ./data/fist_vs_fist_aseqs.cg531629.tsv.gz --dom_to_seq ./data/frag_inst_to_fist.cg531629.tsv.gz
./c/mechismoGroupContacts --contacts ./data/contacts_with_fist_numbers.tsv.gz --hsps ./data/fist_vs_fist_aseqs.tsv.gz --dom_to_seq ./data/frag_inst_to_fist.tsv.gz


# using ECOD domain identifiers and STAMP format domain descriptions:
/usr/bin/time -o ./data/frag_inst_to_fist.ecod.time mysql -u anonymous -D m2b --quick --skip-column-names < sql/get_frag_inst_to_fist.ecod.sql 2> ./data/frag_inst_to_fist.ecod.err | gzip > ./data/frag_inst_to_fist.ecod.tsv.gz &
/usr/bin/time -o ./data/contacts_with_fist_numbers.ecod.time mysql -u anonymous -D m2b --quick --skip-column-names < sql/get_contacts_with_fist_numbers.ecod.sql | ./script/contacts_with_fist_numbers_one_per_line.pl 2> ./data/contacts_with_fist_numbers.ecod.err | gzip > ./data/contacts_with_fist_numbers.ecod.tsv.gz &
./c/mechismoGroupContacts --contacts data/contacts_with_fist_numbers.ecod.1000.tsv.gz --hsps data/fist_vs_fist_aseqs.ecod.1000.tsv.gz --dom_to_seq data/frag_inst_to_fist.ecod.1000.tsv.gz

mkdir -p ./data/contact_groups/ecod
perl -e 'BEGIN{$d = qx(pwd); chomp($d); $d .= "/"; $d2 = "data/contact_groups/ecod/";}foreach $th ([100.0, 1.0, 1.0], [100.0, 0.9, 0.9], [90.0, 0.9, 0.9], [70.0, 0.9, 0.9], [50.0, 0.9, 0.9], [0.0, 0.9, 0.9]){$id = sprintf "%.1f-%.1f-%.1f", @{$th}; $fn = "${d}${d2}${id}.pbs"; open(PBS, ">$fn") or die $fn; printf PBS "#PBS -N gc${id}\n#PBS -o /dev/null\n#PBS -e ${d}${d2}${id}.stderr\n#PBS -l nodes=1:ppn=1\n#PBS -l mem=20gb\n#PBS -m ae\n#PBS -M matthew.betts\@bioquant.uni-heidelberg.de\n${d}c/mechismoGroupContacts --contacts ${d}data/contacts_with_fist_numbers.ecod.tsv.gz --hsps ${d}data/fist_vs_fist_aseqs.tsv.gz --dom_to_seq ${d}data/frag_inst_to_fist.ecod.tsv.gz --pcid %.1f --lf %.1f --jaccard %.1f | gzip > ${d}${d2}${id}.txt.gz\n\n", @{$th}; close(PBS);}'
# now submit on cluster


# using STAMP format domain descriptions
/usr/bin/time -o ./data/frag_inst_to_fist.idcode.time mysql -u anonymous -D m2b --quick --skip-column-names < sql/get_frag_inst_to_fist.idcode.sql 2> ./data/frag_inst_to_fist.idcode.err | gzip > ./data/frag_inst_to_fist.idcode.tsv.gz &
/usr/bin/time -o ./data/contacts_with_fist_numbers.idcode.time mysql -u anonymous -D m2b --quick --skip-column-names < sql/get_contacts_with_fist_numbers.idcode.sql | ./script/contacts_with_fist_numbers_one_per_line.pl 2> ./data/contacts_with_fist_numbers.idcode.err | gzip > ./data/contacts_with_fist_numbers.idcode.tsv.gz &

mkdir -p ./data/contact_groups/idcode
perl -e 'BEGIN{$d = qx(pwd); chomp($d); $d .= "/"; $d2 = "data/contact_groups/idcode/";}foreach $th ([100.0, 1.0, 1.0], [100.0, 0.9, 0.9], [90.0, 0.9, 0.9], [70.0, 0.9, 0.9], [50.0, 0.9, 0.9], [0.0, 0.9, 0.9]){$id = sprintf "%.1f-%.1f-%.1f", @{$th}; $fn = "${d}${d2}${id}.pbs"; open(PBS, ">$fn") or die $fn; printf PBS "#PBS -N gc${id}\n#PBS -o /dev/null\n#PBS -e ${d}${d2}${id}.stderr\n#PBS -l nodes=1:ppn=1\n#PBS -l mem=20gb\n#PBS -m ae\n#PBS -M matthew.betts\@bioquant.uni-heidelberg.de\n${d}c/mechismoGroupContacts --contacts ${d}data/contacts_with_fist_numbers.idcode.tsv.gz --hsps ${d}data/fist_vs_fist_aseqs.tsv.gz --dom_to_seq ${d}data/frag_inst_to_fist.idcode.tsv.gz --pcid %.1f --lf %.1f --jaccard %.1f | gzip > ${d}${d2}${id}.txt.gz\n\n", @{$th}; close(PBS);}'
# now submit on cluster

################################################################################


## load ELM features # FIXME - standardise adding of features, eg. from a file including iupred, pfam, etc
mkdir -p ./data/elm/db/

wget -q http://elm.eu.org/elms/elms_index.tsv -O ./data/elm/db/elm_classes.tsv
dos2unix ./data/elm/db/elm_classes.tsv
perl -i -pe 's/"//g' ./data/elm/db/elm_classes.tsv
perl -F'/\t/' -nae '/^#/ and next; chomp(@F); if(/^Accession/){@headings = @F;}else{@hash{@headings} = @F; print join("\t", "elm", $hash{Accession}, $hash{ELMIdentifier}, $hash{Description}, $hash{Regex}), "\n";}' data/elm/db/elm_classes.tsv > ./data/elm/db/elm_classes_tmp.tsv
mysql -p -D m2b -e 'SET sql_log_bin = 0; LOAD DATA LOCAL INFILE "./data/elm/db/elm_classes_tmp.tsv" INTO TABLE Feature (source, ac_src, id_src, description, regex);'
rm -f data/elm/db/elm_classes_tmp.tsv

wget -q 'http://elm.eu.org/instances.tsv?q=*' -O ./data/elm/db/elm_instances.tsv
dos2unix ./data/elm/db/elm_instances.tsv
perl -i -pe 's/"//g' ./data/elm/db/elm_instances.tsv


## get elm instances by regex pattern matching, label true positives from ./data/elm/db/elm_instances.tsv
mkdir -p ./data/elm/uniprot/sprot_varsplic/
/usr/bin/time -o ./data/elm/uniprot/sprot_varsplic/FeatureInst.time perl -I./lib ./script/get_elm_instances.pl --source 'uniprot-sprot' --source varsplic  --taxon 272634 --taxon 224308 --taxon 83333 --taxon 559292 --taxon 6239 --taxon 7227 --taxon 10090 --taxon 9606 ./data/elm/db/elm_instances.tsv 1> ./data/elm/uniprot/sprot_varsplic/FeatureInst.tsv 2> ./data/elm/uniprot/sprot_varsplic/FeatureInst.err

# import
perl -e 'print "Fist::IO::FeatureInst\t./data/elm/uniprot/sprot_varsplic/FeatureInst.tsv\tid=01,id_seq=DB,id_feature=DB\n";' > ./data/elm/uniprot/sprot_varsplic/import.inp
/usr/bin/time -o ./data/elm/uniprot/sprot_varsplic/import.time perl -I./lib ./script/import_tsv.pl < ./data/elm/uniprot/sprot_varsplic/import.inp &> ./data/elm/uniprot/sprot_varsplic/import.err

# archive


## hierarchical uniprot to fist matching

# 1) For each uniprot, find all matches to fist sequences from these sources:
#
#    a) SIFTS - frag group alignments
#    b) BLAST vs fist
#    c) BLAST vs seqres - and then to fist via frag group alignment
#    d) Pfam - uniprot and fist seq have common pfam domain, map position using pfam seq group alignment
#
# 2) For each uniprot - fist pair, prefer the alignments in that order
#
# 3) When that is done, find pairs of uniprots that hit the same idcode,
#    then check which of these pairs of fist sequences are represented by contacts
#
# 4) foreach pair of uniprots, group the contacts by their contact groups (exact match? or something wider?)
#

# For each species need:
#
# - uniprot to fist matches for that species
# - all contacts - same as for groupContacts input
# - all frag inst to fist links - same as for groupContacts input
# - all contact groups - groupContacts output, but with ContactToGroups for only relevant ContactGroups extracted
#


# for testing:
name=random
./c/mechismoContactHits --contacts ./test/${name}/contacts_with_fist_numbers.tsv --dom_to_seq ./test/${name}/frag_inst_to_fist.tsv --dom_to_chem_type ./test/${name}/frag_inst_chem_type.tsv --queries ./test/${name}/queries.txt -hsps ./test/${name}/query_to_fist.tsv --contact_to_group ./test/${name}/0.0-0.8-0.8.only.ContactToGroup.tsv --contact_hit ./test/${name}/ContactHit.tsv --pcid -1 --lf_fist 0.8 --resres 1


# extract necessary information for each species
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  mkdir -p ./data/contact_hits/${id_taxon}
  /usr/bin/time -o ./data/contact_hits/${id_taxon}/query_to_fist.time perl -I./lib ./script/get_query_to_fist.pl --source 'uniprot-sprot' --source varsplic --taxon ${id_taxon} 2> ./data/contact_hits/${id_taxon}/query_to_fist.err | gzip > ./data/contact_hits/${id_taxon}/query_to_fist.tsv.gz &
  mysql -u anonymous -D m2b --quick --skip-column-names -e "SELECT id FROM Seq AS a, SeqToTaxon AS b WHERE a.source IN ('uniprot-sprot', 'varsplic') AND b.id_seq = a.id AND b.id_taxon = ${id_taxon}" > ./data/contact_hits/${id_taxon}/queries.txt &
done


# find ContactHits
# FIXME - only the bigger species need 30gb (because more hsps)
perl -e '$d = qx(pwd); chomp($d); $d .= "/"; foreach $id_taxon (272634,224308,83333,559292,6239,7227,10090,9606){$d2 = "data/contact_hits/${id_taxon}/"; foreach $th ([0.0, 0.8, 0.8]){$id = sprintf "%.1f-%.1f-%.1f", @{$th}; $fn = "${d}${d2}${id}.pbs"; print"$fn\n";open(PBS, ">$fn") or die $fn; printf PBS "#PBS -N ch${id_taxon}.${id}\n#PBS -o ${d}${d2}${id}.stdout\n#PBS -e ${d}${d2}${id}.stderr\n#PBS -l nodes=1:ppn=1\n#PBS -l mem=30gb\n#PBS -m ae\n#PBS -M matthew.betts\@bioquant.uni-heidelberg.de\n/usr/bin/time -o ${d}${d2}${id}.time ${d}c/mechismoContactHits --contacts ${d}data/contacts_with_fist_numbers.tsv.gz --dom_to_seq ${d}data/frag_inst_to_fist.tsv.gz --dom_to_chem_type ${d}data/frag_inst_chem_type.tsv.gz --queries ${d}${d2}queries.txt -hsps ${d}${d2}query_to_fist.tsv.gz --contact_to_group ${d}data/contact_groups/${id}.only.ContactToGroup.tsv --contact_hit ${d}${d2}${id}.ContactHit.tsv --pcid -1.0 --lf_fist 0.8 --resres 1\n", @{$th}; close(PBS);}}'

# now submit to pbs


# import
ls -rS ./data/contact_hits/*/0.0-0.8-0.8.ContactHit.tsv | perl -ne 'chomp; /(\d+)\/\S+ContactHit.tsv/; print"Fist::IO::ContactHit\t$_\tid=$1\n";' > ./data/contact_hits/import.inp
/usr/bin/time -o ./data/contact_hits/import.time perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/import.inp &> ./data/contact_hits/import.err

################ split queries ################
# split queries by single-linkage of all possible PPI pairs
# FIXME - ensure same parameters are used as in mechismoContactHits (min_n_resres, min_lf_fist)
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  /usr/bin/time -o ./data/contact_hits/${id_taxon}/split_queries.time ./script/split_contact_hit_queries.pl 10 1 0.8 ./data/contact_hits/${id_taxon}/queries.txt ./data/contact_hits/${id_taxon}/query_to_fist.tsv.gz ./data/frag_inst_to_fist.tsv.gz ./data/contacts_with_fist_numbers.tsv.gz &> ./data/contact_hits/${id_taxon}/split_queries.err &
done

# get pbs scripts
./scripts/contact_hits_pbs.pl

# submit to cluster

# import
ls -rS ./data/contact_hits/*/*.0.0-0.8-0.8.ContactHit.tsv | perl -ne 'chomp; /(\d+)\/(\d+)\.0\.0-0\.8-0\.8\.ContactHit.tsv/; print"Fist::IO::ContactHit\t$_\tid=${1}_${2}\n";' > ./data/contact_hits/import.inp
/usr/bin/time -o ./data/contact_hits/import.time perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/import.inp &> ./data/contact_hits/import.err

###############################################

## string aliases and interactions
mkdir -p ./data/string/
perl -I./lib ./script/parse_string.pl --outdir ./data/string/ --taxon 272634 --taxon 224308 --taxon 83333 --taxon 559292 --taxon 6239 --taxon 7227 --taxon 10090 --taxon 9606 --aliases $DS/string/protein.aliases.v10.txt.gz --links $DS/string/protein.links.v10.txt.gz > ./data/string/string.stdout 2> ./data/string/string.stderr &

# per taxon if needed:
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  mkdir -p ./data/string/${id_taxon}
  perl -I./lib ./script/parse_string.pl --outdir ./data/string/${id_taxon} --taxon ${id_taxon} --aliases $DS/string/protein.aliases.v10.txt.gz --links $DS/string/protein.links.v10.txt.gz > ./data/string/${id_taxon}/String.stdout 2> ./data/string/${id_taxon}/String.stderr &
done

# import
mysql -p -D m2b -e 'LOAD DATA LOCAL INFILE "./data/string/Alias.tsv" INTO TABLE Alias (id_seq, alias, type);'
mysql -p -D m2b -e 'LOAD DATA LOCAL INFILE "./data/string/StringInt.tsv" INTO TABLE StringInt (id_seq1, id_seq2, id_string1, id_string2, score);'


## PDB chemical types (from Rob)
perl -ne 'chomp; @F = split; $F[0] =~ s/\A_+//; print join("\t", @F), "\n";' /home/bq_rrussell/jobs/het/current_classes.txt > ./data/pdb_chem.tsv
mysql -p -D m2b -e 'LOAD DATA LOCAL INFILE "./data/pdb_chem.tsv" INTO TABLE PdbChem (id_chem, type);'



###### OLD STUFF, NEEDS UPDATING ######


## load GO terms in to db
mkdir -p ./data/GO/
./script/parse_go.pl < /net/netfile1/ds-russell/GO/gene_ontology_ext.obo 1> ./data/GO/gene_ontology_ext.tsv 2> ./data/GO/gene_ontology_ext.err
perl -e 'print"Fist::IO::GoTerm\t./data/GO/gene_ontology_ext.tsv\n";' | perl -I./lib ./script/import_tsv.pl 


## categorise query proteins by top level GO biological process
perl -ne 'BEGIN{$flag = 1;} if(/^\[Term\]/){$flag and defined($term) and print(@{$term}); $term = []; $flag = 0;}elsif(/^is_a: GO:0008150/){$flag = 1;}elsif(/^\[/){$term = undef; $flag = 0;} if(defined($term)){push @{$term}, $_;}elsif($flag){print;} END{$flag and defined($term) and print(@{$term});}' /net/netfile1/ds-russell/GO/gene_ontology_ext.obo > ./data/uniprot/sprot/goslim_biological_process.obo

mkdir -p ./data/uniprot/sprot/goslim_biological_process/
map2slim ./data/uniprot/sprot/goslim_biological_process.obo /net/netfile1/ds-russell/GO/gene_ontology_ext.obo /net/netfile1/ds-russell/uniprot-goa/gene_association.goa_uniprot.gz 2> ./data/uniprot/sprot/goslim_biological_process/uniprot-goa.slim.err | gzip >./data/uniprot/sprot/goslim_biological_process/uniprot-goa.slim.txt.gz # run on pevolution as takes a lot of memory
zcat ./data/uniprot/sprot/goslim_biological_process/uniprot-goa.slim.txt.gz | perl -I./lib ./script/parse_goa.pl --subset goslim_biological_process 1> ./data/uniprot/sprot/goslim_biological_process/GoAnnotation.tsv 2> ./data/uniprot/sprot/goslim_biological_process/GoAnnotation.err
perl -e 'print"Fist::IO::GoAnnotation\t./data/uniprot/sprot/goslim_biological_process/GoAnnotation.tsv\tid_seq=DB\n";' | perl -I./lib ./script/import_tsv.pl 


## load site types
mysql -p -D fistdb -e 'LOAD DATA LOCAL INFILE "./data/sites/types.tsv" INTO TABLE SiteType (abbr, type);'


## load UniProt human variations
mkdir -p ./data/sites/humsavar/
perl -I./lib ./script/parse_humsavar.pl --outdir ./data/sites/humsavar/ /net/netfile1/ds-russell/uniprot/docs/humsavar.txt  1> ./data/sites/humsavar/stdout 2> ./data/sites/humsavar/stderr
perl -e 'print"Fist::IO::Site\t./data/sites/humsavar/Site.tsv\tid_site=01\n";' > ./data/sites/humsavar/import.inp
perl -e 'print"Fist::IO::DiseaseToSite\t./data/sites/humsavar/DiseaseToSite.tsv\tid_site=01,id_disease=DB\n";' >> ./data/sites/humsavar/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/sites/humsavar/import.inp &> ./data/sites/humsavar/import.err


## load PTMs
mkdir -p ./data/sites/ptms/pablo/
perl -I./lib ./script/parse_pablo_ptms.pl --outdir ./data/sites/ptms/pablo/ $GH/work/ptms/pablos_data/*.txt  1> ./data/sites/ptms/pablo/stdout 2> ./data/sites/ptms/pablo/stderr
perl -e 'print"Fist::IO::Site\t./data/sites/ptms/pablo/Site.tsv\tid=01\n";' > ./data/sites/ptms/pablo/import.inp
perl -e 'print"Fist::IO::Pmid\t./data/sites/ptms/pablo/Pmid.tsv\n";' >> ./data/sites/ptms/pablo/import.inp
perl -e 'print"Fist::IO::PmidToSite\t./data/sites/ptms/pablo/PmidToSite.tsv\tid_site=01\n";' >> ./data/sites/ptms/pablo/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/sites/ptms/pablo/import.inp &> ./data/sites/ptms/pablo/import.err


## download data from www.phosida.com
# filenames, taxa, pubmed ids, and site types are listed in ./data/sites/ptms/PHOSIDA/fofn.txt

mkdir -p ./data/sites/ptms/PHOSIDA/
perl -nae '/^filename/ and next; print"$F[0]\n";' ./data/sites/ptms/PHOSIDA/fofn.txt | wget --no-host-directories --cut-dirs 3 -P ./data/sites/ptms/PHOSIDA/ -i -

# FIXME - map flybase sequence identifiers to uniprot sequences via blast
wget --no-host-directories --cut-dirs 3 -P ./data/blast ftp://ftp.flybase.net/releases/FB2013_02/reporting-xml/FBpp.xml.gz
zcat ./data/blast/FBpp.xml.gz | perl -ne 'if(/<id acode="id">(\S+)<\/id>/){$id = $1;}elsif(/\A\s+<residues>(\S+)<\/residues>/){print">$id\n$1\n";}' | seq_convert.pl --in fasta --out fasta > ./data/blast/FBpp.aa
perl -I./lib script/get_fasta.pl --chemical_type peptide --taxon 7227 --source 'uniprot-sprot' > ./data/blast/uniprot-sprot.7227.aa
formatdb -t uniprot-sprot.7227 -i ./data/blast/uniprot-sprot.7227.aa -p T -n ./data/blast/uniprot-sprot.7227
blastall -p blastp -d ./data/blast/uniprot-sprot.7227 -i ./data/blast/FBpp.aa -e 0.01 -F F 1> ./data/blast/FBpp.vs.uniprot-sprot.7227.blastp 2> ./data/blast/FBpp.vs.uniprot-sprot.7227.blastp.err
./script/aliases_from_blast.pl FlyBase < ./data/blast/FBpp.vs.uniprot-sprot.7227.blastp 1> ./data/blast/FBpp.aliases.tsv 2> ./data/blast/FBpp.aliases.err

# FIXME - map flybase protein ids to uniprot ac using STRING aliases 

# FIXME - map wormbase protein ids to uniprot ac using STRING aliases 
/net/netfile1/ds-russell/string/protein.aliases.v9.05.txt.gz

# parse PHOSIDA ptms
perl -nae '/^filename/ and next; $F[0] =~ s/.*\///; $f = "./data/sites/ptms/PHOSIDA/$F[0]"; $d = "./data/sites/ptms/PHOSIDA/$F[1]/$F[0]/"; $d =~ s/\.csv//; print "mkdir -p $d\nperl -I./lib ./script/parse_phosida_ptms.pl --outdir $d --taxon $F[1] --pmid $F[2] --type $F[3] $f  1> ./${d}stdout 2> ./${d}stderr\n\n";' ./data/sites/ptms/PHOSIDA/fofn.txt > ./data/sites/ptms/PHOSIDA/go.sh
source go.sh

###### this time, map to sites already in db and add new PmidToSite entries ######

ls ./data/sites/ptms/PHOSIDA/*/*/Site.tsv | perl -ne 'chomp;if(/PHOSIDA\/(\d+)/){$taxon = $1; ($f = $_) =~ s/Site.tsv\Z//;; open(I, $_) or die; while(<I>){@F = split; print"SELECT \"$f\", $F[0], id FROM Site WHERE source = \"PHOSIDA\" AND type = \"$F[2]\" AND id_seq = $F[3] AND pos = $F[4];\n";}}' | mysql -u anonymous -D fistdb --quick --skip-column-names | perl -nae '($F[0] == 224308) or ($F[0] == 83333) or ($F[0] == 6239) or print;' > data/sites/ptms/PHOSIDA/new_to_old_site_ids.tsv

ls ./data/sites/ptms/PHOSIDA/*/*/PmidToSite.tsv | perl -ne 'BEGIN{open(I, "data/sites/ptms/PHOSIDA/new_to_old_site_ids.tsv"); chomp; while(<I>){@F = split; $S{$F[0]}->{$F[1]}->{$F[2]}++;}close(I);} chomp; if(/PHOSIDA\/(\d+)/){$taxon = $1; ($f = $_) =~ s/PmidToSite.tsv\Z//; open(I, $_) or die; while(<I>){@F = split; if(defined($S{$f}->{$F[0]})){foreach $id_old (keys %{$S{$f}->{$F[0]}}){print(join("\t", $id_old, $F[1]), "\n");}}}}' > ./data/sites/ptms/PHOSIDA/PmidToSite.update_old.tsv
perl -nae 'print"$F[1]\n";' data/sites/ptms/PHOSIDA/PmidToSite.update_old.tsv | sort -n -u -o data/sites/ptms/PHOSIDA/Pmid.update_old.tsv

perl -e 'print"Fist::IO::Pmid\t./data/sites/ptms/PHOSIDA/Pmid.update_old.tsv\n";' > ./data/sites/ptms/PHOSIDA/import.update_old.inp
perl -e 'print"Fist::IO::PmidToSite\t./data/sites/ptms/PHOSIDA/PmidToSite.update_old.tsv\tid_site=DB\n";' >> ./data/sites/ptms/PHOSIDA/import.update_old.inp
perl -I./lib ./script/import_tsv.pl < ./data/sites/ptms/PHOSIDA/import.update_old.inp &> ./data/sites/ptms/PHOSIDA/import.update_old.err

# directly add PMIDs for worm, as was a real pain to get from sequence aliases used in PHOSIDA files
mysql -p -D fistdb -e 'INSERT INTO Pmid (pmid) VALUES (19530675); INSERT INTO PmidToSite (id_site, pmid) SELECT s.id, 19530675 FROM Site AS s, SeqToTaxon AS s_to_t WHERE s.source = "PHOSIDA" AND s_to_t.id_seq = s.id_seq AND s_to_t.id_taxon = 6239;'

# directly add PMIDs for fly, as was a real pain to get from sequence aliases used in PHOSIDA files
mysql -p -D fistdb -e 'INSERT INTO Pmid (pmid) VALUES (19429919); INSERT INTO PmidToSite (id_site, pmid) SELECT s.id, 19429919 FROM Site AS s, SeqToTaxon AS s_to_t WHERE s.source = "PHOSIDA" AND s_to_t.id_seq = s.id_seq AND s_to_t.id_taxon = 7227;'


###### next time ######

# import
ls ./data/sites/ptms/PHOSIDA/*/*/Site.tsv | perl -ne 'chomp; /PHOSIDA\/(\d+)/ and print"Fist::IO::Site\t$_\tid=$1\n";' > ./data/sites/ptms/PHOSIDA/import.inp
ls ./data/sites/ptms/PHOSIDA/*/*/Pmid.tsv | perl -ne 'chomp; /PHOSIDA\/(\d+)/ and print"Fist::IO::Pmid\t$_\n";' >> ./data/sites/ptms/PHOSIDA/import.inp
ls ./data/sites/ptms/PHOSIDA/*/*/PmidToSite.tsv | perl -ne 'chomp; /PHOSIDA\/(\d+)/ and print"Fist::IO::PmidToSite\t$_\tid_site=$1\n";' >> ./data/sites/ptms/PHOSIDA/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/sites/ptms/PHOSIDA/import.inp &> ./data/sites/ptms/PHOSIDA/import.err

#########################################################################


# download phosphorylation and acetylation sites for myco from PMID:22373819, supp tables S1 & S2
# convert 'identification scores' sheets to csv (tab-delimited fields, quotation marks removed)
# NOTE: incorrect heading in downloaded acetylation file

mkdir -p ./data/sites/ptms/mpn/phosphorylation
perl -I./lib ./script/parse_mpn_ptms.pl --outdir ./data/sites/ptms/mpn/phosphorylation --pmid 22373819 --type phosphorylation ./data/sites/ptms/mpn/mpn-phosphorylated.csv  1> ./data/sites/ptms/mpn/phosphorylation/stdout 2> ./data/sites/ptms/mpn/phosphorylation/stderr
perl -e 'print"Fist::IO::Site\t./data/sites/ptms/mpn/phosphorylation/Site.tsv\tid=01\n";' > ./data/sites/ptms/mpn/phosphorylation/import.inp
perl -e 'print"Fist::IO::Pmid\t./data/sites/ptms/mpn/phosphorylation/Pmid.tsv\n";' >> ./data/sites/ptms/mpn/phosphorylation/import.inp
perl -e 'print"Fist::IO::PmidToSite\t./data/sites/ptms/mpn/phosphorylation/PmidToSite.tsv\tid_site=01\n";' >> ./data/sites/ptms/mpn/phosphorylation/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/sites/ptms/mpn/phosphorylation/import.inp &> ./data/sites/ptms/mpn/phosphorylation/import.err

mkdir -p ./data/sites/ptms/mpn/acetylation
perl -I./lib ./script/parse_mpn_ptms.pl --outdir ./data/sites/ptms/mpn/acetylation --pmid 22373819 --type acetylation ./data/sites/ptms/mpn/mpn-acetylated.csv  1> ./data/sites/ptms/mpn/acetylation/stdout 2> ./data/sites/ptms/mpn/acetylation/stderr
perl -e 'print"Fist::IO::Site\t./data/sites/ptms/mpn/acetylation/Site.tsv\tid=01\n";' > ./data/sites/ptms/mpn/acetylation/import.inp
perl -e 'print"Fist::IO::Pmid\t./data/sites/ptms/mpn/acetylation/Pmid.tsv\n";' >> ./data/sites/ptms/mpn/acetylation/import.inp
perl -e 'print"Fist::IO::PmidToSite\t./data/sites/ptms/mpn/acetylation/PmidToSite.tsv\tid_site=01\n";' >> ./data/sites/ptms/mpn/acetylation/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/sites/ptms/mpn/acetylation/import.inp &> ./data/sites/ptms/mpn/acetylation/import.err


## get sites from uniprot entries
# FIXME - fix sites of unknown type - some may be useful. See 'parse.err'
mkdir -p ./data/sites/uniprot/
perl -I./lib ./script/parse_uniprot_sites.pl --outdir ./data/sites/uniprot/ $DS/uniprot/knowledgebase/complete/uniprot_sprot.dat.gz 1> ./data/sites/uniprot/parse.out 2> ./data/sites/uniprot/parse.err

# FIXME - update schema to allow types of sites other than in the enum

# This time, map to 'swissprot' sites already in db and add new PmidToSite entries
perl -F'/\t/' -nae 'print"SELECT $F[0], id FROM Site WHERE source = \"swissprot\" AND type = \"$F[2]\" AND id_seq = $F[3] AND pos = $F[4];\n";' data/sites/uniprot/Site.tsv | mysql -u anonymous -D fistdb --quick --skip-column-names > data/sites/uniprot/new_to_old_site_ids.tsv
perl -nae 'BEGIN{open(I, "data/sites/uniprot/new_to_old_site_ids.tsv"); while(<I>){@F = split; $S{$F[0]} = $F[1];}close(I);} defined($S{$F[0]}) and print(join("\t", $S{$F[0]}, $F[1]), "\n");' data/sites/uniprot/PmidToSite.tsv > data/sites/uniprot/PmidToSite.update_old.tsv
perl -nae 'print"$F[1]\n";' data/sites/uniprot/PmidToSite.update_old.tsv | sort -n -u -o data/sites/uniprot/Pmid.update_old.tsv

perl -e 'print"Fist::IO::Pmid\t./data/sites/uniprot/Pmid.update_old.tsv\n";' > ./data/sites/uniprot/import.update_old.inp
perl -e 'print"Fist::IO::PmidToSite\t./data/sites/uniprot/PmidToSite.update_old.tsv\tid_site=DB\n";' >> ./data/sites/uniprot/import.update_old.inp
perl -I./lib ./script/import_tsv.pl < ./data/sites/uniprot/import.update_old.inp &> ./data/sites/uniprot/import.update_old.err


# import
perl -e 'print"Fist::IO::Site\t./data/sites/uniprot/Site.tsv\tid=01\n";' > ./data/sites/uniprot/import.inp
perl -e 'print"Fist::IO::Pmid\t./data/sites/uniprot/Pmid.tsv\n";' >> ./data/sites/uniprot/import.inp
perl -e 'print"Fist::IO::PmidToSite\t./data/sites/uniprot/PmidToSite.tsv\tid_site=01\n";' >> ./data/sites/uniprot/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/sites/uniprot/import.inp &> ./data/sites/uniprot/import.err


## map p[STY] and aK in PDB to positions in uniprot sequences
##
##   SEP = pS
##   TPO = pT
##   PTR = pY
##   ALY = aK
##
mkdir -p ./data/sites/ptms/pdb/
perl -I./lib ./script/get_pdb_ptms.pl 1> ./data/sites/ptms/pdb/Site.tsv 2> ./data/sites/ptms/pdb/Site.err
perl -e 'print"Fist::IO::Site\t./data/sites/ptms/pdb/Site.tsv\tid=01\n";' > ./data/sites/ptms/pdb/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/sites/ptms/pdb/import.inp &> ./data/sites/ptms/pdb/import.err


## define throughput for each PMID by the number of distinct sequences with sites
perl -I./lib script/set_pmid_throughput.pl --high 100 --medium 20 &> ./data/set_pmid_throughput.err


## load the known enzymes for each PTM
perl -I./lib/ ./script/site_enzymes.pl /net/netfile2/ag-russell/bq_mbetts/work/ptms/pablos_data/ptm_data_enzymes/* > ./data/sites/ptms/pablo/EnzymeToSite.tsv 2> ./data/sites/ptms/pablo/EnzymeToSite.err
perl -e 'print"Fist::IO::EnzymeToSite\t./data/sites/ptms/pablo/EnzymeToSite.tsv\tid_site=DB,id_seq=DB\n";' | perl -I./lib ./script/import_tsv.pl


## get start positions of chain segments in the fist sequences of fragments
## (which are not necessarily the same as in the full chain fist sequence)
mysql -p -D fistdb < sql/chain_seqment_fist.sql


## get res mapping for fragments (saves complicated sql later on, with ChainSegment etc.)
# FIXME - res3 and res1 were not included in the file generated. Added via sql on 2014-09-16
/usr/bin/time -o ./data/FragResMapping.time perl -I./lib ./script/frag_res_mapping.pl > ./data/FragResMapping.tsv 2> ./data/FragResMapping.err
/usr/bin/time -o ./data/FragResMapping.import.time mysql -p -D fistdb -e 'SET sql_log_bin = 0; LOAD DATA LOCAL INFILE "./data/FragResMapping.tsv" INTO TABLE FragResMapping (id_frag, fist, chain, resseq, icode, res3, res1);' >&./data/FragResMapping.import.err


## get templates for all components (best templates for each position in each sequence by itself)
mkdir -p ./data/frag_hits/uniprot/sprot
/usr/bin/time -o ./data/frag_hits/uniprot/sprot/pbs.time perl -I./lib ./script/fragment_hits.pl --source 'uniprot-sprot' --outdir ./data/frag_hits/uniprot/ --pbs sprot --n_jobs 200 1> ./data/frag_hits/uniprot/sprot/pbs.out 2> ./data/frag_hits/uniprot/sprot/pbs.err
ls ./data/frag_hits/uniprot/sprot/*/FragHit.tsv | perl -ne 'chomp; /(\d+)\/FragHit.tsv/ and print"Fist::IO::FragHit\t$_\tid_seq=DB,id_aln=DB\n";' > ./data/frag_hits/uniprot/sprot/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/frag_hits/uniprot/sprot/import.inp &> ./data/frag_hits/uniprot/sprot/import.err


## map sites in taxa of interest to alignments of uniref sequence groups
# for each type of site, if an alignment position was seen
# in the foreground for any sequence then assign it to the
# set of foreground sites, otherwise use it as background.

perl -I./lib ./script/sites_to_seqgroups.pl --outdir ./temp --type phosphorylation --background 'phosphorylation,[STY]' --group_type 'uniref 50' --taxon 272634 --taxon 224308 --taxon 83333 --taxon 559292 --taxon 6239 --taxon 7227 --taxon 10090 --taxon 9606 2> ./data/sites/uniref50.err | gzip > ./data/sites/uniref50.tsv.gz

perl -I./lib ./script/sites_to_seqgroups.pl --outdir ./temp --type phosphorylation --background 'phosphorylation,[STY]' --group_type 'uniref 90' --taxon 272634 --taxon 224308 --taxon 83333 --taxon 559292 --taxon 6239 --taxon 7227 --taxon 10090 --taxon 9606 2> ./data/sites/uniref90.err | gzip > ./data/sites/uniref90.tsv.gz

perl -I./lib ./script/sites_to_seqgroups.pl --outdir ./temp --type phosphorylation --background 'phosphorylation,[STY]' --group_type 'uniref 100' --taxon 272634 --taxon 224308 --taxon 83333 --taxon 559292 --taxon 6239 --taxon 7227 --taxon 10090 --taxon 9606 2> ./data/sites/uniref100.err | gzip > ./data/sites/uniref100.tsv.gz


## generate domain files for frags grouped by sequence
perl -I./lib ./script/get_frag_seq_group_dom_files.pl --type 'fist lf=0.0 pcid=0.0' 1> data/seq_groups/fist_lf0_pcid0/domains.dom 2> data/seq_groups/fist_lf0_pcid0/domains.err
perl -I./lib ./script/get_frag_seq_group_dom_files.pl --type 'fist lf=0.9 pcid=90.0' 1> data/seq_groups/fist_lf0.9_pcid90/domains.dom 2> data/seq_groups/fist_lf0.9_pcid90/domains.err
perl -I./lib ./script/get_frag_seq_group_dom_files.pl --type 'fist lf=0.5 pcid=50.0' 1> data/seq_groups/fist_lf0.5_pcid50/domains.dom 2> data/seq_groups/fist_lf0.5_pcid50/domains.err
gzip data/seq_groups/*/domains.dom


## generate domain files linking groups that share a common scop superfamily
mkdir ./data/seq_groups/fist_lf0.9_pcid90/scop/
perl -I./lib ./script/get_scop_frag_seq_groups.pl --type 'fist lf=0.9 pcid=90.0' 1>  ./data/seq_groups/fist_lf0.9_pcid90/scop/domains.dom 2>  ./data/seq_groups/fist_lf0.9_pcid90/scop/domains.err
gzip ./data/seq_groups/fist_lf0.9_pcid90/scop/domains.dom


## get chemical info from pdbechem
wget --no-host-directories --cut-dirs 4 -P ./data/ ftp://ftp.ebi.ac.uk/pub/databases/msd/pdbechem/chem_comp.xml
./script/chem_comp_to_tsv.pl < ./data/chem_comp.xml 1> ./data/ChemComp.tsv 2> ChemComp.err
mysql -p -D fistdb -e 'SET sql_log_bin = 0; LOAD DATA LOCAL INFILE "./data/ChemComp.tsv" INTO TABLE ChemComp (id, name, formula, systematic_name, stereo_smiles, non_stereo_smiles, in_chi);'


## generate domain files for interaction groups
for j in 1.0 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1
do
  perl -I./lib ./script/get_contact_group_dom_files.pl --lf 0.9 --pcid 90 --same_frag 0 --aln_jaccard 0 --full_jaccard $j 1> data/contact_groups/fist_lf0.9_pcid90/domains.j$j.dom 2> data/contact_groups/fist_lf0.9_pcid90/domains.j$j.err
  perl -I./lib ./script/get_contact_group_dom_files.pl --lf 0.5 --pcid 50 --same_frag 0 --aln_jaccard 0 --full_jaccard $j 1> data/contact_groups/fist_lf0.5_pcid50/domains.j$j.dom 2> data/contact_groups/fist_lf0.5_pcid50/domains.j$j.err
  perl -I./lib ./script/get_contact_group_dom_files.pl --lf 0.0 --pcid 0.1 --same_frag 0 --aln_jaccard 0 --full_jaccard $j 1> data/contact_groups/fist_lf0.0_pcid0/domains.j$j.dom  2> data/contact_groups/fist_lf0.0_pcid0/domains.j$j.err
done
gzip data/contact_groups/*/domains.*.dom


## find contacts for fist seq Pfam features
perl -I./lib ./script/feature_contacts.pl --source Pfam 1> ./data/pfam/pfam_contacts.tsv 2> ./data/pfam/pfam_contacts.err
perl -e 'print"Fist::IO::FeatureInstContact\tdata/pfam/pfam_contacts.tsv\n";' | perl -I./lib ./script/import_tsv.pl 
mysql -p -D fistdb < sql/update_feature_contact.sql

# summarise
mysql -u anonymous -D fistdb < sql/pfam_contact_summary.sql | gzip > ./data/pfam/pfam_contact_summary.tsv.gz
mysql -u anonymous -D fistdb < sql/pfam_instances_uniprot.sql | gzip > ./data/pfam/pfam_instances_uniprot.tsv.gz
mysql -u anonymous -D fistdb < sql/iupred_instances_uniprot.sql | gzip > ./data/iupred_instances_uniprot.tsv.gz

## contact hits for all PDB sites mapped to uniprot
## WARNING: this was done separately for phosphorylation and acetylation in the files currently stored
mkdir -p ./data/contact_hits/pdb/
mysql -u anonymous -D fistdb --quick --skip-column-names -e 'SELECT b.id_seq, b.id_taxon FROM Site AS a, SeqToTaxon AS b WHERE a.source = "pdb" AND b.id_seq = a.id_seq GROUP BY b.id_seq, b.id_taxon;' | perl -nae 'BEGIN{$d1 = qx(pwd); chomp($d1); ($d2 = $d1) .= "/data/contact_hits/pdb/";} mkdir("$d2$F[0]"); open(PBS, ">$d2$F[0].pbs"); print PBS "#PBS -N $F[0]\n#PBS -o $d2/$F[0]/stdout\n#PBS -e $d2$F[0]/stderr\n#PBS -l cput=04:59:59\n#PBS -m n\n#PBS -M matthew.betts\@bioquant.uni-heidelberg.de\nperl -I$d1/lib $d1/script/contact_hits.pl --id $F[0] --taxon $F[1] --source uniprot-sprot --outdir $d2$F[0]/\n"; close(PBS);'

# on appl2:
ls ./data/contact_hits/pdb/*.pbs | pbs_siesta.pl --wait 0

# import
ls ./data/contact_hits/pdb/*/ContactHit.tsv | perl -ne 'chomp; /(\d+)\/ContactHit.tsv/; print"Fist::IO::ContactHit\t$_\tid=$1\n";' > ./data/contact_hits/pdb/import.inp
ls ./data/contact_hits/pdb/*/ContactHitRes.tsv | perl -ne 'chomp; /(\d+)\/ContactHitRes.tsv/; print"Fist::IO::ContactHitResidue\t$_\tid_contact_hit=$1\n";' >> ./data/contact_hits/pdb/import.inp
/usr/bin/time -o ./data/contact_hits/pdb/import.time perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/pdb/import.inp &> ./data/contact_hits/pdb/import.err


## get all matches above a certain percent identity (to avoid problems with multiple kinases slowing things down),
## for checking whether there are alternative templates with and without phos in interface.

mkdir -p ./data/contact_hits/pdb_all/
mysql -u anonymous -D fistdb --quick --skip-column-names -e 'SELECT b.id_seq, b.id_taxon FROM Site AS a, SeqToTaxon AS b WHERE a.source = "pdb" AND b.id_seq = a.id_seq GROUP BY b.id_seq, b.id_taxon;' | perl -nae 'BEGIN{$d1 = qx(pwd); chomp($d1); ($d2 = $d1) .= "/data/contact_hits/pdb_all/";} mkdir("$d2$F[0]"); open(PBS, ">$d2$F[0].pbs"); print PBS "#PBS -N $F[0]\n#PBS -o $d2/$F[0]/stdout\n#PBS -e $d2$F[0]/stderr\n#PBS -l cput=04:59:59\n#PBS -m ae\n#PBS -M matthew.betts\@bioquant.uni-heidelberg.de\nperl -I$d1/lib $d1/script/contact_hits.pl --id $F[0] --taxon $F[1] --source uniprot-sprot --outdir $d2$F[0]/ --all_matches --both_ways --min_pcid 40\n"; close(PBS);'

# import
ls ./data/contact_hits/pdb_all/*/ContactHit.tsv | perl -ne 'chomp; /(\d+)\/ContactHit.tsv/; print"Fist::IO::ContactHit\t$_\tid=$1\n";' > ./data/contact_hits/pdb_all/import.inp
ls ./data/contact_hits/pdb_all/*/ContactHitRes.tsv | perl -ne 'chomp; /(\d+)\/ContactHitRes.tsv/; print"Fist::IO::ContactHitResidue\t$_\tid_contact_hit=$1\n";' >> ./data/contact_hits/pdb_all/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/pdb_all/import.inp &> ./data/contact_hits/pdb_all/import.err


## run interprets on all matches
## FIXME - assumes the only ContactHits in the db are for the pdb sites
mkdir -p ./data/contact_hits/pdb/itps/
/usr/bin/time -o ./data/contact_hits/pdb/itps/time perl -I./lib ./script/contact_hit_interprets.pl --outdir ./data/contact_hits/pdb/ --pbs itps --n_jobs 200 --rand 1000 1> ./data/contact_hits/pdb/itps/pbs.out 2> ./data/contact_hits/pdb/itps/pbs.err
ls ./data/contact_hits/pdb/itps/*/ContactHitInterprets.tsv | perl -ne 'chomp; /(\d+)\/ContactHitInterprets.tsv/; print"Fist::IO::ContactHitInterprets\t$_\tid_contact_hit=DB\n";' > ./data/contact_hits/pdb/itps/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/pdb/itps/import.inp &> ./data/contact_hits/pdb/itps/import.err


## summarise pdb sites
mkdir -p ./data/site_summary/pdb
perl -I./lib ./script/site_summary.pl --source pdb --hetatm '^[PS]' --background 'phosphorylation,[STY]' --background 'acetylation,K' --subset goslim_biological_process --outdir ./data/site_summary/ --seqgroups ./data/sites/uniref50.tsv.gz --pbs pdb --q_max 300 1> ./data/site_summary/pdb/pbs.out 2> ./data/site_summary/pdb/pbs.err
head -q -n 1 `find ./data/site_summary/pdb/ -name SiteSummary.tsv` | sort -u > ./data/site_summary/pdb.tsv
tail -q -n +2 `find ./data/site_summary/pdb/ -name SiteSummary.tsv` >> ./data/site_summary/pdb.tsv

# min identity for single fragment match = 77%... not 100% as
# one might expect, since the best *by e-value* is reported.


## count things and calculate enrichment and significance
./script/site_summary_table.pl --pcid 70 --lt_pcid 101 --n_ss 2 ./data/site_summary/pdb.tsv 1> ./data/site_summary/pdb.pcid70.ss2.counts.tsv 2> ./data/site_summary/pdb.pcid70.ss2.counts.err


## get templates for uniprot matches to NR templates (best compatible templates for each pair of sequences)

## Some taxa have lots of children with lots of sequences (eg E.coli, id = 562).
## This gives a combinatorial problem when using all sequences to find contact hits.
## Could use all sequences but group them together. For now, just use the child taxon
## with the most phospho sites, as long as it has a lot of sequences.
perl -I./lib ./script/phospho_sites_per_child_taxon.pl > ./data/phospho_sites_per_child_taxon.tsv

# starred taxon used from now on:
#
# taxon  child    n_seqs   n_sites scientific_name
#
# 562    *83333   24604    79      Escherichia coli K-12
# 1423   *224308  4735     70      Bacillus subtilis subsp. subtilis str. 168
# 2104   *272634  707      122     Mycoplasma pneumoniae M129
#
# 4932   4932     27576    20      Saccharomyces cerevisiae
# 4932   307796   494      1       Saccharomyces cerevisiae YJM789
# 4932   *559292  11070    10827   Saccharomyces cerevisiae S288c
#
# 6239   *6239    4592     1995    Caenorhabditis elegans
# 7227   *7227    7103     3020    Drosophila melanogaster
# 9606   *9606    194721   70397   Homo sapiens
# 10090  *10090   48566    27478   Mus musculus

# NOTE: currently importing data in a separate loop so that I can check them first

for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  mkdir -p ./data/contact_hits/${id_taxon}/
  /usr/bin/time -o ./data/contact_hits/${id_taxon}/time perl -I./lib ./script/contact_hits.pl --skip_done --taxon ${id_taxon} --source 'uniprot-sprot' --outdir ./data/contact_hits/ --pbs ${id_taxon} --n_jobs 200 1> ./data/contact_hits/${id_taxon}/pbs.out 2> ./data/contact_hits/${id_taxon}/pbs.err &
done

# run the following on pevolution as the id mapping may need a lot of memory
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  ls ./data/contact_hits/${id_taxon}/*/ContactHit.tsv | perl -ne 'chomp; /(\d+)\/ContactHit.tsv/; print"Fist::IO::ContactHit\t$_\tid=$1\n";' > ./data/contact_hits/${id_taxon}/import.inp
  ls ./data/contact_hits/${id_taxon}/*/ContactHitRes.tsv | perl -ne 'chomp; /(\d+)\/ContactHitRes.tsv/; print"Fist::IO::ContactHitResidue\t$_\tid_contact_hit=$1\n";' >> ./data/contact_hits/${id_taxon}/import.inp
  /usr/bin/time -o ./data/contact_hits/${id_taxon}/import.time perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/${id_taxon}/import.inp &> ./data/contact_hits/${id_taxon}/import.err
done


## run interprets on all matches
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  mkdir -p ./data/contact_hits/${id_taxon}/itps/
  /usr/bin/time -o ./data/contact_hits/${id_taxon}/itps/time perl -I./lib ./script/contact_hit_interprets.pl --skip_done --outdir ./data/contact_hits/${id_taxon}/ --pbs itps --n_jobs 2000 --taxon ${id_taxon} --rand 1000 1> ./data/contact_hits/${id_taxon}/itps/pbs.out 2> ./data/contact_hits/${id_taxon}/itps/pbs.err
  ls ./data/contact_hits/${id_taxon}/itps/*/ContactHitInterprets.tsv | perl -ne 'chomp; /(\d+)\/ContactHitInterprets.tsv/; print"Fist::IO::ContactHitInterprets\t$_\tid_contact_hit=DB\n";' > ./data/contact_hits/${id_taxon}/itps/import.inp
done

for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  ls ./data/contact_hits/${id_taxon}/itps/*/ContactHitInterprets.tsv | perl -ne 'chomp; /(\d+)\/ContactHitInterprets.tsv/; print"Fist::IO::ContactHitInterprets\t$_\tid_contact_hit=DB\n";' > ./data/contact_hits/${id_taxon}/itps/import.inp
done

for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  /usr/bin/time -o ./data/contact_hits/${id_taxon}/itps/import.time perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/${id_taxon}/itps/import.inp &> ./data/contact_hits/${id_taxon}/itps/import.err
done


###### SIFTS ######

# 2014-07-23 SIFTS HSPs were added after contact_hits.pl was originally run,
# so run it again for the affected sequences in the taxa of interest.

mkdir -p ./data/contact_hits/sifts/

perl -nae '/^id_seq/ and next; /NULL/ and $S{$F[0]}++; END{foreach $s (keys %S){print "SELECT id_seq, id_taxon FROM SeqToTaxon WHERE id_seq = $s;\n";}}' ./data/site_summary-v06/sifts_to_hsp.tsv | mysql -u anonymous -D fistdb --skip-column-names > ./data/site_summary-v06/sifts_to_hsp.missing.id_taxon.tsv

perl -nae '$S{$F[1]}->{$F[0]}++; END{foreach $tax (272634,224308,83333,559292,6239,7227,10090,9606){(scalar(keys(%{$S{$tax}})) > 0) or next; print "mkdir -p ./data/contact_hits/sifts/$tax\nperl -I./lib ./script/contact_hits.pl --outdir ./data/contact_hits/sifts/ --pbs $tax --taxon $tax --source uniprot-sprot --n_jobs 31 --id ", join(" --id ", sort {$a <=> $b} keys %{$S{$tax}}), " 1> ./data/contact_hits/sifts/$tax/pbs.out 2> ./data/contact_hits/sifts/$tax/pbs.err &\n\n"}}' ./data/site_summary-v06/sifts_to_hsp.missing.id_taxon.tsv > ./data/contact_hits/sifts/pbs.sh

# remove contact hits that duplicate those already in the db
# for all others, repeat them in the other direction
perl -I./lib ./script/contact_hits_remove_duplicates.pl data/contact_hits/sifts/*/*/ContactHit.tsv

# back-up existing tables
mysqldump -p fistdb ContactHit ContactHitResidue | gzip > data/contact_hits/sifts/ContactHit.pre_sifts.sql.gz

# get current max(ContactHit.id)
# = 2984721

# upload
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  if [ -e ./data/contact_hits/sifts/${id_taxon}/ ]
  then
    ls ./data/contact_hits/sifts/${id_taxon}/*/ContactHit.tsv | perl -ne 'chomp; /(\d+)\/ContactHit.tsv/; print"Fist::IO::ContactHit\t$_\tid=$1\n";' > ./data/contact_hits/sifts/${id_taxon}/import.inp
    ls ./data/contact_hits/sifts/${id_taxon}/*/ContactHitRes.tsv | perl -ne 'chomp; /(\d+)\/ContactHitRes.tsv/; print"Fist::IO::ContactHitResidue\t$_\tid_contact_hit=$1\n";' >> ./data/contact_hits/sifts/${id_taxon}/import.inp
    perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/sifts/${id_taxon}/import.inp &> ./data/contact_hits/sifts/${id_taxon}/import.err
  fi
done

## run interprets on all matches
mkdir -p ./data/contact_hits/sifts/itps/
mysql -u anonymous -D fistdb --skip-column-names --e 'SELECT id FROM ContactHit WHERE id > 2984721' | perl -ne 'chomp; push @ids, $_; END{print"perl -I./lib ./script/contact_hit_interprets.pl --outdir ./data/contact_hits/sifts/ --pbs itps --rand 1000 --id ", join(" --id ", @ids), " 1> ./data/contact_hits/sifts/itps/pbs.out 2> ./data/contact_hits/sifts/itps/pbs.err &\n";}' > ./data/contact_hits/sifts/itps/pbs.sh
source ./data/contact_hits/sifts/itps/pbs.sh

ls ./data/contact_hits/sifts/itps/*/ContactHitInterprets.tsv | perl -ne 'chomp; /(\d+)\/ContactHitInterprets.tsv/; print"Fist::IO::ContactHitInterprets\t$_\tid_contact_hit=DB\n";' > ./data/contact_hits/sifts/itps/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/sifts/itps/import.inp &> ./data/contact_hits/sifts/itps/import.err

mkdir -p ./data/site_summary-v06/sifts/
perl -nae 'if(/NULL/){$S{$F[0]}++; $S{$F[1]}++;} END{foreach $s (sort {$a <=> $b} keys %S) {print"$s\n";}}' data/site_summary-v06/sifts_to_hsp.tsv > ./data/site_summary-v06/sifts/ids.txt
perl -I./lib ./script/site_summary.pl `perl -ne 'chomp; print" --id $_";' ./data/site_summary-v06/sifts/ids.txt` --hetatm '^[PS]' --background 'phosphorylation,[STY]' --background 'acetylation,K' --subset goslim_biological_process --seqgroups ./data/sites/uniref50.tsv.gz --outdir ./data/site_summary-v06/ --pbs sifts 1> ./data/site_summary-v06/sifts/pbs.out 2> ./data/site_summary-v06/sifts/pbs.err &


###################


############################## REDO ##############################

## get JSON data for all contact hits with %id >= 70
mysql -u anonymous -D fistdb --quick --skip-column-names -e 'SELECT id FROM ContactHit WHERE pcid_a >= 70 AND pcid_b >= 70;' > ./data/contact_hits.pcid70.ids.txt
/usr/bin/time -o ./data/contact_hits.pcid70.json.time ./script/get_contact_hit_json.pl < ./data/contact_hits.pcid70.ids.txt 1> ./data/contact_hits.pcid70.json 2> ./data/contact_hits.pcid70.json.err
gzip ./data/contact_hits.pcid70.json

##################################################################



## calculate jaccard indices between different interfaces on the same query
mkdir -p ./data/query_interface_jaccard/human
perl -I./lib ./script/query_interface_jaccard.pl --source 'uniprot-sprot' --taxon 9606 --outdir ./data/query_interface_jaccard/ --pbs human 1> ./data/query_interface_jaccard/human/pbs.out 2> ./data/query_interface_jaccard/human/pbs.err


## group query interfaces by jaccard indices
/usr/bin/time -o ./data/QueryInterfaceGroup.time perl -I./lib ./script/group_query_interfaces.pl --source 'uniprot-sprot' --taxon 9606 --j 0.3 --resres 10 ./data/query_interface_jaccard/human/*/QueryInterfaceJaccard.tsv > ./data/QueryInterfaceGroup.tsv 2> ./data/QueryInterfaceGroup.err


## FIXME - use query interface groups to define compatible interactions for each pair of proteins


# - which proteins have the most interface groups?
# - which interface groups have the most interactors?
# - for each protein, plot number of interactors vs. number of interfaces
perl -I./lib ./script/interactors_and_interfaces_per_query.pl < ./data/QueryInterfaceGroup.tsv > ./data/QueryInterfaceGroup.interactors_and_interfaces_per_query.tsv


## FIXME - introduce checks for IdMapping


## FIXME - list contact hits

## FIXME
##
## queries:
## - all contact hits
## - all contact hits with a site [of a particular type and|or source]
## - all contact hits with a site [of a particular type and|or source] in the interface [with sidechain-sidechain contact]
## - -"- and where charge is within or outside a particular range (eg. <= -1 or >= +1)
##
## contact hits should be grouped in some way
## - by uniprot 90 of queries
## - by template
## - by template group


## FIXME - run DSSP for FragInsts as pairs (ie. for interactions)


## FIXME - uniprot feature table info, especially cellular location
## - easy way to go from this to structures, eg. 'all SCOPS in nucleus'


# FIXME - find gaps in fist sequences wrt. to uniprot sequences, = unstructured regions


## categorise query proteins by GO slim terms
mkdir -p ./data/uniprot/sprot/goslim_generic/
map2slim /net/netfile1/ds-russell/GO_slims/goslim_generic.obo /net/netfile1/ds-russell/GO/gene_ontology_ext.obo /net/netfile1/ds-russell/uniprot-goa/gene_association.goa_uniprot.gz 2> ./data/uniprot/sprot/goslim_generic/uniprot-goa.slim.err | gzip >./data/uniprot/sprot/goslim_generic/uniprot-goa.slim.txt.gz # run on pevolution as takes a lot of memory
zcat ./data/uniprot/sprot/goslim_generic/uniprot-goa.slim.txt.gz | perl -I./lib ./script/parse_goa.pl --subset goslim_generic 1> ./data/uniprot/sprot/goslim_generic/GoAnnotation.tsv 2> ./data/uniprot/sprot/goslim_generic/GoAnnotation.err
perl -e 'print"Fist::IO::GoAnnotation\t./data/uniprot/sprot/goslim_generic/GoAnnotation.tsv\tid_seq=DB\n";' | perl -I./lib ./script/import_tsv.pl 


## PDB chemical types (from Rob)


#perl -ne 'chomp; @F = split /\s+/, $_, 6; $F[0] =~ s/\A_+//; print join("\t", $F[0], ($F[2] eq "---") ? "none" : $F[2], $F[5]), "\n";' ~bq_rrussell/jobs/het/het_count_class_name3.txt > ./data/pdb_chem.tsv
perl -ne 'chomp; @F = split; $F[0] =~ s/\A_+//; print join("\t", @F), "\n";' /home/bq_rrussell/jobs/het/current_classes.txt > ./data/pdb_chem.tsv

mysql -p -D fistdb -e 'LOAD DATA LOCAL INFILE "./data/pdb_chem.tsv" INTO TABLE PdbChem (id_chem, type);'


## summary of protein, chemical and nucleic acid contacts for all residues
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  mkdir -p ./data/res_contact_info/${id_taxon}/
  perl -I./lib ./script/res_contact_info.pl --taxon ${id_taxon} --source 'uniprot-sprot' --outdir ./data/res_contact_info/ --pbs ${id_taxon} 1> ./data/res_contact_info/${id_taxon}/pbs.out 2> ./data/res_contact_info/${id_taxon}/pbs.err &
done


## summarise *all* possible prot-prot contacts, not just the best compatible ones for each pair of query proteins (as stored as ContactHits)
# NOTE: don't do all taxa together at the moment, as this will give inter-species interactions
for id_taxon in 272634 224308 83333 559292 6239 7227 10090 9606
do
  mkdir -p ./data/res_contact_info/pp/${id_taxon}/
  perl -I./lib ./script/contact_hits.pl --source 'uniprot-sprot' --outdir ./data/res_contact_info/pp/ --pbs ${id_taxon} --n_jobs 200 --all_matches --contact_info --taxon ${id_taxon} 1>./data/res_contact_info/pp/${id_taxon}/pbs.out 2> ./data/res_contact_info/pp/${id_taxon}/pbs.err &
done

# parse ids from killed jobs, and submit again in smaller jobs per taxon
mkdir -p ./data/res_contact_info/pp/missing/
for id_taxon in 10090 9606
do
  mkdir -p ./data/res_contact_info/pp/missing/${id_taxon}
  perl -I./lib ./script/contact_hits.pl --source 'uniprot-sprot' --outdir ./data/res_contact_info/pp/missing/ --pbs ${id_taxon} --n_jobs 200 --all_matches --contact_info --taxon ${id_taxon} --fn_id_queries ./data/res_contact_info/pp/missing/${id_taxon}.txt 1>./data/res_contact_info/pp/missing/${id_taxon}/pbs.out 2> ./data/res_contact_info/pp/missing/${id_taxon}/pbs.err &
done


## number of sequences per organism in sprot, sprot varsplic (isoforms), and trembl
for source in sprot sprot_varsplic trembl
do
  zcat $DS/uniprot/knowledgebase/complete/uniprot_${source}.fasta.gz | perl -ne 'if(/^>/){if(/^>.*OS=(.*?)\s+\S{2}=/){$os = $1;}elsif(/^>.*\s+OS=(.*)\Z/){$os = $1;}else{$os="UNK"; warn $_;} $S{$os}++;} END{foreach $os (sort {$S{$b} <=> $S{$a}} keys %S){print join("\t", $S{$os}, $os), "\n";}}' > ./data/${source}_seqs_per_os.txt 2> ./data/${source}_seqs_per_os.err &
done

## trembl
mkdir -p ./data/uniprot/trembl
/usr/bin/time -o ./data/uniprot/trembl/parse.time perl -I./lib ./script/parse_uniprot.pl --trembl --outdir ./data/uniprot/trembl/ /net/netfile1/ds-russell/uniprot/knowledgebase/complete/uniprot_trembl.dat.gz 1> ./data/uniprot/trembl/parse.txt 2> ./data/uniprot/trembl/parse.err
perl -e 'print"Fist::IO::Seq\t./data/uniprot/trembl/Seq.tsv\tid=01\nFist::IO::SeqToTaxon\t./data/uniprot/trembl/SeqToTaxon.tsv\tid_seq=01\nFist::IO::Alias\t./data/uniprot/trembl/Alias.tsv\tid_seq=01\n";' > ./data/uniprot/trembl/import.inp
/usr/bin/time -o ./data/uniprot/trembl/import.time perl -I./lib ./script/import_tsv.pl < ./data/uniprot/trembl/import.inp &> ./data/uniprot/trembl/import.err

## sprot-varsplic
mkdir -p ./data/uniprot/sprot_varsplic
perl -I./lib ./script/parse_fasta.pl --source sprot --outdir ./data/uniprot/sprot_varsplic /net/netfile1/ds-russell/uniprot/knowledgebase/complete/uniprot_sprot_varsplic.fasta.gz 1> ./data/uniprot/sprot_varsplic/parse.txt 2> ./data/uniprot/sprot_varsplic/parse.err

# get taxa via that of the 'master' isoform already in the db
perl -F'/\t/' -nae 'chomp(@F); if($F[2] eq "UniProtKB accession"){($ac = $F[1]) =~ s/-\d+\Z//;print"SELECT $F[0], b.id_taxon FROM Alias AS a, SeqToTaxon AS b WHERE a.alias = \"$ac\" AND a.type = \"UniProtKB accession\" AND b.id_seq = a.id_seq;\n";}' ./data/uniprot/sprot_varsplic/Alias.tsv | mysql -u anonymous -D fistdb --skip-column-names 1> data/uniprot/sprot_varsplic/SeqToTaxon.tsv 2> data/uniprot/sprot_varsplic/SeqToTaxon.err


## count the number of sequences in the eight species currently of interest
ls data/uniprot/{sprot,sprot_varsplic,trembl}/SeqToTaxon.tsv | perl -ne 'chomp; $fn = $_; ($id = $_) =~ s/.*data\/uniprot\/(\S+?)\/SeqToTaxon\S+/$1/; push @ids, $id; open(I, $fn) or die; while(<I>){($id_seq, $id_taxon) = split; $S{$id_taxon}->{$id}++;} END{foreach $id_taxon (9606,10090,7227,6239,559292,83333,224308,272634){print $id_taxon; foreach $id (@ids) {$n = defined($S{$id_taxon}->{$id}) ? $S{$id_taxon}->{$id} : 0; print "\t$n";} print"\n";}}'


## known ints from unint
#perl -I./lib ./script/parse_unint_precalc.pl < /net/netfile1/ds-russell/unint/precalc_2014-01/mapped_interactions_exp_syn_fix.tsv 2> data/unint.err | sort -u -o data/unint.tsv
perl -I./lib ./script/parse_unint_precalc.pl < /net/netfile1/ds-russell/unint/precalc_2014-01/unint_flags.tsv 2> data/unint.err | sort -u -o data/unint.tsv
mysql -p -D fistdb -e 'LOAD DATA LOCAL INFILE "./data/unint.tsv" INTO TABLE UnInt (id_seq1, id_seq2, type_ref, id_ref, method, id_int, source, id_source, physical, n_int_pmid, htp, n_discovery, trust);'
mysql -p -D fistdb -e '
CREATE TEMPORARY TABLE unint_count (source VARCHAR(10), id_source INTEGER UNSIGNED, n INTEGER UNSIGNED, PRIMARY KEY (source, id_source));
INSERT INTO unint_count (source, id_source, n)
SELECT source, id_source, COUNT(DISTINCT(id_seq)) n FROM (SELECT source, id_source, id_seq1 id_seq FROM UnInt UNION SELECT source, id_source, id_seq2 id_seq FROM UnInt) AS a GROUP BY source, id_source;
UPDATE UnInt AS a, unint_count AS b SET a.n = b.n WHERE b.source = a.source AND b.id_source = a.id_source;
'

## counts for figure
# (password required for creating temporary tables)
mysql -p -D fistdb --skip-column-names < sql/mechismo_pipeline_counts.sql 1> data/mechismo_pipeline_counts.txt 2> data/mechismo_pipeline_counts.err

mysql -u anonymous -D fistdb --quick --skip-column-names < sql/mechismo_pipeline_counts_ppPred_support.sql 1> data/mechismo_pipeline_counts_ppPred_support.txt 2> data/mechismo_pipeline_counts_ppPred_support.err
mysql -u anonymous -D fistdb --quick --skip-column-names < sql/mechismo_pipeline_counts_pdPred.sql 1> data/mechismo_pipeline_counts_pdPred.txt 2> data/mechismo_pipeline_counts_pdPred.err
mysql -u anonymous -D fistdb --quick --skip-column-names < sql/mechismo_pipeline_counts_pcPred.sql 1> data/mechismo_pipeline_counts_pcPred.txt 2> data/mechismo_pipeline_counts_pcPred.err

cat data/mechismo_pipeline_counts_ppPred_support.txt data/mechismo_pipeline_counts_pdPred.txt data/mechismo_pipeline_counts_pcPred.txt >> data/mechismo_pipeline_counts.txt

./script/mechismo_pipeline_counts_to_d3.pl < data/mechismo_pipeline_counts.txt > root/static/data/mechismo_pipeline_counts.json

./script/mechismo_pipeline_counts_to_table.pl < data/mechismo_pipeline_counts.txt > data/mechismo_pipeline_counts.table.txt


## get crystallisation conditions from pdb entries (REMARK 280, free-text unfortunately...)
find $DS/pdb/ -name '*.ent.gz' | perl -ne 'chomp; $f = $_; if($f =~ /pdb(\S{4}).ent.gz/){$idcode = $1; @rem = (); open(I, "zcat $f |") or die;while(<I>){if(/^REMARK 280 (.*?)\s*\Z/){push @rem, $1;}}close(I); (@rem > 0) and print join(" ", $idcode, @rem), "\n";}' > data/pdb.REMARK_280.txt 2> data/pdb.REMARK_280.err

# extract protein concentration where possible...
./script/pdb_xray_conc.pl < data/pdb.REMARK_280.txt | grep -v UNK | sort -n -k +2


############################## Memory ##############################

Memory used in Gb

                      RawMemory     Memory               Low memory
                      ------------  -------------------  ------------------
                      cache  vmem   cache  vmem   $json  cache  vmem   $json
                      -----  -----  -----  -----  -----  -----  -----  -----
DDX3X                  0.04   0.36   0.01   0.60
Jones                  5.44   8.24   0.91   2.09   0.34   0.91   1.87   0.02
uniprot disease mods  18.16  27.03   0.82   3.32   1.37   0.82   3.01   0.67
phosphosites human                   0.97  12.13  17.52   0.97   5.56   0.91


phosphosites human, sizes for json split in to different files:

Memory  Low
------  ----
     1     1  min_pcid_nuc.json
     1     1  min_pcid.json
     1     1  min_pcid_homo.json
     1     1  min_pcid_hetero.json
     1     1  min_pcid_chem.json
     2     2  min_pcid_known.json
     7     7  id_frag_hit_max.json
    10    10  known_level.json
    14    14  path.json
    19     -  seq_to_frag.json
   277   277  site_counts.json
   786   786  prot_counts.json
  108K  108K  query_seqs.json
  142K     -  ch_to_interface_sites.json
  218K  218K  seqs_to_aliases.json
  661K     -  ppis.json
  1.1M  1.1M  text.json
  1.1M  1.1M  params.json
  1.2M  1.2M  seqs.json
     -  1.3M  ppi_table.json
  2.0M  2.0M  prot_table.json
     -  3.6M  struct_table.json
  2.1M     -  pdis.json
  3.0M     -  pdbs.json
  3.2M     -  frags.json
  5.3M  5.3M  aliases.json
  7.2M     -  contact_hits.json
  7.4M  7.3M  network.json
     -   11M  pdi_table.json
     -   13M  pci_table.json
   16M     -  site_table.json
   24M   24M  sites.json
   29M     -  pcis.json
   36M     -  fh_to_interface_sites.json
   42M     -  frag_hits.json
  108M     -  known_ints_by_uniref.json
  161M     -  known_ints.json
  218M     -  frag_hit_info.json
------  ----  ----------
  666M   86M  (total)


Does it make sense to store the data in a db rather than in
json files? At least that way it does not all need to be read
in to memory just to load a single page. The tables at least
could be loaded asynchronously and in pieces.

Number of rows in low_mem versions of tables in json files:

              DDX3X  jones    udis  psites
              -----  -----  ------  ------
ppi_table         3    149    4157    9174  
pdi_table        89    509   11950   24964 
struct_table     31    857   47114   45910 
prot_table        2    620    2121   10253 
prot_counts       9      9       9       9        
pci_table        48   1269  141849  108394
site_counts       9      9       9       9        
site_table       11    705   24978   70419

(Note that this does not count sub-arrays that are present
in some elements.)

## get homodimers in reverse direction (except for completely closed homodimers)
mkdir -p ./data/contact_hits/reverse_homo
perl -I./lib ./script/reverse_homo_contact_hits.pl --outdir ./data/contact_hits/reverse_homo/ 1> ./data/contact_hits/reverse_homo/reverse_homo.txt 2> ./data/contact_hits/reverse_homo/reverse_homo.err

## import
# MAX(contact.id) before import = 3509814
# MAX(contact.id) after import  = 3584685
ls ./data/contact_hits/reverse_homo/ContactHit.tsv | perl -ne 'chomp; print"Fist::IO::ContactHit\t$_\tid=1\n";' > ./data/contact_hits/reverse_homo/import.inp
ls ./data/contact_hits/reverse_homo/ContactHitRes.tsv | perl -ne 'chomp; print"Fist::IO::ContactHitResidue\t$_\tid_contact_hit=1\n";' >> ./data/contact_hits/reverse_homo/import.inp
perl -I./lib ./script/import_tsv.pl < ./data/contact_hits/reverse_homo/import.inp &> ./data/contact_hits/reverse_homo/import.err

# FIXME - then test Gsk3b/S219Sp