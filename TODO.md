######

- sifts matches are represented as global alignments but would be
  clearer to remove N and C-terminal overhangs to fix start and end
  positions in HSPs (probably easiest in alignment.c)


######


########## OLD TODO (check if still relevant...) ##########

######

- map fist, pdbseq and interprets sequence positions to chain, resSeq and iCode,
  via alignment and through knowing the chain, resSeq and iCode for fist positions

- for each SeqGroup, count all sites on representative
- for each SeqGroup, count all sites on representatives of sub SeqGroups of specified type

- map sites to alignment positions
- map sites between members of a SeqGroup via the alignment
- find the member with the most sites mapped, set as representative
- for groups with no sites, choose a representative

- fix dbuser issue in fist.conf

###### IO ######

FIXME - ability to select IO to Schema or NonDB versions of objects
FIXME - handle insert of db objects

######

protein sequences
 - with or without structure (a sequence can have more than one structure)
 - with or without modifications (PTMs, mutations)
 - groups
   - grouped by
     - same taxon
     - sequence similarity
     - database links (eg. uniprot to pdb)
     - structural similarity
     - uniref 100, 90, 50 via groups
   - alignments for some groups
     - map between member sequence positions and from member sequence positions to alignment positions
     - map modifications of member sequences on to alignment positions. (Could do with all sequence features?)
   - total counts for group
   - counts per subgroup (eg. 'all PTMs per uniref 90 subgroup of taxon 9606 group')
     - generate on the fly if quick enough or pregenerate
   - representative sequence
     - modifications of all members of group mapped to representative
       via alignment. (Could do with all sequence features?)
 - sequence features
   - start-end
     - IUPred
     - Pfam
     - GO annotations (don't have start and end but fit otherwise)
     - ...
   - single position
     - PTMs
       - high-throughput / low-throughput
     - mutations

structures
 - a structure can have more than one sequence: from uniprot, fist, pdbseq, or interprets


###### proteins

- unique list of taxon ids of all proteins considered
- get all uniprot sequences for those taxa
- get scientific and common names of all taxa
- load mapping of uniprot accessions and identifiers in to alias table
- import sequences into db, using interbal db identifiers for proteins
- import uniref
- protein groups
- use uniref.level=100 to make taxa sequence files non-redundant
  at 100% identity and identical sequence lengths, then
  output non-redundant sequences to fasta files (use prot.id as identifiers)


###### structures

- load pdb and pdb-biounit chains in to db
- get pdbseq, interprets, pdbaa and uniprot sequences for all PDB chains
- pdb species
- plot distribution of species in PDB

- blast interprets sequences all-vs-all

- create fragments
  - from whole chains
  - from SCOP
- create fragment instances
  - extend from pdb to biounit
  - how can templates including parts of multiple chains (eg. some SCOPs) be extended to pdb-biounit instances?
- centres of mass of all fragment instances (FIXME - cofm gives 'Rmax = nan' on Fedora 14)
- contacts between all pairs of fragment instances
- mark crystal contacts (= those in pdb but not in biounit)

- make blastdb of interprets sequences of fragments

- group fragments with 100% sequence identity across entire length
- group highly-redundant interaction templates: 100% sequence identity across entire length, for both components
- refine interaction template groups to those with identical contact residues (jaccard index = 1)
  - assumes that the sequences are 100% identical, otherwise will need alignment of the two sequences to
    look for correspondance of contact residues


###### PTMs

- 'ptm' table to 'modification' table, allowing for mutations as well as PTMs
- load PTMs in to db (only load those where res agrees with sequence at given position and id_taxon agrees)
- load PTM pubmed links
- load PTM sources
- PTM high/low-throughput - count the number of proteins per PMID
- correlated PTMs
- use temporal data from phosida database
- allow non-modified equivalents of PTMs to be specified (i.e. background)


###### proteins and structures

- split nr sequences into smaller sets then BLAST against the PDB (without SEG filtering)
- load blast results in to db
- ignore blast matches to over-represented PDB chains
- get possible templates for all intra-species pairs of proteins
- go from contacts in template to contacts in protein pair via alignment
- find real examples where prot1 interacts with >1 prot2
  - calculate stoichiometry in these cases using compatible templates data
- define best templates for each pair of prots, only considering side-chain side-chain interactions.
  - make sure multiple instances of this running at the same time do not re-use template IDs


###### proteins and structures and PTMs

- identify PTMs in interfaces from best templates (sidechain-sidechain contacts)
- find PTMs that are in contact with others
- use alignments to identify interesting substitutions between protein and pdb, eg asp/glu for phospho sites. Could also use resres_contacts data to do this.
- count PTMs coverage at different levels:
  - when using best template for each (uniref90) pair


###### Misc

- GO terms

- network view (cytoscape?) of structured interactome
  - colour by PTMs and their likely effects
  - also show unmodified equivalents

- counts per species at different levels of non-redundancy
  - proteins
  - pairs of proteins
  - pairs with templates
  - compatible templates

- analyse nature of interface around a particular site
  - measure significance of differences in charge etc

- use non-redundant, non-nested contacts to define res-res log-odds scores, as per interprets

- group tables in schema.sql in a meaningful way

- refactor TransDB::Adjacency in to new modules

- remove old methods from this README and re-order it

- be consistant with underscores or capitals; id_prot or idProt, but not both

- use uniref alignments to map PTMs on to one representative
- HTP and LTP PTMs
- run naccess on all fragments
- run iupred
- get other sequence features and load in to database
- get the best template(s) for each protein on its own (i.e. don't care if it's an interaction template or not).

- background for each PTM type
- which PTMs are surface exposed?
- counts (iupred, exposed, etc.)

- best_templates should take in to account alternative templates,
  eg 1P3H and 1WE3 for GroS-GroS (the latter for GroS homomultimer int with GroL homomultimer)

- nr prots should be in protGroup table
- protGroup table (and equivalents) should store a link to the representative

- make sure correct 'sequence position to pdb seqRes' conversion is used;
  Interprets sequences can be slightly different to pdbseq, and I'm using the
  former for contacts but the latter for mapping those contacts via alignments.

- pdbseq/i2/PDB residue mapping (+ uniprot?)

- a single protein can have more than one UniProtKB accession,
  and these can belong to different uniref clusters... when the uniref
  clusters were formed before uniprot entries were merged/demerged.
  So take the uniref that applies to the most accessions.

- counts of AA types affected

- possible to detect modified residues in PDB? eg. present as HETATMs?
