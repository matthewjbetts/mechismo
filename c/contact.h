#if !defined(CONTACT_H)
#define CONTACT_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include "myFile.h"
#include "pdb.h"
#include "spatialPartition.h"
#include "sphere.h"
#include "list.h"
#include "maths.h"
#include "alignment.h"

#define MAXDIST 5.0 // atoms are considered not to be in contact if they are separated by more than this
#define MINOVERLAP MAXDIST * -1.0 // since overlaps are positive, threshold for separation should be negative (if two lines are 5.0 apart, their overlap is -5.0)
#define MAXDISTSQ 25.0
#define MINDIST 0.5 // atoms are considered to be clashing if they are separated by more than this
#define MINDISTSQ 0.25
#define IDLEN 11 // up to 10 characters in a 4byte unsigned int

// bit-masks for different bond types
#define UNKNOWN_BONDTYPE         0
#define MM                       1
#define MS                       2
#define SM                       4
#define SS                       8
#define MM_HBOND                16
#define MM_SALTBRIDGE           32
#define MS_HBOND                64
#define MS_SALTBRIDGE          128
#define SM_HBOND               256
#define SM_SALTBRIDGE          512
#define SS_HBOND              1024
#define SS_SALTBRIDGE         2048
#define SS_BUSINESSEND        4096
#define SS_UNMOD_HBOND        8192
#define SS_UNMOD_SALTBRIDGE  16384
#define SS_UNMOD_BUSINESSEND 32768

typedef struct resContact {
    unsigned short posA; // 1 + index of residue in domainA's list of residues, i.e. sequence position
    unsigned short posB;
    unsigned int   bondType;
    float          minD;
} RES_CONTACT;

typedef struct contact {
    char           *idDomA; // for when the whole DOMAIN_LOC structure has not been created
    char           *idDomB;
    unsigned short *rc;
    unsigned int   id;
    unsigned short nResA;
    DOMAIN_LOC     *domainA;
    DOMAIN_LOC     *domainB;
    LIST           *resContacts;
    unsigned short nResB;
    unsigned short nClash;
    unsigned short nResRes;
    unsigned char  crystal;
    unsigned char  homo;

    /*
     * rc = residue contacts as (1d) array of positions.
     *
     * rc[0]   = number of rows
     * rc[1]   = length of first row
     * rc[2]   = the position of residueA of domainA
     * rc[2..] = the positions of residues of domainB with which that residue is in contact
     * rc[..]  = length of second row
     * etc
     *
     * FIXME - write function to create this from resContacts
     */
} CONTACT;

typedef struct contactmin {
    char           *idDomA;
    char           *idDomB;
    unsigned short *rc;
    unsigned int   id;
    unsigned short nResA;
} CONTACTMIN;

RES_CONTACT *resContactCreate(unsigned short posA, unsigned short posB, unsigned int bondType, float minD);
int resContactDelete(void *thing);
int resContactOutput(CONTACT *c, RES_CONTACT *rc, FILE *fh);
RES_CONTACT *resContactReverse(RES_CONTACT *rc1);

CONTACT *contactCreate();
int contactDelete(void *thing);
int contactDeleteKVP(void *thing);
int contactDeleteHash(void *thing);
int contactOutput(CONTACT *c, FILE *fhContact, FILE *fhResContact);
CONTACT *contactReverse(CONTACT *c1);
float contactJaccard(CONTACT *c1, CONTACT *c2, HASH *domToSeq, HASH *hsps);
float contactJaccardFromAln(
                            CONTACT    *c1,
                            CONTACT    *c2,

                            unsigned int   alnLenA,

                            unsigned short seqLenA1,
                            unsigned short startA1,
                            short          *editsA1,
                            unsigned short nEditsA1,

                            unsigned short seqLenA2,
                            unsigned short startA2,
                            short          *editsA2,
                            unsigned short nEditsA2,

                            unsigned int   alnLenB,

                            unsigned short seqLenB1,
                            unsigned short startB1,
                            short          *editsB1,
                            unsigned short nEditsB1,

                            unsigned short seqLenB2,
                            unsigned short startB2,
                            short          *editsB2,
                            unsigned short nEditsB2
                            );
float contactJaccardFromHsps(CONTACT *c1, CONTACT *c2, HASH *domToSeq, HASH *hsps);

int atomContact(void *thing_a, void *thing_b, LIST *args);
int residueContact(void *thing_a, void *thing_b, LIST *args);
int domainContact(void *thing_a, void *thing_b, LIST *args);
int modelContact(void *thing_a, void *thing_b, LIST *args);
int contactSortByNResRes(const void *a, const void *b);
int contactSaveToList(void *thing, CONTACT *c);
int contactSaveToHash(void *thing, CONTACT *c);
CONTACT *contactParseLine(char *line);
int contactParse(char *fileName, void *contacts, int (*contactSave)(void *, CONTACT *), int noclash, unsigned short minResRes);
LIST *contactGroupBySequence(LIST *contacts, HASH *domToSeq, LIST *seqGroups, unsigned int *idGroup);
int contactsJaccards(LIST *group, HASH *domToSeq, float minJaccard, HASH *hsps);
LIST *contactGroupByJaccards(LIST *contacts, HASH *domToSeq, float minJaccard, HASH *hsps, unsigned int *idGroup);

#endif
