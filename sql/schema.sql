# Table names as 'camel-case' (individual words capitalised) and never plural
# or plural-like, column names lower-case with words separated by underscores.
# This is so that they agree with the class names and accessor functions
# created from this schema by DBIx::Class::Schema::Loader via catalyst.

# sequences
DROP TABLE IF EXISTS Seq;
CREATE TABLE Seq (
       id             INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       primary_id     VARCHAR(20), # the primary identifier in the source db, eg. first UniProt accession
       name           VARCHAR(20), # eg. gene name
       seq            TEXT,
       len            SMALLINT UNSIGNED NOT NULL, # LENGTH(seq), included as an explicit column so it can be indexed
       chemical_type  VARCHAR(10) NOT NULL, # peptide, nucleotide, pdb chemical id, unknown
       source         VARCHAR(20) NOT NULL, # ENUM('uniprot-sprot', 'uniprot-trembl', 'fist', 'seqres', 'pdbseq', 'interprets') NOT NULL,
       description    TEXT NOT NULL,

       # source = fist       : sequence given by fist from ATOM/HETATM records
       # source = pdbseq     : sequence given by pdbseq
       # source = interprets : sequence given by interprets -fasta

       INDEX(seq(10)),
       INDEX(len),
       INDEX(chemical_type),
       INDEX(source),
       INDEX(primary_id)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Alignment;
CREATE TABLE Alignment (
       id      INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       method  VARCHAR(20),
       len     SMALLINT UNSIGNED NOT NULL,

       INDEX(method)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS AlignedSeq;
CREATE TABLE AlignedSeq (
       id_aln    INTEGER UNSIGNED NOT NULL,
       id_seq    INTEGER UNSIGNED NOT NULL,
       start     SMALLINT UNSIGNED NOT NULL DEFAULT 1,
       end       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
       _edit_str TEXT NOT NULL,

       PRIMARY KEY (id_aln, id_seq)

       # cannot use foreign keys on partitioned tables
       #FOREIGN KEY (id_aln) REFERENCES Alignment(id) ON DELETE CASCADE ON UPDATE CASCADE,
       #FOREIGN KEY (id_seq) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Taxon;
CREATE TABLE Taxon (
       id               INTEGER UNSIGNED NOT NULL PRIMARY KEY,
       id_parent        INTEGER UNSIGNED NOT NULL,
       scientific_name  VARCHAR(120) NOT NULL DEFAULT '',
       common_name      VARCHAR(70) NOT NULL DEFAULT '',

       INDEX(id_parent)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS SeqToTaxon;
CREATE TABLE SeqToTaxon (
       id_seq    INTEGER UNSIGNED NOT NULL,
       id_taxon  INTEGER UNSIGNED NOT NULL,

       PRIMARY KEY (id_seq, id_taxon),
       INDEX(id_taxon),

       FOREIGN KEY (id_seq) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE
       #FOREIGN KEY (id_taxon) REFERENCES Taxon(id) ON DELETE CASCADE ON UPDATE CASCADE # some pdb structures have obsolete taxon ids
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS SeqGroup;
CREATE TABLE SeqGroup (
       id    INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       type  VARCHAR(50) NOT NULL,
       ac    VARCHAR(30) NOT NULL,

       INDEX(type, ac)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS SeqToGroup;
CREATE TABLE SeqToGroup (
       id_seq    INTEGER UNSIGNED NOT NULL,
       id_group  INTEGER UNSIGNED NOT NULL,
       rep       BOOLEAN NOT NULL DEFAULT FALSE,

       PRIMARY KEY (id_group, id_seq),
       INDEX(id_seq),

       FOREIGN KEY (id_seq) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_group) REFERENCES SeqGroup(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS AlignmentToGroup;
CREATE TABLE AlignmentToGroup (
       id_aln    INTEGER UNSIGNED NOT NULL,
       id_group  INTEGER UNSIGNED NOT NULL,

       PRIMARY KEY (id_group, id_aln),
       INDEX(id_aln),

       FOREIGN KEY (id_aln) REFERENCES Alignment(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_group) REFERENCES SeqGroup(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Alias;
CREATE TABLE Alias (
       id_seq  INTEGER UNSIGNED NOT NULL,
       alias   VARCHAR(30) NOT NULL,
       type    VARCHAR(50) NOT NULL,

       PRIMARY KEY (id_seq, alias, type),
       INDEX(alias),
       INDEX(type),

       FOREIGN KEY (id_seq) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

# structures
DROP TABLE IF EXISTS Pdb;
CREATE TABLE Pdb (
       idcode      CHAR(4) NOT NULL PRIMARY KEY,
       title       VARCHAR(255),
       resolution  FLOAT NOT NULL DEFAULT 99999,
       depdate     DATE NOT NULL DEFAULT '9999-12-31', # PDB deposition date
       updated     DATE NOT NULL DEFAULT '9999-12-31', # PDB revision date

       INDEX(resolution),
       INDEX(depdate),
       INDEX(updated)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Expdta;
CREATE TABLE Expdta (
       idcode  CHAR(4) NOT NULL,
       expdta  ENUM(
                    'ELECTRON DIFFRACTION',
                    'ELECTRON MICROSCOPY',
                    'ELECTRON CRYSTALLOGRAPHY',
                    'CRYO-ELECTRON MICROSCOPY',
                    'SOLUTION SCATTERING',
                    'FIBER DIFFRACTION',
                    'FLUORESCENCE TRANSFER',
                    'NEUTRON DIFFRACTION',
                    'POWDER DIFFRACTION',
                    'SOLUTION NMR',
                    'THEORETICAL MODEL',
                    'X-RAY DIFFRACTION'
                   ),

       PRIMARY KEY (idcode, expdta),
       INDEX(expdta),

       FOREIGN KEY (idcode) REFERENCES Pdb(idcode) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Frag;
CREATE TABLE Frag (
       id             INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       idcode         CHAR(4) NOT NULL,
       id_seq         INTEGER UNSIGNED NOT NULL, # id of sequence of source 'fist'
       fullchain      BOOLEAN NOT NULL DEFAULT FALSE,
       description    TEXT NOT NULL,
       chemical_type  VARCHAR(10) NOT NULL, # peptide, nucleotide, pdb chemical id, unknown

       dom            TEXT NOT NULL, # STAMP format domain description. Could be derived from location(s)
                                     # and the method to derive them could be part of API, but good to
                                     # store result here too so that we know where seq comes from.
                                     # Type = VARBINARY so that dom is case sensitive

       INDEX(idcode),
       INDEX(chemical_type),

       FOREIGN KEY (idcode) REFERENCES Pdb(idcode) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_seq) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS FragDssp;
CREATE TABLE FragDssp (
       id_frag        INTEGER UNSIGNED NOT NULL,
       chain          BINARY(1) NOT NULL, # chain id, type = BINARY so that chain is case sensitive
       resseq         SMALLINT SIGNED NOT NULL, # PDB residue sequence number - needs to be a SIGNED integer
       icode          BINARY(1) NOT NULL,
       ss             ENUM('H', 'B', 'E', 'G', 'I', 'T', 'S', 'C') NOT NULL DEFAULT 'C',
       phi            FLOAT NOT NULL DEFAULT 0,
       psi            FLOAT NOT NULL DEFAULT 0,

       PRIMARY KEY (id_frag, chain, resseq, icode)

       # cannot use foreign keys on partitioned tables
       #FOREIGN KEY (id_frag) REFERENCES Frag(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS FragNaccess;
CREATE TABLE FragNaccess (
       id_frag        INTEGER UNSIGNED NOT NULL,
       chain          BINARY(1) NOT NULL, # chain id, type = BINARY so that chain is case sensitive
       resseq         SMALLINT SIGNED NOT NULL, # PDB residue sequence number - needs to be a SIGNED integer
       icode          BINARY(1) NOT NULL,
       acc            FLOAT UNSIGNED NOT NULL DEFAULT 0, # all atom absolute accessibility
       acc_s          FLOAT UNSIGNED NOT NULL DEFAULT 0, # sidechain absolute accessibility

       PRIMARY KEY (id_frag, chain, resseq, icode)

       # cannot use foreign keys on partitioned tables
       #FOREIGN KEY (id_frag) REFERENCES Frag(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS ChainSegment;
CREATE TABLE ChainSegment (
       id       INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       id_frag  INTEGER UNSIGNED NOT NULL,
       chain    BINARY(1) NOT NULL,

       resseq_start  SMALLINT SIGNED NOT NULL, # PDB residue sequence number - needs to be a SIGNED integer
       icode_start   BINARY(1) NOT NULL,
       resseq_end    SMALLINT SIGNED NOT NULL, # PDB residue sequence number - needs to be a SIGNED integer
       icode_end     BINARY(1) NOT NULL,

       # joining to ResMapping with the fields above will give the position in
       # the fullchain fist sequence but we normally need the position in the
       # fragment fist sequence, so store that in the following fields
       fist_start    INTEGER UNSIGNED NOT NULL,
       fist_len      INTEGER UNSIGNED NOT NULL,

       INDEX(id_frag, chain, resseq_start, icode_start, resseq_end, icode_end),

       FOREIGN KEY (id_frag) REFERENCES Frag(id) ON DELETE CASCADE ON UPDATE CASCADE
)       
ENGINE=MyISAM
;

DROP TABLE IF EXISTS FragToSeqGroup;
CREATE TABLE FragToSeqGroup (
       id_frag    INTEGER UNSIGNED NOT NULL,
       id_group   INTEGER UNSIGNED NOT NULL,

       PRIMARY KEY(id_frag, id_group),
       INDEX(id_group),

       FOREIGN KEY (id_frag) REFERENCES Frag(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_group) REFERENCES SeqGroup(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

# Do not need a frag.type column:
#
# - if a fragment comes from SCOP it will be linked to from the scop
#   table, with scop.sunid IS NULL
#
# - if a fragment comes from a match to SCOP it will be linked to from
#   the scop table with scop.sunid IS NOT NULL
#
# - if a fragment is a whole chain then frag.fullchain = TRUE. It may
#   also be linked to from the scop table.
#
# - if a fragment is not a whole chain and is not from scop (eg. comes
#   from assembling BLAST HSPs) then it will frag.fullchain = FALSE and
#   it will not be linked to from the scop table.

# FIXME - also have position table, as per pdb/2011-09-28/schema.sql ?

DROP TABLE IF EXISTS FragResMapping;
CREATE TABLE FragResMapping (
       id_frag     INTEGER UNSIGNED NOT NULL,
       fist        SMALLINT UNSIGNED NOT NULL, # one-based position in sequence given by fist from ATOM/HETATM records
       chain       BINARY(1) NOT NULL,         # chain id, type = BINARY so that chain is case sensitive
       resseq      SMALLINT SIGNED NOT NULL,   # PDB residue sequence number - needs to be a SIGNED integer
       icode       BINARY(1) NOT NULL,         # PDB residue insertion code
       res3        CHAR(3) NOT NULL,           # three-letter residue code
       res1        CHAR(1) NOT NULL,           # one-letter residue code

       PRIMARY KEY (id_frag, fist),
       INDEX(id_frag, chain, resseq, icode),
       INDEX(res3)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Ecod;
CREATE TABLE Ecod (
       id           INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       x            SMALLINT UNSIGNED,
       h            SMALLINT UNSIGNED,
       t            SMALLINT UNSIGNED,
       f            SMALLINT UNSIGNED,
       name         TEXT,

       INDEX(x, h, t, f)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS FragToEcod;
CREATE TABLE FragToEcod (
       id_frag      INTEGER UNSIGNED NOT NULL,
       id_ecod      INTEGER UNSIGNED NOT NULL,
       type         ENUM('ecod', 'match') NOT NULL DEFAULT 'ecod', # origin of the ECOD annotation
       ac           VARCHAR(30) NOT NULL,

       PRIMARY KEY (id_frag, id_ecod),
       INDEX(id_ecod),
       INDEX(type),
       INDEX(ac),

       FOREIGN KEY (id_frag) REFERENCES Frag(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_ecod) REFERENCES Ecod(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS FragGroup;
CREATE TABLE FragGroup (
       id      INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       type    VARCHAR(50) NOT NULL,

       INDEX(type)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS FragToGroup;
CREATE TABLE FragToGroup (
       id         INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       id_frag    INTEGER UNSIGNED NOT NULL,
       id_group   INTEGER UNSIGNED NOT NULL,
       rep        BOOLEAN NOT NULL DEFAULT FALSE,

       INDEX(id_frag),
       INDEX(id_group),

       FOREIGN KEY (id_frag) REFERENCES Frag(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_group) REFERENCES FragGroup(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

# instances of structure pieces in pdb or pdb-biounit
DROP TABLE IF EXISTS FragInst;
CREATE TABLE FragInst (
       id        INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       id_frag   INTEGER UNSIGNED NOT NULL,  # = 0 for pdb, > 0 for pdb-biounit
       assembly  SMALLINT UNSIGNED NOT NULL, # = 0 for pdb, > 0 for pdb-biounit
       model     SMALLINT UNSIGNED NOT NULL,  # not TINYINT as is sometimes > 255, eg. for 1m4x, a virus capsid

       INDEX(id_frag, assembly, model),

       FOREIGN KEY (id_frag) REFERENCES Frag(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

# transformation that superposes frag_inst1 on to frag_inst2
# should be given in both directions
DROP TABLE IF EXISTS Tran;
CREATE TABLE Tran (
       id_frag_inst1  INTEGER UNSIGNED NOT NULL,
       id_frag_inst2  INTEGER UNSIGNED NOT NULL,
       pcid           SMALLINT UNSIGNED NOT NULL DEFAULT 0,
       sc             FLOAT NOT NULL,
       rmsd           FLOAT NOT NULL,

       # Now storing the tranformation as twelve floats, = 48 bytes,
       # rather than as text. The text as output by stamp has ca. 150
       # characters, which would take 150 bytes with the latin1 character set.
       # Also easier to use in non-STAMP programs.
       #
       # r11 r12 r13 v1
       # r21 r22 r23 v2
       # r31 r32 r33 v3
       #
       # This transformation superposes entity1 on to entity2

       r11  FLOAT NOT NULL,
       r12  FLOAT NOT NULL,
       r13  FLOAT NOT NULL,
       v1   FLOAT NOT NULL,
       r21  FLOAT NOT NULL,
       r22  FLOAT NOT NULL,
       r23  FLOAT NOT NULL,
       v2   FLOAT NOT NULL,
       r31  FLOAT NOT NULL,
       r32  FLOAT NOT NULL,
       r33  FLOAT NOT NULL,
       v3   FLOAT NOT NULL,
        
       PRIMARY KEY (id_frag_inst1, id_frag_inst2),
       INDEX(pcid),
       INDEX(sc),
       INDEX(rmsd),

       FOREIGN KEY (id_frag_inst1) REFERENCES FragInst(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_frag_inst2) REFERENCES FragInst(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

# Contacts also assumed to be stored in both directions

# Entries in Contact can be single contacts or groups of contacts.
# This will make it easier to cluster contacts based on properties
# of the representative or of the member contacts

DROP TABLE IF EXISTS Contact;
CREATE TABLE Contact ( 
       id              INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,

       # if this contact represents a group, these are for the representative contact:
       id_frag_inst1   INTEGER UNSIGNED NOT NULL,
       id_frag_inst2   INTEGER UNSIGNED NOT NULL,
       crystal         BOOLEAN NOT NULL DEFAULT FALSE,
       n_res1          SMALLINT UNSIGNED NOT NULL,
       n_res2          SMALLINT UNSIGNED NOT NULL,
       n_clash         SMALLINT UNSIGNED NOT NULL,
       n_resres        SMALLINT UNSIGNED NOT NULL,
       homo            BOOLEAN NOT NULL DEFAULT 0,

       INDEX(id_frag_inst1, id_frag_inst2), # not unique because may be a representative of a group as well as a contact
       INDEX(crystal),
       INDEX(n_res1),
       INDEX(n_res2),
       INDEX(n_clash),
       INDEX(n_resres),

       FOREIGN KEY (id_frag_inst1) REFERENCES FragInst(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_frag_inst2) REFERENCES FragInst(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS ContactGroup;
CREATE TABLE ContactGroup (
       id         INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       id_parent  INTEGER UNSIGNED NOT NULL,
       type       VARCHAR(50) NOT NULL,

       INDEX(type)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS ContactToGroup;
CREATE TABLE ContactToGroup (
       id_contact INTEGER UNSIGNED NOT NULL,
       id_group   INTEGER UNSIGNED NOT NULL,
       rep        BOOLEAN NOT NULL DEFAULT FALSE,

       PRIMARY KEY (id_group, id_contact),
       INDEX(id_contact),

       FOREIGN KEY (id_contact) REFERENCES Contact(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_group) REFERENCES ContactGroup(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

# pairs of residues in contact, stored in both directions
DROP TABLE IF EXISTS ResContact;
CREATE TABLE ResContact (
       id_contact  INTEGER UNSIGNED NOT NULL,

       bond_type   SMALLINT UNSIGNED NOT NULL,

       chain1      BINARY(1) NOT NULL,
       resseq1     SMALLINT SIGNED NOT NULL,
       icode1      BINARY(1) NOT NULL,

       chain2      BINARY(1) NOT NULL,
       resseq2     SMALLINT SIGNED NOT NULL,
       icode2      BINARY(1) NOT NULL,

       # need icode1 and icode2 in the primary key, or will lose data
       #PRIMARY KEY (id_contact, chain1, resseq1, icode1, chain2, resseq2, icode2)

       # using UNIQUE INDEX rather than PRIMARY KEY so that it can be turned off for import
       #UNIQUE INDEX (id_contact, chain1, resseq1, icode1, chain2, resseq2, icode2)

       # better to have a smaller index and filter by chain1 etc afterwards
       INDEX(id_contact)

       # cannot use foreign keys on partitioned tables, or when id_frag_inst2 does not exist (is '0' for intra-fraginst contacts)
       #FOREIGN KEY (id_frag_inst1) REFERENCES FragInst(id) ON DELETE CASCADE ON UPDATE CASCADE,
       #FOREIGN KEY (id_frag_inst2) REFERENCES FragInst(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
# Using MyISAM so that keys can be turned off for import
;

DROP TABLE IF EXISTS ResResJaccard;
CREATE TABLE ResResJaccard ( 
       id_frag_inst_a1  INTEGER UNSIGNED NOT NULL, # not using contact id as will be queried for contact groups as well as contacts
       id_frag_inst_b1  INTEGER UNSIGNED NOT NULL,
       id_frag_inst_a2  INTEGER UNSIGNED NOT NULL,
       id_frag_inst_b2  INTEGER UNSIGNED NOT NULL,
       intersection     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
       aln_n_resres1    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
       aln_n_resres2    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
       aln_union        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
       aln_jaccard      FLOAT NOT NULL DEFAULT 0,
       full_union       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
       full_jaccard     FLOAT NOT NULL DEFAULT 0,

       INDEX(id_frag_inst_a1, id_frag_inst_b1)
  
       # to reduce index size, so that it is more likely to fit in memory:
       # - do not need the primary key below as have only queried for all jaccards to a particular contact so far
       # - have not queried by jaccard so far

       #PRIMARY KEY(id_frag_inst_a1, id_frag_inst_b1, id_frag_inst_a2, id_frag_inst_b2),
       #INDEX(id_frag_inst_a2, id_frag_inst_b2)
       #INDEX(aln_jaccard),
       #INDEX(full_jaccard)
)
ENGINE=MyISAM
# Using MyISAM so that keys can be turned off for import
;

DROP TABLE IF EXISTS Hsp;
CREATE TABLE Hsp (
       # can also get seq IDs via Alignment, but needed here as order is important
       # because BLAST can give different results for query=A hit=B and vice-versa
       id       INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,

       id_seq1  INTEGER UNSIGNED NOT NULL, 
       id_seq2  INTEGER UNSIGNED NOT NULL,

       pcid     FLOAT NOT NULL,
       a_len    SMALLINT UNSIGNED NOT NULL,
       n_gaps   SMALLINT UNSIGNED NOT NULL,

       start1   SMALLINT UNSIGNED NOT NULL,
       end1     SMALLINT UNSIGNED NOT NULL,

       start2   SMALLINT UNSIGNED NOT NULL,
       end2     SMALLINT UNSIGNED NOT NULL,

       e_value  DOUBLE NOT NULL,
       score    FLOAT NOT NULL,
       id_aln   INTEGER UNSIGNED NOT NULL,

       INDEX(id_seq1, start1, end1),
       INDEX(id_seq2, start2, end2),
       INDEX(id_seq1, id_seq2, pcid), # for faster SELECT & ORDER using these columns
       INDEX(pcid),
       INDEX(e_value)

       # cannot use foreign keys on partitioned tables
       #FOREIGN KEY (id_seq1) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE,
       #FOREIGN KEY (id_seq2) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE,
       #FOREIGN KEY (id_aln) REFERENCES Alignment(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
# - Using MyISAM so that keys can be turned off for import
# - Not partitioning as will often join from hsp to contact to hsp, requiring the whole table
;

# matches of queries to fragments
# i.e. FragHits = a processed set of HSPs
DROP TABLE IF EXISTS FragHit;
CREATE TABLE FragHit (
       id_seq1  INTEGER UNSIGNED NOT NULL, # first component of query

       start    SMALLINT UNSIGNED NOT NULL,
       end      SMALLINT UNSIGNED NOT NULL,

       # the following link this table to the Hsp table - start and end above may be a subsection of the Hsp
       start1   SMALLINT UNSIGNED NOT NULL,
       end1     SMALLINT UNSIGNED NOT NULL,

       id_seq2  INTEGER UNSIGNED NOT NULL, # second component of query
       start2   SMALLINT UNSIGNED NOT NULL,
       end2     SMALLINT UNSIGNED NOT NULL,

       pcid     FLOAT NOT NULL, # copy of data from Hsp, for easier queries
       e_value  DOUBLE NOT NULL,
       id_aln   INTEGER UNSIGNED NOT NULL,

       PRIMARY KEY (id_seq1, start, end),

       FOREIGN KEY (id_seq1) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_seq2) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_aln) REFERENCES Alignment(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

# matches of queries to contacts
DROP TABLE IF EXISTS ContactHit;
CREATE TABLE ContactHit (
       id               INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,

       type             VARCHAR(6) NOT NULL DEFAULT "UNK",

       # need id_seq, start, end for all four components for easy join to Hsp table

       id_seq_a1        INTEGER UNSIGNED NOT NULL, # first component of query
       start_a1         SMALLINT UNSIGNED NOT NULL,
       end_a1           SMALLINT UNSIGNED NOT NULL,

       id_seq_b1        INTEGER UNSIGNED NOT NULL, # second component of query
       start_b1         SMALLINT UNSIGNED NOT NULL,
       end_b1           SMALLINT UNSIGNED NOT NULL,

       id_seq_a2        INTEGER UNSIGNED NOT NULL, # first component of template
       start_a2         SMALLINT UNSIGNED NOT NULL,
       end_a2           SMALLINT UNSIGNED NOT NULL,

       id_seq_b2        INTEGER UNSIGNED NOT NULL, # second component of template
       start_b2         SMALLINT UNSIGNED NOT NULL,
       end_b2           SMALLINT UNSIGNED NOT NULL,

       id_contact       INTEGER UNSIGNED NOT NULL,

       n_res_a1         SMALLINT UNSIGNED NOT NULL,
       n_res_b1         SMALLINT UNSIGNED NOT NULL,
       n_resres_a1b1    SMALLINT UNSIGNED NOT NULL,

       pcid_a           FLOAT NOT NULL, # copy of data from Hsp, for easier queries
       e_value_a        DOUBLE NOT NULL,
       pcid_b           FLOAT NOT NULL,
       e_value_b        DOUBLE NOT NULL,

       chr              BLOB, # gzip compressed string of contact hit residues

       # FIXME - are all these indicies necessary? They will take a lot of space.
       INDEX(id_seq_a1, start_a1, end_a1),
       INDEX(id_seq_b1, start_b1, end_b1),
       INDEX(id_seq_a2, start_a2, end_a2),
       INDEX(id_seq_b2, start_b2, end_b2),
       INDEX(pcid_a),
       INDEX(pcid_b)

       #INDEX(n_resres_a1b1),
       #INDEX(e_value_a),
       #INDEX(e_value_b)

       #FOREIGN KEY (id_seq_a1, start_a1, end_a1, id_seq_b1, start_b1, end_b1) REFERENCES Hsp(id_seq1, start1, end1, id_seq2, start2, end2) ON DELETE CASCADE ON UPDATE CASCADE,
       #FOREIGN KEY (id_seq_a2, start_a2, end_a2, id_seq_b2, start_b2, end_b2) REFERENCES Hsp(id_seq1, start1, end1, id_seq2, start2, end2) ON DELETE CASCADE ON UPDATE CASCADE,
       #FOREIGN KEY (id_contact) REFERENCES Contact(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
# - Using MyISAM so that keys can be turned off for import
# - not partitioning as will often query by id_seq_a1 or id_seq_b1, etc
;

DROP TABLE IF EXISTS ContactHitInterprets;
CREATE TABLE ContactHitInterprets (
       id_contact_hit INTEGER UNSIGNED NOT NULL,
       mode           TINYINT UNSIGNED NOT NULL,
       rand           MEDIUMINT UNSIGNED NOT NULL,
       raw            DOUBLE NOT NULL,
       mean           DOUBLE NOT NULL,
       sd             DOUBLE NOT NULL,
       z              DOUBLE NOT NULL,

       INDEX (id_contact_hit, mode, rand)

       #FOREIGN KEY (id_contact_hit) REFERENCES ContactHit(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Pmid;
CREATE TABLE Pmid (
       pmid        INTEGER UNSIGNED NOT NULL PRIMARY KEY,
       throughput  ENUM('high', 'medium', 'low', 'single', 'none') NOT NULL DEFAULT 'none',

       INDEX(throughput)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS PmidToFeatureInst;
CREATE TABLE PmidToFeatureInst (
       id_feature_inst INTEGER UNSIGNED NOT NULL,
       pmid            INTEGER UNSIGNED NOT NULL,

       PRIMARY KEY (id_feature_inst, pmid),
       INDEX(pmid),

       FOREIGN KEY (id_feature_inst) REFERENCES FeatureInst(id) ON DELETE CASCADE ON UPDATE CASCADE
       #FOREIGN KEY (pmid) REFERENCES Pmid(pmid) ON DELETE CASCADE ON UPDATE CASCADE # not all PMIDs are in PMID table
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Feature;
CREATE TABLE Feature (
       id           INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       source       VARCHAR(20) NOT NULL,
       ac_src       VARCHAR(30) NOT NULL,
       id_src       VARCHAR(30) NOT NULL,
       type         VARCHAR(30) NOT NULL,
       regex        VARCHAR(200),
       description  TEXT NOT NULL,

       INDEX(source, ac_src, type),
       INDEX(source, id_src),
       INDEX(type)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS FeatureInst;
CREATE TABLE FeatureInst (
       id             INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       id_seq         INTEGER UNSIGNED NOT NULL,
       id_feature     INTEGER UNSIGNED NOT NULL,
       ac             VARCHAR(30) NOT NULL,
       start_seq      SMALLINT UNSIGNED NOT NULL,
       end_seq        SMALLINT UNSIGNED NOT NULL,
       start_feature  SMALLINT UNSIGNED NOT NULL,
       end_feature    SMALLINT UNSIGNED NOT NULL,
       wt             VARCHAR(255) NOT NULL DEFAULT '',
       mt             VARCHAR(255) NOT NULL DEFAULT '',
       e_value        DOUBLE NOT NULL,
       score          FLOAT NOT NULL,
       true_positive  BOOLEAN NOT NULL DEFAULT FALSE,
       description    TEXT,

       # cannot use PRIMARY KEY (id_seq, id_feature) as can have more than
       # one instance of a particular feature on a particular sequence
       INDEX(id_seq),
       INDEX(id_feature),
       INDEX(ac),
       INDEX(true_positive),

       FOREIGN KEY (id_seq) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_feature) REFERENCES Feature(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS FeatureInstContact;
CREATE TABLE FeatureInstContact (
       id             INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       id_frag_inst1  INTEGER UNSIGNED NOT NULL,
       id_frag_inst2  INTEGER UNSIGNED NOT NULL,
       id_feat_inst1  INTEGER UNSIGNED NOT NULL,
       id_feat_inst2  INTEGER UNSIGNED NOT NULL,
       n_resres       SMALLINT UNSIGNED NOT NULL,

       INDEX(id_frag_inst1, id_frag_inst2),
       INDEX(id_feat_inst1, id_feat_inst2),

       FOREIGN KEY (id_frag_inst1) REFERENCES FragInst(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_frag_inst2) REFERENCES FragInst(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_feat_inst1) REFERENCES FeatureInst(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_feat_inst2) REFERENCES FeatureInst(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

# 'FeatureContact' table defined in update_feature_contact.sql

DROP TABLE IF EXISTS GoTerm;
CREATE TABLE GoTerm (
       id         CHAR(10) NOT NULL PRIMARY KEY,
       namespace  ENUM('biological_process', 'molecular_function', 'cellular_component'),
       name       VARCHAR(250),
       def        TEXT NOT NULL,

       INDEX(namespace)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS GoAnnotation;
CREATE TABLE GoAnnotation (
       id_seq         INTEGER UNSIGNED NOT NULL,
       id_term        CHAR(10) NOT NULL,
       subset         VARCHAR(50) NOT NULL DEFAULT 'none', # none, goslim_generic, ...
       evidence_code  VARCHAR(3) NOT NULL,

       PRIMARY KEY (id_seq, id_term, subset, evidence_code),
       INDEX (subset),

       FOREIGN KEY (id_seq) REFERENCES Seq(id) ON DELETE CASCADE ON UPDATE CASCADE,
       FOREIGN KEY (id_term) REFERENCES GoTerm(id) ON DELETE CASCADE ON UPDATE CASCADE
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Disease;
CREATE TABLE Disease (
       id      INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
       id_mim  INTEGER UNSIGNED NOT NULL,
       abbr    VARCHAR(10) NOT NULL, # abbreviation
       name    TEXT NOT NULL,

       INDEX(id_mim),
       INDEX(abbr),
       INDEX(name(10))
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS ChemComp;
CREATE TABLE ChemComp (
       id                 CHAR(3) NOT NULL PRIMARY KEY,
       name               VARCHAR(700),
       formula            VARCHAR(50),
       systematic_name    VARCHAR(700),
       stereo_smiles      VARCHAR(700),
       non_stereo_smiles  VARCHAR(700),
       in_chi             VARCHAR(1500)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS PdbChem;
CREATE TABLE PdbChem (
       id_chem      CHAR(3) NOT NULL PRIMARY KEY,
       type         VARCHAR(20) NOT NULL DEFAULT 'none',
       description  TEXT NOT NULL,

       INDEX(type)
)
ENGINE=MyISAM
;

DROP TABLE IF EXISTS Job;
CREATE TABLE Job (
        id           INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, # so the order in which the jobs were submitted can be seen
        id_search    VARCHAR(20) NOT NULL,
        search_name  VARCHAR(255) NOT NULL DEFAULT '',
        ipint        BIGINT NOT NULL DEFAULT 0,
        hostname     VARCHAR(255) NOT NULL DEFAULT '',
        queue_name   VARCHAR(20) NOT NULL,
        n_aliases    INTEGER UNSIGNED NOT NULL DEFAULT 0,
        n_labels     INTEGER UNSIGNED NOT NULL DEFAULT 0,
        type         ENUM('short', 'long') NOT NULL DEFAULT 'long',
        status       ENUM('queued', 'running', 'finished', 'error') NOT NULL DEFAULT 'queued',
        queued       INTEGER UNSIGNED NOT NULL DEFAULT 0, # time in seconds at which the job was queued
        started      INTEGER UNSIGNED NOT NULL DEFAULT 0, # time in seconds at which the job was started
        finished     INTEGER UNSIGNED NOT NULL DEFAULT 0, # time in seconds at which the job was finished
        message      TEXT,
        pid          INTEGER UNSIGNED NOT NULL DEFAULT 0, # id of process than ran the job

        UNIQUE INDEX(id_search),
        INDEX(queue_name),
        INDEX(status)
)
ENGINE=InnoDB # InnoDB because of row-locking
;

DROP TABLE IF EXISTS StringInt;
CREATE TABLE StringInt (
       id_seq1      INTEGER UNSIGNED NOT NULL,
       id_seq2      INTEGER UNSIGNED NOT NULL,

       # uniprot to string matching is not one-to-one, so need to save the string ids
       # here too to ensure that we can link to the correct interaction in string

       id_string1   VARCHAR(30) NOT NULL, 
       id_string2   VARCHAR(30) NOT NULL,

       score        SMALLINT UNSIGNED NOT NULL,

       PRIMARY KEY (id_seq1, id_seq2)
)
ENGINE=MyISAM
;
