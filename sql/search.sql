/* 
For search parameters and so on. Linked to Job.id_search.
Or merge with Job table?
*/
CREATE TABLE Search (
        id
        name
        known_level
        min_pcid_chem
        min_pcid_hetero
        min_pcid_homo
        min_pcid
        min_pcid_known
        min_pcid_nuc
        path
        dn_search
        id_search
        search_file
        search
        stringency
        taxon
)
ENGINE=InnoDB
;

CREATE TABLE SearchSeq (
        id
        user_input
        mechScore
)
ENGINE=InnoDB
;

CREATE TABLE SearchSite (
        id
        id_seq
        pos
        res1
        given_res
        res2
        disordered
        blosum62
        label
        label_orig
        mechProt
        mechChem
        mechDNA
        mechScore
)
ENGINE=InnoDB
;

CREATE TABLE SearchPPI (
        id
        id_site
        id_ch
        homo # FIXME - move this to Contact and/or ContactHit?
        conf # FIXME - move this to ContactHit?
        ie
        ie_class
)
ENGINE=InnoDB
;

CREATE TABLE SearchPPIEvidence (
        id_search_ppi
)
ENGINE=InnoDB
;

CREATE TABLE SearchPCI (
        id
        id_site
        id_fh # FIXME - FragHits / HSPs need an identifier
        chem_type # including DNA/RNA
        id_chem
        conf # FIXME - move this to FragHit?
        ie
        ie_class
)
ENGINE=InnoDB
;

CREATE TABLE SearchStruct (
        id
        id_site
        id_fh # FIXME - FragHits / HSPs need an identifier
)
ENGINE=InnoDB
;


Aliases

Network
ProtCounts
ProtTable
QuerySeqs
Seqs
SeqsToAliases
SiteCounts
Sites
SiteTable
Taxa
