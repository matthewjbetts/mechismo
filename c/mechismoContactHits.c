#include <locale.h>
#include "myFile.h"
#include "list.h"
#include "strings.h"
#include "hash.h"
#include "contact.h"
#include "contactHit.h"
#include "alignment.h"

void usage() {
    fprintf(stderr, "\n");
    fprintf(stderr, "Usage: mechismoContactHits [options]\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "option              parameter  description                                                         default\n");
    fprintf(stderr, "------------------  ---------  ------------------------------------------------------------------  -------\n");
    fprintf(stderr, "--help              [none]     print this usage info and exit\n");
    fprintf(stderr, "--queries           string     name of file of queries                                             [none]\n");
    fprintf(stderr, "--contacts          string     name of file of contacts                                            [none]\n");
    fprintf(stderr, "--hsps              string     name of file of hsps                                                [none]\n");
    fprintf(stderr, "--dom_to_seq        string     name of file that maps dom ids used in contacts to seqs in hsps     [none]\n");
    fprintf(stderr, "--dom_to_chem_type  string     name of file that maps dom ids used in contacts to frag chem types  [none]\n");
    fprintf(stderr, "--contact_to_group  string     name of file of mechismo-format ContactToGroup output               [none]\n");
    fprintf(stderr, "                               file to sequence ids used in hsp file\n");
    fprintf(stderr, "--pcid              float      minimum percent sequence identity of hsps                           -1.0\n");
    fprintf(stderr, "--lf_query          float      minimum fraction of query sequence covered by hsps                  0.0\n");
    fprintf(stderr, "--lf_fist           float      minimum fraction of template (fist) sequence covered by hsps        0.8\n");
    fprintf(stderr, "--contact_hit       string     name of file for ContactHit output                                  [to stdout]\n");
    fprintf(stderr, "--contact_hit_res   string     name of file for ContactHitResidue output                           [none]\n");
    fprintf(stderr, "--ppiresres         integer    minimum number of residue-residue contacts per PPI contact          10\n");
    fprintf(stderr, "--pdiresres         integer    minimum number of residue-base contacts per PDI contact             10\n");
    fprintf(stderr, "--pciresres         integer    minimum number of residue-chemical contacts per PCI contact         1\n");
    fprintf(stderr, "--n_templates       integer    maximum number of non-redundant interaction templates to use        5\n");
    fprintf(stderr, "                               pair of query proteins\n");
    fprintf(stderr, "\n");
    exit(-1);
}

typedef struct args {
    char           fn_queries[FILENAMELEN];
    char           fn_contacts[FILENAMELEN];
    char           fn_hsps[FILENAMELEN];
    char           fn_dom_to_seq[FILENAMELEN]; 
    char           fn_dom_to_chem_type[FILENAMELEN]; 
    char           fn_contact_to_group[FILENAMELEN];
    char           fn_contact_hit[FILENAMELEN];
    char           fn_contact_hit_res[FILENAMELEN];
    unsigned short minPPIResRes, minPDIResRes, minPCIResRes;
    unsigned short maxNTemplates;
    float          minPcid;
    float          minLfQuery;
    float          minLfFist;
} ARGS;

ARGS *getArgs(int argc, char **argv) {
    ARGS *args;
    int  i, j;
    int  len;

    // FIXME - abstract out the actual arguments to make this function directly usable by other programs

    // FIXME - remove switch arguments from argc and argv so that only other arguments remain

    // initialise defaults
    args = (ARGS *) malloc(sizeof(ARGS));
    if(args == NULL) {
        fprintf(stderr, "Error: main: malloc failed for args.\n");
        return NULL;
    }

    args->minPcid = -1.0;
    args->minLfQuery = 0.0;
    args->minLfFist = 0.8;
    args->minPPIResRes = 10;
    args->minPDIResRes = 10;
    args->minPCIResRes = 1;
    args->maxNTemplates = 5;
    memset(args->fn_queries, '\0', FILENAMELEN);
    memset(args->fn_contacts, '\0', FILENAMELEN);
    memset(args->fn_hsps, '\0', FILENAMELEN);
    memset(args->fn_dom_to_seq, '\0', FILENAMELEN);
    memset(args->fn_dom_to_chem_type, '\0', FILENAMELEN);
    memset(args->fn_contact_to_group, '\0', FILENAMELEN);
    memset(args->fn_contact_hit, '\0', FILENAMELEN);
    memset(args->fn_contact_hit_res, '\0', FILENAMELEN);

    for(i = 1; i < argc; ++i) {
        len = strlen(argv[i]);

        if(argv[i][0] != '-')
            return NULL;

        j = (argv[i][1] == '-') ? 2 : 1; // allow for '--' style
        len -= j; // allow for short versions

        if(strncmp(&argv[i][j], "help", len) == 0) { 
            return NULL;
        }
        else if(strncmp(&argv[i][j], "queries", len) == 0) { 
            strncpy(args->fn_queries, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "contacts", len) == 0) { 
            strncpy(args->fn_contacts, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "hsps", len) == 0) { 
            strncpy(args->fn_hsps, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "dom_to_seq", len) == 0) { 
            strncpy(args->fn_dom_to_seq, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "dom_to_chem_type", len) == 0) { 
            strncpy(args->fn_dom_to_chem_type, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "pcid", len) == 0) { 
            sscanf(argv[++i], "%f", &args->minPcid);
        }
        else if(strncmp(&argv[i][j], "lf_query", len) == 0) { 
            sscanf(argv[++i], "%f", &args->minLfQuery);
        }
        else if(strncmp(&argv[i][j], "lf_fist", len) == 0) { 
            sscanf(argv[++i], "%f", &args->minLfFist);
        }
        else if(strncmp(&argv[i][j], "ppiresres", len) == 0) { 
            args->minPPIResRes = (unsigned short) strtoul(argv[++i], NULL, 0);
        }
        else if(strncmp(&argv[i][j], "pdiresres", len) == 0) { 
            args->minPDIResRes = (unsigned short) strtoul(argv[++i], NULL, 0);
        }
        else if(strncmp(&argv[i][j], "pciresres", len) == 0) { 
            args->minPCIResRes = (unsigned short) strtoul(argv[++i], NULL, 0);
        }
        else if(strncmp(&argv[i][j], "n_templates", len) == 0) { 
            args->maxNTemplates = (unsigned short) strtoul(argv[++i], NULL, 0);
        }
        else if(strncmp(&argv[i][j], "contact_to_group", len) == 0) { 
            strncpy(args->fn_contact_to_group, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "contact_hit", len) == 0) { 
            strncpy(args->fn_contact_hit, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "contact_hit_res", len) == 0) { 
            strncpy(args->fn_contact_hit_res, argv[++i], FILENAMELEN);
        }
        else {
            return NULL;
        }
    }

    if(args->fn_queries[0] == '\0') return NULL;
    if(args->fn_contacts[0] == '\0') return NULL;
    if(args->fn_hsps[0] == '\0') return NULL;
    if(args->fn_dom_to_seq[0] == '\0') return NULL;
    if(args->fn_contact_to_group[0] == '\0') return NULL;

    return args;
}

int contactHitNR(
                 unsigned int *idCh,
                 const char *idSeqA1,
                 HASH *contactHits,  // contactHits = contact hits of idSeqA1 will all its interactors
                 HASH *contactToGroup,
                 unsigned short maxNTemplates,
                 FILE *fhContactHit,
                 FILE *fhContactHitResidue,
                 unsigned short minPPIResRes,
                 unsigned short minPDIResRes,
                 unsigned short minPCIResRes
                 ) {
    LIST           *idsInteractors;
    char           *idInteractor;
    LIST           *contactHitsInteractor; // all contact hits of idSeqA1 with the specific interactor
    char           *discardCh;
    unsigned short nTemplates;
    int            i, j, k;
    char           idContactKey1[IDLEN], idContactKey2[IDLEN]; // id for ContactHit as a string
    CONTACTHIT     *ch1, *ch2;
    char           *idGroup1, *idGroup2;

    if((idsInteractors = hashGetAllKeys(contactHits)) != NULL) {
        for(i = 0; i < idsInteractors->n; i++) {
            idInteractor = (char *) idsInteractors->all[i];
            if((contactHitsInteractor = (LIST *) hashGetElement(contactHits, idInteractor)) != NULL) {

                if(contactHitsInteractor->n > 1) listSort(contactHitsInteractor, contactHitSortBest);
                nTemplates = 0;

                if((discardCh = (char *) calloc(contactHitsInteractor->n, sizeof(char))) == NULL) {
                    fprintf(stderr, "Error: calloc failed for discardCh.\n");
                    continue;
                }
                for(j = 0; j < contactHitsInteractor->n; j++) {
                    ch1 = (CONTACTHIT *) contactHitsInteractor->all[j];
                    if(discardCh[j] == 0) {
                        memset(idContactKey1, '\0', IDLEN);
                        sprintf(idContactKey1, "%u", ch1->cA2B2->id);
                        ch1->id = ++(*idCh);

                        contactHitResiduesCreate(ch1);
                        if(
                           (ch1->nResResA1B1 == 0)
                           || ((strncmp(ch1->type, "PPI", 3) == 0) && (ch1->nResResA1B1 < minPPIResRes))
                           || ((strncmp(ch1->type, "PDI", 3) == 0) && (ch1->nResResA1B1 < minPDIResRes))
                           || (ch1->nResResA1B1 < minPCIResRes)
                           ) {
                            discardCh[j] = 1;
                            //printf("discarding %u\n", ch1->id);
                            contactHitResiduesDelete(ch1);
                            continue;
                        }
                        contactHitOutput(ch1, fhContactHit, fhContactHitResidue);
                        contactHitResiduesDelete(ch1);

                        if(++nTemplates >= maxNTemplates) break;

                        idGroup1 = (char *) hashGetElement(contactToGroup, idContactKey1);
                        if(idGroup1 != NULL) {
                            for(k = j + 1; k < contactHitsInteractor->n; k++) {
                                if(discardCh[k] == 0) {
                                    ch2 = (CONTACTHIT *) contactHitsInteractor->all[k];
                                    memset(idContactKey2, '\0', IDLEN);
                                    sprintf(idContactKey2, "%u", ch2->cA2B2->id);
                                    idGroup2 = (char *) hashGetElement(contactToGroup, idContactKey2);

                                    // are the contacts in the same contact group?
                                    if((idGroup2 != NULL) && (strcmp(idGroup2, idGroup1) == 0)) {
                                        discardCh[k] = 1;
                                        //printf("discarding %u\n", ch2->id);
                                    }

                                    // old measure of redundancy - hits overlap on both A1 and B1
                                    /*
                                    if((ch1->hspA1A2 != NULL) && (ch1->hspB2B1 != NULL) && (ch2->hspA1A2 != NULL) && (ch2->hspB2B1 != NULL)) {
                                        if(
                                           (lineOverlap(ch1->hspA1A2->start1, ch1->hspA1A2->end1, ch2->hspA1A2->start1, ch2->hspA1A2->end1) > 0)
                                           && (lineOverlap(ch1->hspB2B1->start2, ch1->hspB2B1->end2, ch2->hspB2B1->start2, ch2->hspB2B1->end2) > 0)
                                           ) {
                                            discardCh[k] = 1;
                                        }
                                    }
                                    */

                                    // FIXME - any better measures of redundancy?
                                }
                            }
                        }
                    }
                }
                free(discardCh);
                listDelete(contactHitsInteractor, contactHitDelete);
            }
        }
        listDelete(idsInteractors, NULL);
    }

    return 0;
}

int main(int argc, char **argv) {
    ARGS           *args;
    MYFILE         *file;
    char           *line;
    char           str[IDLEN];
    char           *idSeqA1, *idSeqA2, *idSeqB2, *idSeqB1;
    char           *idDomA2, *idDomB2;
    LIST           *queries        = NULL;
    HASH           *hsps           = NULL;
    HASH           *domToSeq       = NULL;
    HASH           *domToChemType  = NULL;
    HASH           *seqToDom       = NULL;
    HASH           *contacts       = NULL;
    HASH           *contactToGroup = NULL;
    HASH           *contacts2      = NULL;
    LIST           *idsDom         = NULL;
    LIST           *idsSeqsA2      = NULL;
    LIST           *idsDomsA2      = NULL;
    LIST           *idsDomsB2      = NULL;
    LIST           *idsSeqsB1      = NULL;
    int            i, j, k, l, m;
    HASH           *hspsA1, *hspsB2;
    LIST           *hspsA1A2, *hspsB2B1;
    HSP            *hspA1A2, *hspB2B1;
    unsigned int   idCh; // id for ContactHit
    HASH           *contactHitsA1B1s; // contact hits between a specific A1 and all its B1
    LIST           *contactHitsA1B1; // contact hits between a specific A1 and a specific B1
    HASH           *contactHitsA1B2s; // contact hits between a specific A1 and all its B2s (that don't have matching B1s)
    LIST           *contactHitsA1B2; // contact hits between a specific A1 and a specific B2
    CONTACT        *cA2B2;
    CONTACTHIT     *ch1;
    FILE           *fhContactHit;
    FILE           *fhContactHitResidue;
    int            flag;

    args = getArgs(argc, argv);
    if(args == NULL) usage();

    // open output files
    if(args->fn_contact_hit[0] == '\0') {
        fhContactHit = stdout;
    }
    else {
        if((fhContactHit = fopen(args->fn_contact_hit, "w")) == NULL) {
            fprintf(stderr, "Error: cannot open '%s' file for writing.\n", args->fn_contact_hit);
            exit(0);
        }
    }

    // only outputting contact hit residues separately if specifically requested
    if(args->fn_contact_hit_res[0] == '\0') {
        fhContactHitResidue = NULL;
    }
    else {
        if((fhContactHitResidue = fopen(args->fn_contact_hit_res, "w")) == NULL) {
            fprintf(stderr, "Error: cannot open '%s' file for writing.\n", args->fn_contact_hit_res);
            exit(0);
        }
    }

    // read in all id_seq for query sequences
    if((queries = listCreate("queries")) == NULL) exit(1);
    if((file = myFileOpen(args->fn_queries)) == NULL) exit(1);
    if(myFileRead(file) != 0) exit(1);
    line = (*file->nextLine)(file);
    while(line != NULL) {
        memset(str, '\0', IDLEN);
        sscanf(line, "%s", str);
        idSeqA1 = stringCopy(str);
        listAddElement(queries, 1, idSeqA1);
        line = (*file->nextLine)(file);
    }
    myFileDelete(file);

    // read in query-fist hsps and their alignments
    // will need to be able to query them by fist sequence too, so save in both directions
    if((hsps = hspParse(args->fn_hsps, args->minPcid, args->minLfQuery, args->minLfFist, hspSaveBoth)) == NULL) exit(1);

    // read in id_dom to id_seq
    // FIXME - could save memory by ignoring fist sequences that are not in an hsp
    if((domToSeq = hashParseTsv(args->fn_dom_to_seq, NULL)) == NULL) exit(1);
    hashResize(domToSeq, domToSeq->nKeys * 4 / 3);

    // read in id_dom to chem type
    // FIXME - could save memory by ignoring fist sequences that are not in an hsp
    if((domToChemType = hashParseTsv(args->fn_dom_to_chem_type, NULL)) == NULL) exit(1);
    hashResize(domToChemType, domToChemType->nKeys * 4 / 3);

    // get seqToDom
    idsDom = hashGetAllKeys(domToSeq);
    seqToDom = hashCreate(idsDom->n);
    for(i = 0; i < idsDom->n; i++) {
        idDomA2 = idsDom->all[i];
        idSeqA2 = hashGetElement(domToSeq, idDomA2);

        if((idsDomsA2 = hashGetElement(seqToDom, idSeqA2)) == NULL) {
            if((idsDomsA2 = listCreate(NULL)) == NULL) exit(1);
            hashAddElement(seqToDom, idSeqA2, idsDomsA2);
        }
        listAddElement(idsDomsA2, 1, idDomA2);
    }
    
    // read in contacts given as sequence numbers
    // FIXME - could save memory by ignoring contacts involving fist sequences that are not in an hsp
    if((contacts = hashCreate(0)) == NULL) exit(1);
    if((contactParse(args->fn_contacts, contacts, contactSaveToHash, 1, args->minPPIResRes, args->minPDIResRes, args->minPCIResRes)) != 0) exit(1); // NB. contacts only stored in given direction

    // read in contact groups
    if((contactToGroup = hashParseTsv(args->fn_contact_to_group, NULL)) == NULL) exit(1);
    hashResize(contactToGroup, contactToGroup->nKeys * 4 / 3);

    // get contact hits
    flag = 0; 
    idCh = 0;
    //for(i = 0; i < 0; i++) {
    for(i = 0; i < queries->n; i++) {
        idSeqA1 = (char *) queries->all[i];
        //printf("idSeqA1\t%d\t%s\n", i, idSeqA1);
        //flag = ((strcmp(idSeqA1, "680402") == 0) || (strcmp(idSeqA1, "780077") == 0)) ? 1 : 0;
        //if(flag == 0) continue;

        if((contactHitsA1B1s = hashCreate(0)) == NULL) continue;
        if((contactHitsA1B2s = hashCreate(0)) == NULL) continue;
        if((hspsA1 = hashGetElement(hsps, idSeqA1)) != NULL) {
            if((idsSeqsA2 = hashGetAllKeys(hspsA1)) != NULL) {
                for(j = 0; j < idsSeqsA2->n; j++) {
                    idSeqA2 = (char *) idsSeqsA2->all[j];
                    hspsA1A2 = (LIST *) hashGetElement(hspsA1, idSeqA2);
                    hspA1A2 = (HSP *) hspsA1A2->all[0]; // FIXME - check all hsps
                    //if(flag) printf("HSPA1A2\t%s\t%s\n", idSeqA1, idSeqA2);

                    // get all doms for this sequence
                    if((idsDomsA2 = hashGetElement(seqToDom, idSeqA2)) != NULL) {
                        for(k = 0; k < idsDomsA2->n; k++) {
                            idDomA2 = (char *) idsDomsA2->all[k];
                            //if(flag) printf("idDomA2\t%d\t%s\n", k, idDomA2);

                            // get all contacts for this dom
                            if((contacts2 = hashGetElement(contacts, idDomA2)) != NULL) {
                                if((idsDomsB2 = hashGetAllKeys(contacts2)) != NULL) {
                                    for(l = 0; l < idsDomsB2->n; l++) {
                                        idDomB2 = (char *) idsDomsB2->all[l];
                                        //if(flag) printf("idDomB2\t%d\t%s\n", l, idDomB2);
                                        cA2B2 = (CONTACT *) hashGetElement(contacts2, idDomB2);
                                        //if(flag) printf("CONTACT %u\t%s\t%s\n", cA2B2->id, idDomA2, idDomB2);

                                        // get the sequence for this dom
                                        if((idSeqB2 = (char *) hashGetElement(domToSeq, idDomB2)) != NULL) {
                                            //if(flag) printf("idSeqB2\t%s\n", idSeqB2);
                                            // get all queries matched to this sequence
                                            if((hspsB2 = hashGetElement(hsps, idSeqB2)) != NULL) {
                                                if((idsSeqsB1 = hashGetAllKeys(hspsB2)) != NULL) {
                                                    for(m = 0; m < idsSeqsB1->n; m++) {
                                                        idSeqB1 = (char *) idsSeqsB1->all[m];
                                                        hspsB2B1 = (LIST *) hashGetElement(hspsB2, idSeqB1);
                                                        hspB2B1 = (HSP *) hspsB2B1->all[0]; // FIXME - check all hsps
                                                        //if(flag) printf("HSPB2B1\t%s\t%s\n", idSeqB2, idSeqB1);

                                                        ch1 = contactHitCreate(0, idSeqA1, idSeqB1, idSeqA2, idSeqB2, cA2B2, hspA1A2, hspB2B1, domToChemType); // ch1->id will be set later, on output

                                                        // saving now to ignore redundancies later
                                                        if((contactHitsA1B1 = (LIST *) hashGetElement(contactHitsA1B1s, idSeqB1)) == NULL) {
                                                            if((contactHitsA1B1 = listCreate(NULL)) == NULL) continue;
                                                            hashAddElement(contactHitsA1B1s, idSeqB1, contactHitsA1B1);
                                                        }
                                                        listAddElement(contactHitsA1B1, 1, ch1);
                                                    }
                                                    listDelete(idsSeqsB1, NULL);
                                                }
                                            }
                                            else {
                                                /*
                                                 * is an interaction structure but no seqB1 matches to seqB2 - might
                                                 * be a nucleotide, chemical or a small peptide in the structure
                                                 */
                                                ch1 = contactHitCreate(0, idSeqA1, NULL, idSeqA2, idSeqB2, cA2B2, hspA1A2, NULL, domToChemType); // ch1->id will be set later, on output

                                                // saving now to ignore redundancies later
                                                if((contactHitsA1B2 = (LIST *) hashGetElement(contactHitsA1B2s, idSeqB2)) == NULL) {
                                                    if((contactHitsA1B2 = listCreate(NULL)) == NULL) continue;
                                                    hashAddElement(contactHitsA1B2s, idSeqB2, contactHitsA1B2);
                                                }
                                                listAddElement(contactHitsA1B2, 1, ch1);
                                            }
                                        }
                                        else {
                                            // should always be a 'sequence' for chemicals now, which will just be the PDB chemical id
                                            fprintf(stderr, "Error: no sequence for domB2 '%s'\n", idDomB2);
                                        }
                                    }
                                    listDelete(idsDomsB2, NULL);
                                }
                            }
                        }
                    }
                }
                listDelete(idsSeqsA2, NULL);
            }
        }

        contactHitNR(&idCh, idSeqA1, contactHitsA1B1s, contactToGroup, args->maxNTemplates, fhContactHit, fhContactHitResidue, args->minPPIResRes, args->minPDIResRes, args->minPCIResRes);
        contactHitNR(&idCh, idSeqA1, contactHitsA1B2s, contactToGroup, args->maxNTemplates, fhContactHit, fhContactHitResidue, args->minPPIResRes, args->minPDIResRes, args->minPCIResRes);
        hashDelete(contactHitsA1B1s, NULL);
        hashDelete(contactHitsA1B2s, NULL);

        //if(flag) break;
    }

    // cleanup
    if(domToSeq != NULL) hashDeleteTsv(domToSeq);
    if(domToChemType != NULL) hashDeleteTsv(domToChemType);
    if(seqToDom != NULL) hashDelete(seqToDom, hashDeleteList);
    if(idsDom != NULL) listDelete(idsDom, NULL);
    if(contacts != NULL) hashDelete(contacts, contactDeleteHash);
    if(queries != NULL) listDelete(queries, stringDelete);
    if(hsps != NULL) hashDelete(hsps, hspsDelete);
    if(contactToGroup != NULL) hashDeleteTsv(contactToGroup);
    if(args->fn_contact_hit[0] != '\0') fclose(fhContactHit);
    if(args->fn_contact_hit_res[0] != '\0') fclose(fhContactHitResidue);
    free(args);

    exit(0);
}
