#if !defined(CONTACTHIT_H)
#define CONTACTHIT_H

#include <stdio.h>
#include <stdlib.h>
#include "strings.h"
#include "hash.h"
#include "list.h"
#include "alignment.h"
#include "contact.h"

typedef struct contacthit {
    char           *type;
    char           *idSeqA1;
    char           *idSeqB1;
    char           *idSeqA2;
    char           *idSeqB2;
    CONTACT        *cA2B2;   // contact between A2 and B2 (A1 and B1 are the queries)
    HSP            *hspA1A2; // hsp between A1 and A2
    HSP            *hspB2B1; // hsp between B2 and B1
    unsigned short *rc; // residue contacts as 1d array of positions (cf. rcontact->rc)
    unsigned short *residues; // posA1, posB1, posA2, posB2 as 1d array (for output)
    unsigned short nResA1, nResB1, nResResA1B1;
    unsigned int   id;
    unsigned char  pcidA, pcidB;
    double         eValueA, eValueB; 
} CONTACTHIT;

CONTACTHIT *contactHitCreate(unsigned int idCh, char *idSeqA1, char *idSeqB1, char *idSeqA2, char *idSeqB2, CONTACT *cA2B2, HSP *hspA1A2, HSP *hspB2B1, HASH *domToChemType);
int contactHitResiduesCreate(CONTACTHIT *ch);
int contactHitResiduesDelete(void *thing);
int contactHitDelete(void *thing);
CONTACTHIT *contactHitParseSimple(char *idLine, char *cA2B2Line, char *hspA1A2Line, char *hspB2B1Line);
int contactHitResiduesOutput(CONTACTHIT *ch, FILE *fhContactHitResidue);
int contactHitOutput(CONTACTHIT *ch, FILE *fhContactHit, FILE *fhContactHitResidue);
int contactHitSortBest(const void *a, const void *b);

#endif
