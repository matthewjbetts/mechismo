#include <locale.h>
#include "myFile.h"
#include "list.h"
#include "strings.h"
#include "hash.h"
#include "contact.h"
#include "alignment.h"

int seqGroupOutput(const char *label, LIST *group) {
    int  i;
    char *idSeq;

    printf("# seqGroup %u, %s, size = %u\n", group->id, label, group->n); 
    for(i = 0; i < group->n; i++) {
        idSeq = (char *) group->all[i];
        printf("%u\t%s\n", group->id, idSeq);
    }

    return 0;
}

int contactGroupOutputText(const char *type, LIST *group, unsigned int idParent, FILE *fh_contact_group, FILE *fh_contact_to_group) { // same as next function so I can use a pointer to a function
    int     i;
    CONTACT *c;

    printf("# contactGroup %u, %s, size = %u\n", group->id, type, group->n); 
    for(i = 0; i < group->n; i++) {
        c = (CONTACT *) group->all[i];
        printf("%u\t%u\t%u\t%s\t%s\n", group->id, c->nResRes, c->id, c->idDomA, c->idDomB);
    }

    return 0;
}

int contactGroupOutputMechismo(const char *type, LIST *group, unsigned int idParent, FILE *fh_contact_group, FILE *fh_contact_to_group) {
    int          i;
    CONTACT      *c;
    unsigned int rep;

    fprintf(fh_contact_group, "%u\t%u\t%s\n", group->id, idParent, type);
    //fflush(fh_contact_group);
    rep = 0; // FIXME - choose a representative contact
    for(i = 0; i < group->n; i++) {
        c = (CONTACT *) group->all[i];
        fprintf(fh_contact_to_group, "%u\t%u\t%u\n", c->id, group->id, rep);
        //fflush(fh_contact_to_group);
    }

    return 0;
}

void usage() {
    fprintf(stderr, "\n");
    fprintf(stderr, "Usage: mechismoGroupContacts [options]\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "option              parameter  description                                              default\n");
    fprintf(stderr, "------------------  ---------  -------------------------------------------------------  -------\n");
    fprintf(stderr, "--help              [none]     print this usage info and exit\n");
    fprintf(stderr, "--contacts          string     name of file of contacts                                 [none]\n");
    fprintf(stderr, "--hsps              string     name of file of hsps                                     [none]\n");
    fprintf(stderr, "--dom_to_seq        string     name of file that maps dom ids used in contacts          [none]\n");
    fprintf(stderr, "                               file to sequence ids used in hsp file\n");
    fprintf(stderr, "--pcid              float      minimum percent sequence identity of hsps                0.0\n");
    fprintf(stderr, "--lf                float      minimum fraction of sequence covered by hsps             0.9\n");
    fprintf(stderr, "--jaccard           float      minimum resres contact jaccard                           0.9\n");
    fprintf(stderr, "--contact_group     string     name of file for mechismo-format ContactGroup output.    [text to stdout]\n");
    fprintf(stderr, "--contact_to_group  string     name of file for mechismo-format ContactToGroup output.  [text to stdout]\n");
    fprintf(stderr, "\n");
    //fprintf(stderr, "1 - these options can be used more than once\n");
    fprintf(stderr, "\n");
    exit(-1);
}

typedef struct args {
    LIST  *fns_contacts;
    LIST  *fns_hsps;
    LIST  *fns_dom_to_seq;
    char  fn_contact_group[FILENAMELEN];
    char  fn_contact_to_group[FILENAMELEN];
    float minPcid;
    float minLf;
    float minJaccard;
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

    args->minPcid = 0.0;
    args->minLf = 0.9;
    args->minJaccard = 0.9;
    args->fns_contacts = listCreate(NULL);
    args->fns_hsps = listCreate(NULL);
    args->fns_dom_to_seq = listCreate(NULL);
    memset(args->fn_contact_group, '\0', FILENAMELEN);
    memset(args->fn_contact_group, '\0', FILENAMELEN);
    memset(args->fn_contact_to_group, '\0', FILENAMELEN);

    for(i = 1; i < argc; ++i) {
        len = strlen(argv[i]);

        if(argv[i][0] != '-')
            return NULL;

        j = (argv[i][1] == '-') ? 2 : 1; // allow for '--' style
        len -= j; // allow for short versions

        if(strncmp(&argv[i][j], "help", len) == 0) { 
            return NULL;
        }
        else if(strncmp(&argv[i][j], "contacts", len) == 0) { 
            listAddElement(args->fns_contacts, 1, argv[++i]);
        }
        else if(strncmp(&argv[i][j], "hsps", len) == 0) { 
            listAddElement(args->fns_hsps, 1, argv[++i]);
        }
        else if(strncmp(&argv[i][j], "dom_to_seq", len) == 0) { 
            listAddElement(args->fns_dom_to_seq, 1, argv[++i]);
        }
        else if(strncmp(&argv[i][j], "pcid", len) == 0) { 
            sscanf(argv[++i], "%f", &args->minPcid);
        }
        else if(strncmp(&argv[i][j], "lf", len) == 0) { 
            sscanf(argv[++i], "%f", &args->minLf);
        }
        else if(strncmp(&argv[i][j], "jaccard", len) == 0) { 
            sscanf(argv[++i], "%f", &args->minJaccard);
        }
        else if(strncmp(&argv[i][j], "contact_group", len) == 0) { 
            strncpy(args->fn_contact_group, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "contact_to_group", len) == 0) { 
            strncpy(args->fn_contact_to_group, argv[++i], FILENAMELEN);
        }
        else {
            return NULL;
        }
    }

    if(args->fns_contacts->n == 0) return NULL;
    if(args->fns_hsps->n == 0) return NULL;
    if(args->fns_dom_to_seq == 0) return NULL;

    return args;
}

int argsDelete(ARGS *args) {
    listDelete(args->fns_contacts, NULL);
    listDelete(args->fns_hsps, NULL);
    listDelete(args->fns_dom_to_seq, NULL);
    free(args);

    return 1;
}

int main(int argc, char **argv) {
    ARGS         *args;
    HASH         *hsps      = NULL;
    HASH         *domToSeq  = NULL;
    LIST         *seqIds    = NULL;
    LIST         *seqGroups = NULL;
    LIST         *contacts  = NULL;
    int          i, j;
    unsigned int idSeqGroup, idContactGroup;
    LIST         *contactGroupsBySeq;
    LIST         *contactGroupBySeq;
    LIST         *contactGroupsByJacc;
    LIST         *contactGroupByJacc;
    char         label1[100], label2[100];
    FILE         *fh_contact_group;
    FILE         *fh_contact_to_group;
    int          (*contactGroupOutput)(const char *, LIST *, unsigned int, FILE *, FILE *);

    args = getArgs(argc, argv);
    if(args == NULL) usage();

    if(args->fn_contact_group[0] == '\0') {
        fh_contact_group = NULL;
        fh_contact_to_group = NULL;
        contactGroupOutput = &contactGroupOutputText;
    }
    else {
        if((fh_contact_group = fopen(args->fn_contact_group, "w")) == NULL) {
            fprintf(stderr, "Error: cannot open '%s' file for writing.\n", args->fn_contact_group);
            exit(0);
        }
        if((fh_contact_to_group = fopen(args->fn_contact_to_group, "w")) == NULL) {
            fprintf(stderr, "Error: cannot open '%s' file for writing.\n", args->fn_contact_to_group);
            exit(0);
        }
        contactGroupOutput = &contactGroupOutputMechismo;
    }

    // read in id_dom to id_seq
    if((domToSeq = hashParseTsv(args->fns_dom_to_seq->all[0], NULL)) == NULL) exit(1);
    hashResize(domToSeq, domToSeq->nKeys * 4 / 3);
    if((seqIds = hashGetAllValues(domToSeq)) == NULL) exit(1); // FIXME - this list will have repetitions if several domains map to the same seq id

    // read in hsps and their alignments
    if((hsps = hspParse(args->fns_hsps->all[0], args->minPcid, args->minLf, args->minLf, hspSaveForward)) == NULL) exit(1);

    // group sequences by single linkage using given hsps
    idSeqGroup = 0;
    if((seqGroups = hspGroupSeqs(seqIds, hsps, args->minPcid, args->minLf, &idSeqGroup)) == NULL) exit(1);
    /*
    sprintf(label1, "pcid >= %.2f, lf >= %.2f", args->minPcid, args->minLf);
    for(i = 0; i < seqGroups->n; i++) {
        seqGroup = (LIST *) seqGroups->all[i];
        seqGroupOutput(label1, seqGroup);
    }
    */

    // read in contacts given as sequence numbers
    if((contacts = listCreate(NULL)) == NULL) exit(1);
    if((contactParse(args->fns_contacts->all[0], contacts, contactSaveToList, 0, 1)) != 0) exit(1);

    // group contacts by sequence and by jaccard index of res-res contacts
    idContactGroup = 0;
    if((contacts != NULL) && (domToSeq != NULL)) {
        if(seqGroups == NULL) {
            // group contacts with identical seqs
            sprintf(label1, "identical sequences");
            sprintf(label2, "%s, jaccard >= %.2f", label1, args->minJaccard);
            if((contactGroupsBySeq = contactGroupBySequence(contacts, domToSeq, NULL, &idContactGroup)) == NULL) exit(1);

            if(args->minJaccard > 1.0) {
                for(i = 0; i < contactGroupsBySeq->n; i++) {
                    contactGroupBySeq = (LIST *) contactGroupsBySeq->all[i];
                    (*contactGroupOutput)(label1, contactGroupBySeq, 0, fh_contact_group, fh_contact_to_group);
                }
            }
            else {
                for(i = 0; i < contactGroupsBySeq->n; i++) {
                    contactGroupBySeq = (LIST *) contactGroupsBySeq->all[i];
                    (*contactGroupOutput)(label1, contactGroupBySeq, 0, fh_contact_group, fh_contact_to_group);

                    /*
                     * it isn't strictly necessary to subdivide a group that only has one member...
                     * ... but it's nice to have the contact in a jaccard group by itself too, to
                     * make subsequent querying easier.
                     */
                
                    if((contactGroupsByJacc = contactGroupByJaccards(contactGroupBySeq, domToSeq, args->minJaccard, hsps, &idContactGroup)) == NULL) exit(1);
                    for(j = 0; j < contactGroupsByJacc->n; j++) {
                        contactGroupByJacc = (LIST *) contactGroupsByJacc->all[j];
                        (*contactGroupOutput)(label2, contactGroupByJacc, contactGroupBySeq->id, fh_contact_group, fh_contact_to_group);
                    }
                    listDelete(contactGroupsByJacc, listDeleteList);
                }
            }

            listDelete(contactGroupsBySeq, listDeleteList);
        }
        else {
            // group contacts between FragInsts with pcid >= minPcid and lf >= minLf
            sprintf(label1, "pcid >= %.2f, lf >= %.2f", args->minPcid, args->minLf);
            sprintf(label2, "%s, jaccard >= %.2f", label1, args->minJaccard);
            if((contactGroupsBySeq = contactGroupBySequence(contacts, domToSeq, seqGroups, &idContactGroup)) == NULL) exit(1);

            if(args->minJaccard > 1.0) {
                for(i = 0; i < contactGroupsBySeq->n; i++) {
                    contactGroupBySeq = (LIST *) contactGroupsBySeq->all[i];
                    (*contactGroupOutput)(label1, contactGroupBySeq, 0, fh_contact_group, fh_contact_to_group);
                }
            }
            else {
                for(i = 0; i < contactGroupsBySeq->n; i++) {
                    contactGroupBySeq = (LIST *) contactGroupsBySeq->all[i];
                    (*contactGroupOutput)(label1, contactGroupBySeq, 0, fh_contact_group, fh_contact_to_group);

                    /*
                     * it isn't strictly necessary to subdivide a group that only has one member...
                     * ... but it's nice to have the contact in a jaccard group by itself too, to
                     * make subsequent querying easier.
                     */
                
                    if((contactGroupsByJacc = contactGroupByJaccards(contactGroupBySeq, domToSeq, args->minJaccard, hsps, &idContactGroup)) == NULL) exit(1);
                    for(j = 0; j < contactGroupsByJacc->n; j++) {
                        contactGroupByJacc = (LIST *) contactGroupsByJacc->all[j];
                        (*contactGroupOutput)(label2, contactGroupByJacc, contactGroupBySeq->id, fh_contact_group, fh_contact_to_group);
                    }
                    listDelete(contactGroupsByJacc, listDeleteList);
                }
            }

            listDelete(contactGroupsBySeq, listDeleteList);
        }
    }

    // cleanup
    if(hsps != NULL) hashDelete(hsps, hspsDelete);
    if(domToSeq != NULL) hashDeleteTsv(domToSeq);
    if(seqIds != NULL) listDelete(seqIds, NULL);
    if(seqGroups != NULL) listDelete(seqGroups, listDeleteList);
    if(contacts != NULL) listDelete(contacts, contactDelete);
    if(fh_contact_group != NULL) fclose(fh_contact_group);
    if(fh_contact_to_group != NULL) fclose(fh_contact_to_group);
    argsDelete(args);

    exit(0);
}
