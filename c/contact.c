#include "contact.h"

#define SWAP(T, a, b) do { T tmp = a; a = b; b = tmp; } while (0)

unsigned int getBondType(char *resName1, char *atomName1, char *resName2, char *atomName2, float dSq) {
    int             i, j;
    unsigned int    bondType;
    //char            resNameOrig[2][4];
    char            resName[2][4];
    char            atomName[2][5];
    int             res_idx[2];
    int             atom_idx[2];
    int             unmod_res_idx[2];
    int             unmod_atom_idx[2];

    bondType = 0;
    if(dSq <= MAXDISTSQ) {
        /*
        strcpy(resNameOrig[0], resName1);
        strcpy(resNameOrig[1], resName2);
        */
        strcpy(resName[0], resName1);
        strcpy(resName[1], resName2);
        strcpy(atomName[0], atomName1);
        strcpy(atomName[1], atomName2);

        for(i = 0; i < 2; i++) {
            res_idx[i]        = -1;
            atom_idx[i]       = -1;
            unmod_res_idx[i]  = -1;
            unmod_atom_idx[i] = -1;

            for(j = 0; j < MAXSTANDARDRES; ++j) {
                if(strcmp(resName[i], standardRes[j].threeCode) == 0) {
                    res_idx[i] = j;
                    unmod_res_idx[i] = standardRes[j].idx_unmod;
                    break;
                }
            }

            if(res_idx[i] == -1) {
                if(strcmp(resName[i], "UNK\0") == 0) {
                    return UNKNOWN_BONDTYPE;
                }
                else {
                    //fprintf(stderr, "Warning: res type '%s' not found. Using 'UNK'.\n", resName[i]);
                    strcpy(resName[i], "UNK\0");
                    --i;
                    continue;
                }
            }
            else {
                for(j = 0; j < standardRes[res_idx[i]].atomCount; ++j) {
                    if(strcmp(atomName[i], standardRes[res_idx[i]].atomTypes[j]) == 0) {
                        atom_idx[i] = j;
                        break;
                    }
                }

                if(atom_idx[i] == -1) {
                    if(strcmp(atomName[i], "UNK\0") == 0) {
                        return UNKNOWN_BONDTYPE;
                    }
                    else {
                        //fprintf(stderr, "Warning: atom type '%s' for res type '%s' not found. Using 'UNK'.\n", atomName[i], resNameOrig[i]);
                        strcpy(atomName[i], "UNK\0");
                        --i;
                        continue;
                    }
                }

                if(unmod_res_idx[i] == res_idx[i]) {
                    unmod_atom_idx[i] = atom_idx[i];
                }
                else {
                    for(j = 0; j < standardRes[unmod_res_idx[i]].atomCount; ++j) {
                        if(strcmp(atomName[i], standardRes[unmod_res_idx[i]].atomTypes[j]) == 0) {
                            unmod_atom_idx[i] = j;
                            break;
                        }
                    }
                }
            }
        }

        if(standardRes[res_idx[0]].atomClasses[atom_idx[0]] & SIDECHAIN)
            if(standardRes[res_idx[1]].atomClasses[atom_idx[1]] & SIDECHAIN)
                bondType |= SS;
            else
                bondType |= SM;
        else if(standardRes[res_idx[1]].atomClasses[atom_idx[1]] & SIDECHAIN)
            bondType |= MS;
        else
            bondType |= MM;

        if(
           ((standardRes[res_idx[0]].atomClasses[atom_idx[0]] & HBOND_DONOR) && (standardRes[res_idx[1]].atomClasses[atom_idx[1]] & HBOND_ACCEPTOR))
           || ((standardRes[res_idx[0]].atomClasses[atom_idx[0]] & HBOND_ACCEPTOR) && (standardRes[res_idx[1]].atomClasses[atom_idx[1]] & HBOND_DONOR))
           ) {
            if((standardRes[res_idx[0]].atomClasses[atom_idx[0]] & SALT) && (standardRes[res_idx[1]].atomClasses[atom_idx[1]] & SALT)) {
                if(bondType & SS)
                    bondType |= SS_SALTBRIDGE;
                else if(bondType & SM)
                    bondType |= SM_SALTBRIDGE;
                else if(bondType & MS)
                    bondType |= MS_SALTBRIDGE;
                else if(bondType & MM)
                    bondType |= MM_SALTBRIDGE;
            }
            else {
                if(bondType & SS)
                    bondType |= SS_HBOND;
                else if(bondType & SM)
                    bondType |= SM_HBOND;
                else if(bondType & MS)
                    bondType |= MS_HBOND;
                else if(bondType & MM)
                    bondType |= MM_HBOND;
            }
        }            

        if((standardRes[res_idx[0]].atomClasses[atom_idx[0]] & RES_END) && (standardRes[res_idx[1]].atomClasses[atom_idx[1]] & RES_END)) {
            if(bondType & SS)
                bondType |= SS_BUSINESSEND;
        }

        if((unmod_res_idx[0] == res_idx[0]) && (unmod_res_idx[1] == res_idx[1])) {
            if(bondType & SS_HBOND)
                bondType |= SS_UNMOD_HBOND;

            if(bondType & SS_SALTBRIDGE)
                bondType |= SS_UNMOD_SALTBRIDGE;

            if(bondType & SS_BUSINESSEND)
                bondType |= SS_UNMOD_BUSINESSEND;
        }
        else if((unmod_atom_idx[0] != -1) && (unmod_atom_idx[1] != -1)) {
            if(
               ((standardRes[unmod_res_idx[0]].atomClasses[unmod_atom_idx[0]] & HBOND_DONOR) && (standardRes[unmod_res_idx[1]].atomClasses[unmod_atom_idx[1]] & HBOND_ACCEPTOR))
               || ((standardRes[unmod_res_idx[0]].atomClasses[unmod_atom_idx[0]] & HBOND_ACCEPTOR) && (standardRes[unmod_res_idx[1]].atomClasses[unmod_atom_idx[1]] & HBOND_DONOR))
               ) {
                if((standardRes[unmod_res_idx[0]].atomClasses[unmod_atom_idx[0]] & SALT) && (standardRes[unmod_res_idx[1]].atomClasses[unmod_atom_idx[1]] & SALT)) {
                    if(bondType & SS)
                        bondType |= SS_UNMOD_SALTBRIDGE;
                }
                else {
                    if(bondType & SS)
                        bondType |= SS_UNMOD_HBOND;
                }
            }            

            if((standardRes[unmod_res_idx[0]].atomClasses[unmod_atom_idx[0]] & RES_END) && (standardRes[unmod_res_idx[1]].atomClasses[unmod_atom_idx[1]] & RES_END)) {
                if(bondType & SS)
                    bondType |= SS_UNMOD_BUSINESSEND;
            }
        }

    }

    return bondType;
}

unsigned int reverseBondType(unsigned int bondType) {
    unsigned int pairs[16][2] = {
        {MM,                   MM},
        {MS,                   SM},
        {SM,                   MS},
        {SS,                   SS},
        {MM_HBOND,             MM_HBOND},
        {MM_SALTBRIDGE,        MM_SALTBRIDGE},
        {MS_HBOND,             SM_HBOND},
        {SM_HBOND,             MS_HBOND},
        {MS_SALTBRIDGE,        SM_SALTBRIDGE},
        {SM_SALTBRIDGE,        MS_SALTBRIDGE},
        {SS_HBOND,             SS_HBOND},
        {SS_SALTBRIDGE,        SS_SALTBRIDGE},
        {SS_BUSINESSEND,       SS_BUSINESSEND},
        {SS_UNMOD_HBOND,       SS_UNMOD_HBOND},
        {SS_UNMOD_SALTBRIDGE,  SS_UNMOD_SALTBRIDGE},
        {SS_UNMOD_BUSINESSEND, SS_UNMOD_BUSINESSEND}
    };
    int i;
    int reverse;

    reverse = 0;
    for(i = 0; i < 16; i++) {
        if(bondType & pairs[i][0])
            reverse |= pairs[i][1];
    }

    //printf("%5ld %5d\n", bondType, reverse);

    return reverse;
}

RES_CONTACT *resContactCreate(unsigned short posA, unsigned short posB, unsigned int bondType, float minD) {
    RES_CONTACT *rc;

    rc = (RES_CONTACT *) malloc(sizeof(RES_CONTACT));
    if(rc == NULL) {
        fprintf(stderr, "Error: resContactCreate: malloc failed.\n");
        return NULL;
    }
    rc->posA = posA;
    rc->posB = posB;
    rc->bondType = bondType;
    rc->minD = minD;

    return rc;
}

int resContactDelete(void *thing) {
    RES_CONTACT *rc;

    rc = (RES_CONTACT *) thing;
    free(rc);

    return 0;
}

int resContactOutput(CONTACT *c, RES_CONTACT *rc, FILE *fh) {
    RESIDUE *residueA;
    RESIDUE *residueB;

    residueA = (RESIDUE *) c->domainA->residues->all[rc->posA - 1];
    residueB = (RESIDUE *) c->domainB->residues->all[rc->posB - 1];

    fprintf(
            fh,
            "%u\t%u\t%c\t%d\t%c\t%c\t%d\t%c\n",
            c->id,            // 0
            rc->bondType,     // 1
            residueA->chain,  // 2
            residueA->resSeq, // 3
            residueA->iCode,  // 4
            residueB->chain,  // 5
            residueB->resSeq, // 6
            residueB->iCode   // 7
            );

    return 0;
}

CONTACT *contactCreate(DOMAIN_LOC *domainA, DOMAIN_LOC *domainB) {
    CONTACT *c;

    c = (CONTACT *) malloc(sizeof(CONTACT));
    if(c == NULL) {
        fprintf(stderr, "Error: contactCreate: malloc failed.\n");
        return NULL;
    }

    c->id = 0;

    if(domainA != NULL) {
        if((c->idDomA = (char *) malloc((strlen(domainA->id) + 1) * sizeof(char))) == NULL) {
            fprintf(stderr, "Error: contactCreate: malloc failed.\n");
            return NULL;
        }
        strcpy(c->idDomA, domainA->id);
        c->domainA = domainA;
    }
    else {
        c->idDomA  = NULL;
        c->domainA = NULL;
    }

    if(domainB != NULL) {
        if((c->idDomB = (char *) malloc((strlen(domainB->id) + 1) * sizeof(char))) == NULL) {
            fprintf(stderr, "Error: contactCreate: malloc failed.\n");
            return NULL;
        }
        strcpy(c->idDomB, domainB->id);
        c->domainB = domainB;
    }
    else {
        c->idDomB  = NULL;
        c->domainB = NULL;
    }

    c->crystal     = 0;
    c->nResA       = 0;
    c->nResB       = 0;
    c->nClash      = 0;
    c->nResRes     = 0;
    c->homo        = 0;
    c->resContacts = listCreate(NULL);
    c->rc          = NULL;
    c->type        = NULL;

    return c;
}

int contactDelete(void *thing) {
    CONTACT      *c;

    c = (CONTACT *) thing;
    if(c->idDomA != NULL)
        free(c->idDomA);
    if(c->idDomB != NULL)
        free(c->idDomB);
    if(c->type != NULL)
        free(c->type);
    listDelete(c->resContacts, resContactDelete);
    if(c->rc != NULL) {
        free(c->rc);
    }
    free(c);

    return 0;
}

int contactDeleteKVP(void *thing) {
    KEYVALUEPAIR *kvp;

    kvp = (KEYVALUEPAIR *) thing;
    free(kvp->key);
    contactDelete(kvp->value);
    free(kvp);

    return 0;
}

int contactDeleteHash(void *thing) {
    KEYVALUEPAIR *kvp;

    kvp = (KEYVALUEPAIR *) thing;
    free(kvp->key);
    hashDelete(kvp->value, contactDeleteKVP);
    free(kvp);

    return 0;
}

int contactOutput(CONTACT *c, FILE *fhContact, FILE *fhResContact) {
    int         i;
    RES_CONTACT *rc;

    if(fhContact != NULL) {
        fprintf(
                fhContact,
                "%u\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\n",
                c->id,
                c->idDomA, // domain ids should be integers for Mechismo but might not be for other uses
                c->idDomB,
                c->crystal,
                c->nResA,
                c->nResB,
                c->nClash,
                c->nResRes,
                0 // FIXME - homo
                );
    }

    if(fhResContact != NULL) {
        for(i = 0; i < c->resContacts->n; i++) {
            rc = (RES_CONTACT *) c->resContacts->all[i];
            resContactOutput(c, rc, fhResContact);
        }
    }

    return 0;
}

RES_CONTACT *resContactReverse(RES_CONTACT *rc1) {
    RES_CONTACT *rc2;

    rc2 = resContactCreate(rc1->posB, rc1->posA, reverseBondType(rc1->bondType), rc1->minD);

    return rc2;
}

CONTACT *contactReverse(CONTACT *c1) {
    CONTACT     *c2;
    int         i;
    RES_CONTACT *rc1;
    RES_CONTACT *rc2;

    c2 = contactCreate(c1->domainB, c1->domainA);
    c2->crystal = c1->crystal;
    c2->nResA = c1->nResB;
    c2->nResB = c1->nResA;
    c2->nClash = c1->nClash;
    c2->nResRes = c1->nResRes;

    for(i = 0; i < c1->resContacts->n; i++) {
        rc1 = (RES_CONTACT *) c1->resContacts->all[i];
        rc2 = resContactReverse(rc1);
        listAddElement(c2->resContacts, 1, rc2);
    }

    return c2;
}

float contactJaccard(CONTACT *c1, CONTACT *c2, HASH *domToSeq, HASH *hsps) { // domToSeq and Hsps not used here, only specified to provide uniform interface
    unsigned int   nIntersection, nUnion;
    float          jaccard;
    unsigned short tPosA1, tPosA2; // total number of A1 positions
    unsigned short nPosA1, nPosA2; // running count of A1 positions
    unsigned int   idx1, idx1Start, idx1End, idx2, idx2Start, idx2End;
    unsigned short posA1, posA2, posB1, posB2;

    if(c1->rc == NULL) {
        fprintf(stderr, "Error: contactJaccard: rc not defined for contact %d.\n", c1->id);
        return -1.0;
    }

    if(c2->rc == NULL) {
        fprintf(stderr, "Error: contactJaccard: rc not defined for contact %d.\n", c2->id);
        return -1.0;
    }

    /*
     * quickest to loop through the smallest contact first,
     * but better for big sets to decide this outside this
     * function rather than checking every pair individually
     */
    //if(c1->nResRes > c2->nResRes) SWAP(CONTACT *, c1, c2);

    nIntersection = 0;
    tPosA1 = c1->rc[0];
    tPosA2 = c2->rc[0];
    nPosA1 = 0;
    idx1End = 0;
    while(nPosA1 < tPosA1) {
        ++nPosA1;
        idx1Start = idx1End + 2;
        idx1End += (c1->rc[idx1End + 1] + 1);
        posA1 = c1->rc[idx1Start++];
        nPosA2 = 0;
        idx2End = 0;
        while(nPosA2 < tPosA2) {
            nPosA2++;
            idx2Start = idx2End + 2;
            idx2End += (c2->rc[idx2End + 1] + 1);
            posA2 = c2->rc[idx2Start++];
            if(posA2 == posA1) {
                for(idx1 = idx1Start; idx1 <= idx1End; idx1++) {
                    posB1 = c1->rc[idx1];
                    for(idx2 = idx2Start; idx2 <= idx2End; idx2++) {
                        posB2 = c2->rc[idx2];
                        if(posB2 == posB1) {
                            ++nIntersection;
                            break; // move on to next posB1;
                        }
                    }
                }
            }
        }
    }
    nUnion = c1->nResRes + c2->nResRes - nIntersection;
    jaccard = (float) nIntersection / nUnion;
    //printf("c1->nResRes = %d, c2->nResRes = %d, intersection = %d, jaccard = %f\n", c1->nResRes, c2->nResRes, nIntersection, jaccard);

    return jaccard;
}

float contactJaccardFromAln(
                            CONTACT        *c1,
                            CONTACT        *c2,

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
                            ) {
    unsigned short tPosA1, tPosA2; // total number of A1 positions
    unsigned short nPosA1, nPosA2; // running count of A1 positions
    unsigned int   idx1, idx1Start, idx1End, idx2, idx2Start, idx2End;
    unsigned short posA1, posA2, posB1, posB2;
    unsigned short aposA1, aposA2, aposB1, aposB2;
    unsigned short nIntersection, nUnion;
    float          jaccard;
    unsigned short **mappingA1, **mappingA2, **mappingB1, **mappingB2;
    unsigned short (*mapFuncA1)(unsigned short **mapping, unsigned short idx, unsigned short pos);
    unsigned short (*mapFuncA2)(unsigned short **mapping, unsigned short idx, unsigned short pos);
    unsigned short (*mapFuncB1)(unsigned short **mapping, unsigned short idx, unsigned short pos);
    unsigned short (*mapFuncB2)(unsigned short **mapping, unsigned short idx, unsigned short pos);

    if(c1->rc == NULL) {
        fprintf(stderr, "Error: contactJaccardFromAln: rc not defined for contact %d.\n", c1->id);
        return -1.0;
    }

    if(c2->rc == NULL) {
        fprintf(stderr, "Error: contactJaccardFromAln: rc not defined for contact %d.\n", c2->id);
        return -1.0;
    }

    /*
     * quickest to loop through the smallest contact first,
     * but better for big sets to decide this outside this
     * function rather than checking every pair individually
     */
    /*
    if(c1->nResRes > c2->nResRes) {
        SWAP(CONTACT *, c1, c2);

        SWAP(unsigned short, seqLenA1, seqLenA2);
        SWAP(unsigned short, startA1,  startA2);
        SWAP(short *       , editsA1,  editsA2);
        SWAP(unsigned short, nEditsA1, nEditsA2);

        SWAP(unsigned short, seqLenB1, seqLenB2);
        SWAP(unsigned short, startB1,  startB2);
        SWAP(short *       , editsB1,  editsB2);
        SWAP(unsigned short, nEditsB1, nEditsB2);
    }
    */

    if(alnLenA == 0) {
        mappingA1 = NULL;
        mapFuncA1 = &posPassThrough;
        mappingA2 = NULL;
        mapFuncA2 = &posPassThrough;
    }
    else {
        if((mappingA1 = alignedSeqPosMapping(seqLenA1, startA1, editsA1, nEditsA1, alnLenA)) == NULL) return -1.0;
        mapFuncA1 = &posFromMapping;
        if((mappingA2 = alignedSeqPosMapping(seqLenA2, startA2, editsA2, nEditsA2, alnLenA)) == NULL) return -1.0;
        mapFuncA2 = &posFromMapping;
    }

    if(alnLenB == 0) {
        mappingB1 = NULL;
        mapFuncB1 = &posPassThrough;
        mappingB2 = NULL;
        mapFuncB2 = &posPassThrough;
    }
    else {
        if((mappingB1 = alignedSeqPosMapping(seqLenB1, startB1, editsB1, nEditsB1, alnLenB)) == NULL) return -1.0;
        mapFuncB1 = &posFromMapping;
        if((mappingB2 = alignedSeqPosMapping(seqLenB2, startB2, editsB2, nEditsB2, alnLenB)) == NULL) return -1.0;
        mapFuncB2 = &posFromMapping;
    }

    nIntersection = 0;
    tPosA1 = c1->rc[0];
    tPosA2 = c2->rc[0];
    nPosA1 = 0;
    idx1End = 0;
    while(nPosA1 < tPosA1) {
        ++nPosA1;
        idx1Start = idx1End + 2;
        idx1End += (c1->rc[idx1End + 1] + 1);
        posA1 = c1->rc[idx1Start++];
        nPosA2 = 0;
        idx2End = 0;
        if((aposA1 = (*mapFuncA1)(mappingA1, 0, posA1)) == 0) continue;
        while(nPosA2 < tPosA2) {
            nPosA2++;
            idx2Start = idx2End + 2;
            idx2End += (c2->rc[idx2End + 1] + 1);
            posA2 = c2->rc[idx2Start++];
            if((aposA2 = (*mapFuncA2)(mappingA2, 0, posA2)) == 0) continue;
            if(aposA2 == aposA1) {
                for(idx1 = idx1Start; idx1 <= idx1End; idx1++) {
                    posB1 = c1->rc[idx1];
                    if((aposB1 = (*mapFuncB1)(mappingB1, 0, posB1)) == 0) continue;
                    for(idx2 = idx2Start; idx2 <= idx2End; idx2++) {
                        posB2 = c2->rc[idx2];
                        if((aposB2 = (*mapFuncB2)(mappingB2, 0, posB2)) == 0) continue;
                        if(aposB2 == aposB1) {
                            ++nIntersection;
                            break; // move on to next posB1;
                        }
                    }
                }
            }
        }
    }
    nUnion = c1->nResRes + c2->nResRes - nIntersection;
    jaccard = (float) nIntersection / nUnion;
    //printf("c1->nResRes = %d, c2->nResRes = %d, intersection = %d, jaccard = %f\n", c1->nResRes, c2->nResRes, nIntersection, jaccard);

    if(mappingA1 != NULL) {
        free(mappingA1[0]);
        free(mappingA1[1]);
        free(mappingA1);
    }

    if(mappingA2 != NULL) {
        free(mappingA2[0]);
        free(mappingA2[1]);
        free(mappingA2);
    }

    if(mappingB1 != NULL) {
        free(mappingB1[0]);
        free(mappingB1[1]);
        free(mappingB1);
    }

    if(mappingB2 != NULL) {
        free(mappingB2[0]);
        free(mappingB2[1]);
        free(mappingB2);
    }

    return jaccard;
}

float contactJaccardFromHsps(CONTACT *c1, CONTACT *c2, HASH *domToSeq, HASH *hsps) {
    float          jaccard;

    char           *idSeqA1, *idSeqB1, *idSeqA2, *idSeqB2;
    LIST           *hsps12;
    HSP            *hspA, *hspB;
    
    unsigned int   alnLenA;

    unsigned short seqLenA1;
    unsigned short startA1;
    short          *editsA1;
    unsigned short nEditsA1;

    unsigned short seqLenA2;
    unsigned short startA2;
    short          *editsA2;
    unsigned short nEditsA2;

    unsigned int   alnLenB;

    unsigned short seqLenB1;
    unsigned short startB1;
    short          *editsB1;
    unsigned short nEditsB1;

    unsigned short seqLenB2;
    unsigned short startB2;
    short          *editsB2;
    unsigned short nEditsB2;

    /*
     * if any of the domains don't have a sequence, assume that jaccard = 0.0.
     * this can happen for non-peptide and non-nucleotide domains, i.e. small molecules
     *
     * FIXME - introduce similarity measure for small molecules, and a way
     * to map between equivalent parts (cf. alignments for sequences)
     */

    if((idSeqA1 = (char *) hashGetElement(domToSeq, c1->idDomA)) == NULL) return 0.0;
    if((idSeqB1 = (char *) hashGetElement(domToSeq, c1->idDomB)) == NULL) return 0.0;
    if((idSeqA2 = (char *) hashGetElement(domToSeq, c2->idDomA)) == NULL) return 0.0;
    if((idSeqB2 = (char *) hashGetElement(domToSeq, c2->idDomB)) == NULL) return 0.0;
                
    if(strcmp(idSeqA2, idSeqA1) == 0) {
        alnLenA  = 0;

        seqLenA1 = 0;
        startA1  = 0;
        editsA1  = NULL;
        nEditsA1 = 0;

        seqLenA2 = 0;
        startA2  = 0;
        editsA2  = NULL;
        nEditsA2 = 0;
    }
    else {
        if((hsps12 = (LIST *) hash2DGetElement(hsps, idSeqA1, idSeqA2)) == NULL) return 0;
        hspA = hsps12->all[0];

        alnLenA  = hspA->len;

        seqLenA1 = hspA->seqLen1;
        startA1  = hspA->start1;
        editsA1  = hspA->edits;
        nEditsA1 = hspA->nEdits1;

        seqLenA2 = hspA->seqLen2;
        startA2  = hspA->start2;
        editsA2  = hspA->edits + hspA->nEdits1;
        nEditsA2 = hspA->nEdits2;
    }

    if(strcmp(idSeqB2, idSeqB1) == 0) {
        alnLenB  = 0;

        seqLenB1 = 0;
        startB1  = 0;
        editsB1  = NULL;
        nEditsB1 = 0;

        seqLenB2 = 0;
        startB2  = 0;
        editsB2  = NULL;
        nEditsB2 = 0;
    }
    else {
        if((hsps12 = (LIST *) hash2DGetElement(hsps, idSeqB1, idSeqB2)) == NULL) return 0;
        hspB = hsps12->all[0];

        alnLenB  = hspB->len;

        seqLenB1 = hspB->seqLen1;
        startB1  = hspB->start1;
        editsB1  = hspB->edits;
        nEditsB1 = hspB->nEdits1;

        seqLenB2 = hspB->seqLen2;
        startB2  = hspB->start2;
        editsB2  = hspB->edits + hspB->nEdits1;
        nEditsB2 = hspB->nEdits2;
    }

    jaccard = contactJaccardFromAln(
                                    c1,
                                    c2,
                                    alnLenA,

                                    seqLenA1,
                                    startA1,
                                    editsA1,
                                    nEditsA1,

                                    seqLenA2,
                                    startA2,
                                    editsA2,
                                    nEditsA2,

                                    alnLenB,

                                    seqLenB1,
                                    startB1,
                                    editsB1,
                                    nEditsB1,

                                    seqLenB2,
                                    startB2,
                                    editsB2,
                                    nEditsB2
                                    );
        
    return jaccard;
}

int crystalContact(DOMAINS_TO_FRAGS *ds2fs, char idA[DOMIDLEN], char idB[DOMIDLEN]) {
    int            i, j;
    DOMAIN_TO_FRAG *d2f;
    int            id_fragA, id_fragB;
    int            *common;
    int            crystal;

    if(ds2fs == NULL)
        return 0;

    common = (int *) malloc(ds2fs->n_assemblies * sizeof(int));
    if(common == NULL) {
        fprintf(stderr, "Error: crystalContact: malloc failed.\n");
        return -1;
    }
    for(i = 0; i < ds2fs->n_assemblies; ++i) {
        common[i] = 0;
    }

    // find the fragment of which idA is an instance
    id_fragA = -1;
    for(i = 0; i < ds2fs->n; i++) {
        d2f = ds2fs->all[i];
        if(strcmp(d2f->id_domain, idA) == 0) {
            id_fragA = d2f->id_frag;
            break;
        }
    }

    // find the fragment of which idB is an instance
    id_fragB = -1;
    for(i = 0; i < ds2fs->n; i++) {
        d2f = ds2fs->all[i];
        if(strcmp(d2f->id_domain, idB) == 0) {
            id_fragB = d2f->id_frag;
            break;
        }
    }

    // find all assemblies in which id_fragA has instances
    for(i = 0; i < ds2fs->n_frags; i++) {
        if(id_fragA == ds2fs->frags_to_assemblies[i][0]) {
            for(j = 1; j <= ds2fs->n_assemblies; ++j) {
                if(ds2fs->frags_to_assemblies[i][j] > 0)
                    common[j - 1]++;
            }
            break;
        }
    }

    // find all assemblies in which id_fragB has instances
    for(i = 0; i < ds2fs->n_frags; i++) {
        if(id_fragB == ds2fs->frags_to_assemblies[i][0]) {
            for(j = 1; j <= ds2fs->n_assemblies; ++j) {
                if(ds2fs->frags_to_assemblies[i][j] > 0)
                    common[j - 1]++;
            }
            break;
        }
    }

    // contacts between fragments that only have instances together in the original PDB (assembly 0) are crystal artefacts
    crystal = 0;
    if(common[0] > 1) {
        crystal = 1;

        for(i = 1; i < ds2fs->n_assemblies; ++i) {
            if(common[i] > 1) {
                crystal = 0;
                break;
            }
        }
    }

    free(common);

    return crystal;
}

int atomContact(void *thingA, void *thingB, LIST *args) {
    ATOM         *atomA;
    ATOM         *atomB;
    RESIDUE      *residueA;
    RESIDUE      *residueB;
    unsigned int *bondType;
    float        *minDSq;
    unsigned int bondType0;
    float        dSq;

    atomA = (ATOM *) thingA;
    atomB = (ATOM *) thingB;

    // get extra arguments
    residueA = (RESIDUE *) args->all[0];
    residueB = (RESIDUE *) args->all[1];
    bondType = (unsigned int *) args->all[2];
    minDSq    = (float *) args->all[3];

    dSq = distanceSquared(atomA->sphere.centre, atomB->sphere.centre);
    /*
    printf(
           "atomContact\t'%c%d%c' %s <-> '%c%d%c' %s \t[%08.3f, %08.3f, %08.3f]\t[%08.3f, %08.3f, %08.3f]\t%08.3f\t%08.3f\n",
           residueA->chain,
           residueA->resSeq,
           residueA->iCode,
           atomA->name,
           residueB->chain,
           residueB->resSeq,
           residueB->iCode,
           atomB->name,
           atomA->sphere.centre[0],
           atomA->sphere.centre[1],
           atomA->sphere.centre[2],
           atomB->sphere.centre[0],
           atomB->sphere.centre[1],
           atomB->sphere.centre[2],
           dSq,
           MAXDISTSQ
           );
    */
    if(dSq <= MAXDISTSQ) {
        bondType0 = getBondType(residueA->resName, atomA->name, residueB->resName, atomB->name, dSq);
        (*bondType) |= bondType0; 
    }

    if(dSq < *minDSq)
        *minDSq = dSq;

    return 0;
}

int residueContact(void *thingA, void *thingB, LIST *args) {
    RESIDUE           *residueA;
    RESIDUE           *residueB;
    int               *intra;
    int               *bothDirections;
    int               is_intra;
    CONTACT           *c;
    float             *minD_domain;
    int               *res_a_count;
    int               *res_b_count;
    float             minD;
    float             minDSq;
    unsigned int      bondType; // bond type(s) for a particular pair of residues
    LIST              *atomContactArgs;
    RES_CONTACT       *rc;
    RES_CONTACT       *rc2;

    residueA = (RESIDUE *) thingA;
    residueB = (RESIDUE *) thingB;

    // get extra arguments
    c              = (CONTACT *) args->all[0];
    intra          = (int *) args->all[1];
    bothDirections = (int *) args->all[2];
    is_intra       = *((int *) args->all[3]);
    res_a_count    = (int *) args->all[4];
    res_b_count    = (int *) args->all[5];
    minD_domain    = (float *) args->all[6];

    minD = distance(residueA->sphere.centre, residueB->sphere.centre) - residueA->sphere.r - residueB->sphere.r;
    //printf("residueContact(%s, %s, %c%d%c, %c%d%c) %f\n", c->domainA->id, c->domainB->id, residueA->chain, residueA->resSeq, residueA->iCode, residueB->chain, residueB->resSeq, residueB->iCode, minD);
    if(minD <= MAXDIST) {
        if(cubeOverlap(residueA->minCoord, residueA ->maxCoord, residueB->minCoord, residueB->maxCoord, MINOVERLAP) == 0) {
            /*
             * minD between two residue spheres might be less than minD between
             * any two atoms of those two residues, so need to reset minD
             */
            minDSq = 1000000.0;
            bondType = 0;

            if(residueA->grid == NULL) {
                residueA->grid = spatialPartitionCreate(residueA->atoms, atomSphere, MAXDIST, MAXDIST, residueA->minCoord, residueA->maxCoord);
                if(residueA->grid == NULL)
                    return 1;
                //spatialPartitionOutput(residueA->grid, "ATOMS_A", NULL);
            }

            if(residueB->grid == NULL) {
                residueB->grid = spatialPartitionCreate(residueB->atoms, atomSphere, MAXDIST, MAXDIST, residueB->minCoord, residueB->maxCoord);
                if(residueB->grid == NULL)
                    return 1;
                //spatialPartitionOutput(residueB->grid, "ATOMS_B", NULL);
            }

            atomContactArgs = listCreate("args");
            listAddElement(atomContactArgs, 4, residueA, residueB, &bondType, &minDSq);
            spatialPartitionFindContacts(residueA->grid, residueB->grid, atomContact, atomContactArgs);
            listDelete(atomContactArgs, NULL);

            minD = sqrt(minDSq); // saves doing sqrt for every pair of atoms
            if(minD < *minD_domain)
                *minD_domain = minD;

            if(minD <= MAXDIST) {
                rc = resContactCreate(residueA->pos, residueB->pos, bondType, minD);
                listAddElement(c->resContacts, 1, rc);
                c->nResRes++;

                res_a_count[residueA->pos - 1]++;
                res_b_count[residueB->pos - 1]++;
                if(is_intra == 1) {
                    rc2 = resContactReverse(rc);
                    listAddElement(c->resContacts, 1, rc2);
                    //c->nResRes++; // list it twice, once in each direction, but don't count twice
                    res_a_count[residueB->pos - 1]++;
                    res_b_count[residueA->pos - 1]++;
                }

                if(minD < MINDIST)
                    c->nClash++;
            }
        }
    }

    return 0;
}

int domainContact(void *thingA, void *thingB, LIST *args) {
    DOMAIN_LOC        *domainA;
    DOMAIN_LOC        *domainB;
    int               i, j;
    RESIDUE           *residueA, *residueB;
    float             d_domain; // = distance between centres - sum of radii
    float             minD; // min distance between any pair of residues
    int               *intra;
    int               *bothDirections;
    int               *res_a_count; // for counting residues-in-contact uniquely
    int               *res_b_count;
    int               is_intra;
    DOMAINS_TO_FRAGS  *ds2fs;
    int               calc_contact;
    LIST              *residueContactArgs;
    int               *id_contact;
    FILE              *fhContact;
    FILE              *fhResContact;
    SPATIAL_PARTITION *grid_a;
    SPATIAL_PARTITION *grid_b;
    float             rMaxAllResidues;
    CONTACT           *c1;
    CONTACT           *c2;

    domainA = (DOMAIN_LOC *) thingA;
    domainB = (DOMAIN_LOC *) thingB;

    // get extra arguments
    intra           = (int *)              args->all[0];
    bothDirections  = (int *)              args->all[1];
    id_contact      = (int *)              args->all[2];
    ds2fs           = (DOMAINS_TO_FRAGS *) args->all[3];
    fhContact       = (FILE *)             args->all[4];
    fhResContact    = (FILE *)             args->all[5];
    rMaxAllResidues = *((float *)          args->all[6]);

    if(domainB == NULL) {
        // calculate intra-domain contacts
        is_intra = 1;
        domainB = domainA;
        d_domain = 0;
    }
    else if(!strcmp(domainA->id, domainB->id)) {
        // calculate intra-domain contacts
        is_intra = 1;
        d_domain = 0;
    }
    else {
        // only need to calculate intra-model contacts if the domains are from the original pdb (assembly 0)
        if((domainA->assembly != NULL) && (domainA->assembly->id != 0) && (domainB->model->id == domainA->model->id))
            return 0;

        is_intra = 0;
        d_domain = distance(domainA->sphere.centre, domainB->sphere.centre) - domainA->sphere.r - domainB->sphere.r;
    }
    //printf("domainContact(%s, %s), d_domain = %f\n", domainA->id, domainB->id, d_domain);

    // only need to calculate intra-domain contacts if the domain is from the original pdb (assembly 0)
    if((is_intra == 1) && ((*intra == 0) || ((domainA->assembly != NULL) && domainA->assembly->id != 0)))
        return 0;
    
    if(d_domain <= MAXDIST) {
        if(cubeOverlap(domainA->minCoord, domainA->maxCoord, domainB->minCoord, domainB->maxCoord, MINOVERLAP) == 0) {
            minD = 99999999.0;

            res_a_count = (int *) malloc(domainA->residues->n * sizeof(int));
            for(i = 0; i < domainA->residues->n; ++i)
                res_a_count[i] = 0;
    
            res_b_count = (int *) malloc(domainB->residues->n * sizeof(int));
            for(j = 0; j < domainB->residues->n; ++j)
                res_b_count[j] = 0;

            // don't calculate contacts if the domains have any residues in common
            calc_contact = 1;
            if(is_intra == 0) {
                if(!strcmp(domainA->filename, domainB->filename)) {
                    for(i = 0; i < domainA->residues->n; ++i) {
                        residueA = domainA->residues->all[i];
                        for(j = 0; j < domainB->residues->n; ++j) {
                            residueB = domainB->residues->all[j];
                            if((residueB->chain == residueA->chain) && (residueB->resSeq == residueA->resSeq) && (residueB->iCode == residueA->iCode)) {
                                /*
                                printf(
                                       "ignoring %s ('%c%d%c') %s ('%c%d%c')\n",
                                       domainA->id,
                                       residueA->chain,
                                       residueA->resSeq,
                                       residueA->iCode,
                                       domainB->id,
                                       residueB->chain,
                                       residueB->resSeq,
                                       residueB->iCode
                                       ); 
                                */
                                calc_contact = 0;
                                break;
                            }
                        }
                        if(calc_contact == 0)
                            break;
                    }
                }
            }

            if(calc_contact == 1) {
                /*
                 * Store the residues spatially in 3D bins of size = max_rmax.
                 * Then only need to check for contacts between all pairs of
                 * fragments in the same bin and in the eight adjacent bins.
                 */

                if(domainA->grid == NULL) {
                    domainA->grid = spatialPartitionCreate(domainA->residues, residueSphere, MAXDIST, rMaxAllResidues, domainA->minCoord, domainA->maxCoord);
                    if(domainA->grid == NULL)
                        return 1;
                    //spatialPartitionOutput(domainA->grid, "RESIDUES_A", residueOutput);
                }
                grid_a = domainA->grid;

                if(is_intra == 1) {
                    grid_b = NULL;
                }
                else {
                    if(domainB->grid == NULL) {
                        domainB->grid = spatialPartitionCreate(domainB->residues, residueSphere, MAXDIST, rMaxAllResidues, domainB->minCoord, domainB->maxCoord);
                        if(domainB->grid == NULL)
                            return 1;
                        //spatialPartitionOutput(domainB->grid, "RESIDUES_B", residueOutput);
                    }
                    grid_b = domainB->grid;
                }

                c1 = contactCreate(domainA, domainB);
                residueContactArgs = listCreate("args");
                listAddElement(residueContactArgs, 7, c1, intra, bothDirections, &is_intra, res_a_count, res_b_count, &minD);
                spatialPartitionFindContacts(grid_a, grid_b, residueContact, residueContactArgs);
                listDelete(residueContactArgs, NULL);

                if(minD <= MAXDIST) {
                    c1->id = ++(*id_contact);

                    for(i = 0; i < domainA->residues->n; ++i)
                        if(res_a_count[i] > 0)
                            c1->nResA++;

                    for(j = 0; j < domainB->residues->n; ++j)
                        if(res_b_count[j] > 0)
                            c1->nResB++;
    
                    c1->crystal = (is_intra == 0) ? crystalContact(ds2fs, domainA->id, domainB->id) : 0;
                    contactOutput(c1, fhContact, fhResContact);

                    if((is_intra == 0) && (*bothDirections == 1)) {
                        c2 = contactReverse(c1);
                        c2->id = ++(*id_contact);
                        contactOutput(c2, fhContact, fhResContact);
                        contactDelete(c2);
                    }
                }
                contactDelete(c1);
            }
            free(res_a_count);
            free(res_b_count);
        }
    }

    return 0;
}

int modelContact(void *thingA, void *thingB, LIST *args) {
    MODEL    *modelA;
    MODEL    *modelB;
    ASSEMBLY *assembly;
    float    dCentre;
    float    d;
    float    rMaxAllDomains;

    modelA = (MODEL *) thingA;
    modelB = (MODEL *) thingB;
    assembly = modelA->assembly;

    // get extra arguments
    rMaxAllDomains = *((float *) args->all[7]);

    /*
     * intra-model contacts are the same as in assembly zero
     * (the original pdb), so only calculate inter-model contacts
     */
    dCentre = distance(modelA->sphere.centre, modelB->sphere.centre);
    d = dCentre - modelA->sphere.r - modelB->sphere.r;
    //printf("MODEL_CONTACT\t%d\t%d\t%d\t%f\n", modelA->assembly->id, modelA->id, modelB->id, d);
    //printf("rMaxAllDomains = %f\n", rMaxAllDomains);
    
    if(d <= MAXDIST) {
        if(cubeOverlap(modelA->minCoord, modelA->maxCoord, modelB->minCoord, modelB->maxCoord, MINOVERLAP) == 0) {
            d = 99999999.0;
            if(modelA->grid == NULL) {
                modelA->grid = spatialPartitionCreate(modelA->domains, domainSphere, MAXDIST, rMaxAllDomains, modelA->minCoord, modelA->maxCoord);
                if(modelA->grid == NULL)
                    return 1;
                //spatialPartitionOutput(modelA->grid, "MODELA", domainOutput);
            }

            if(modelB->grid == NULL) {
                modelB->grid = spatialPartitionCreate(modelB->domains, domainSphere, MAXDIST, rMaxAllDomains, modelB->minCoord, modelB->maxCoord);
                if(modelB->grid == NULL)
                    return 1;
                //spatialPartitionOutput(modelB->grid, "MODELB", domainOutput);
            }

            spatialPartitionFindContacts(modelA->grid, modelB->grid, domainContact, args);
        }
    }

    return 0;
}

int contactSortByNResRes(const void *a, const void *b) {
    const CONTACT *ca = *(const CONTACT **) a;
    const CONTACT *cb = *(const CONTACT **) b;

    if(ca->nResRes < cb->nResRes) {
        return -1;
    }
    else if(ca->nResRes > cb->nResRes) {
        return 1;
    }

    return 0;
}

int contactSaveToList(void *thing, CONTACT *c) {
    LIST *contacts;

    contacts = (LIST *) thing;
    listAddElement(contacts, 1, c);

    return 0;
}

int contactSaveToHash(void *thing, CONTACT *c) {
    HASH *contacts;

    contacts = (HASH *) thing;
    hash2DAddElement(contacts, c->idDomA, c->idDomB, c);

    return 0;
}

CONTACT *contactParseLine(char *line) {
    LIST           *tokens;
    unsigned int   idContact;
    int            i, j, k;
    unsigned char  crystal;
    unsigned short nResA, nResB, nResRes, nClash, nResCheck, nResResCheck, idxResA;
    char           **type;
    CONTACT        *c;
    LIST           *posStringsAll, *posStrings; // sequence positions as strings
    int            rcLength;

    c = NULL;
    if((tokens = stringSplit(line, "\t", NULL)) != NULL) {
        /*
         * 00   - idContact
         * 01   - idDomA
         * 02   - idDomB
         * 03   - crystal
         * 04   - nResA
         * 05   - nResB
         * 06   - nClash
         * 07   - nResRes
         # 08   - type
         * 09.. - pos1:pos2a,pos2b,...
         */
        idContact = (unsigned int) strtoul(tokens->all[0], NULL, 0);
        crystal   = (unsigned char)  strtoul(tokens->all[3], NULL, 0);
        nResA     = (unsigned short) strtoul(tokens->all[4], NULL, 0);
        nResB     = (unsigned short) strtoul(tokens->all[5], NULL, 0);
        nClash    = (unsigned short) strtoul(tokens->all[6], NULL, 0);
        nResRes   = (unsigned short) strtoul(tokens->all[7], NULL, 0);

        nResCheck = tokens->n - 9; // '9' for columns 0..8
        if(nResCheck != nResA) {
            fprintf(stderr, "Warning: contactParseLine: nResA found for contact %d != given nResA (%d != %d).\n", idContact, nResCheck, nResA);
            nResA = nResCheck;
        }

        if(nResA > 0) {
            //printf("%09d: %d\t%s\t%s\t%d\n", n, idContact, idDomA, idDomB, nResA);
            nResResCheck = 0;
            if((c = contactCreate(NULL, NULL)) != NULL) {
                c->idDomA = stringCopy(tokens->all[1]);
                c->idDomB = stringCopy(tokens->all[2]);
                c->id = idContact;
                c->crystal = crystal;
                c->nResA = nResA;
                c->nResB = nResB;
                c->nClash = nClash;
                c->nResRes = nResRes;
                c->type = stringCopy(tokens->all[8]);
                if((posStringsAll = listCreate(NULL)) == NULL)
                    return NULL;

                rcLength = 1;
                /*
                 * rc[0]   = number of rows
                 * rc[1]   = length of first row
                 * rc[2..] = positions
                 * rc[..]  = length of second row
                 * etc
                 */
                for(i = 8, idxResA = 0; i < tokens->n; i++, idxResA++) {
                    if((posStrings = stringSplit(tokens->all[i], ",", NULL)) == NULL)
                        continue;
                    listAddElement(posStringsAll, 1, posStrings);
                    rcLength += (posStrings->n + 1); // number of positions + one element for each position
                    nResResCheck += (posStrings->n - 1); // first element is posA1, subsequent elements are posB2, so number of pairs = posStrings->n - 1
                }

                if((c->rc = (unsigned short *) malloc(rcLength * sizeof(unsigned short))) == NULL) {
                    fprintf(stderr, "Error: contactParseLine: malloc failed for c->rc.\n");
                    return NULL;
                }

                i = 0;
                c->rc[i++] = posStringsAll->n;
                for(j = 0; j < posStringsAll->n; j++) {
                    posStrings = posStringsAll->all[j];
                    c->rc[i++] = posStrings->n;
                    for(k = 0; k < posStrings->n; k++) {
                        c->rc[i++] = (unsigned short) strtoul(posStrings->all[k], NULL, 0);
                    }
                    free(posStrings->all[0]); // subsequent elements are just pointers in to a block of memory from the same malloc
                    listDelete(posStrings, NULL);
                }
                listDelete(posStringsAll, NULL);

                if(nResResCheck != nResRes) {
                    fprintf(stderr, "Warning: contactParseLine: nResRes found for contact %d != given nResRes (%d != %d).\n", idContact, nResResCheck, nResRes);
                    c->nResRes = nResResCheck;
                }
            }
        }
        free(tokens->all[0]); // subsequent elements are just pointers in to a block of memory from the same malloc
        listDelete(tokens, NULL);
    }

    return c;
}

int contactParse(char *fileName, void *contacts, int (*contactSave)(void *, CONTACT *), int noclash, unsigned short minPPIResRes, unsigned short minPDIResRes, unsigned short minPCIResRes) {
    MYFILE  *file;
    char    *line;
    CONTACT *c;

    // FIXME - read in hsps and their alignments
    if((file = myFileOpen(fileName)) == NULL)
        return 1;

    line = (*file->nextLine)(file);
    while(line != NULL) {
        if((c = contactParseLine(line)) != NULL) {
            if((c->nClash > 0) && (noclash == 1)) {
                contactDelete(c);
            }
            else if((strcmp(c->type, "PPI") == 0) && (c->nResRes < minPPIResRes)) {
                contactDelete(c);
            }
            else if((strcmp(c->type, "PDI") == 0) && (c->nResRes < minPDIResRes)) {
                contactDelete(c);
            }
            else if(c->nResRes < minPCIResRes) {
                contactDelete(c);
            }
            else {
                (*contactSave)(contacts, c);
            }
        }
        line = (*file->nextLine)(file);
    }
    myFileDelete(file);

    return 0;
}

LIST *contactGroupBySequence(LIST *contacts, HASH *domToSeq, LIST *seqGroups, unsigned int *idGroup) {
    LIST    *groups;
    HASH    *groupsBySeqIds;
    LIST    *seqGroupA, *seqGroupB;
    HASH    *seqToGroup;
    LIST    *group;
    int     i, j;
    CONTACT *c;
    char    *idSeqA1, *idSeqB1;
    char    idA[49];
    char    idB[49];
    char    key[100];

    if((groupsBySeqIds = hashCreate(contacts->n)) == NULL) return NULL;

    seqToGroup = NULL;
    if(seqGroups != NULL) {
        if((seqToGroup = hashCreate(0)) == NULL) return NULL;
        for(i = 0; i < seqGroups->n; i++) {
            seqGroupA = (LIST *) seqGroups->all[i];
            //printf("seqGroup %8d\n", seqGroupA->n);
            for(j = 0; j < seqGroupA->n; j++) {
                idSeqA1 = (char *) seqGroupA->all[j];
                hashAddElement(seqToGroup, idSeqA1, seqGroupA);
            }
        }
    }

    for(i = 0; i < contacts->n; i++) {
        c = contacts->all[i];

        memset(idA, '\0', 49);
        memset(idB, '\0', 49);
        memset(key, '\0', 100);

        idSeqA1 = (char *) hashGetElement(domToSeq, c->idDomA);
        if((idSeqA1 = (char *) hashGetElement(domToSeq, c->idDomA)) != NULL)
            if((seqToGroup != NULL) && ((seqGroupA = (LIST *) hashGetElement(seqToGroup, idSeqA1)) != NULL))
                sprintf(idA, "G%d", seqGroupA->id);
            else
                sprintf(idA, "S%s", idSeqA1);
        else
            sprintf(idA, "D%s", c->idDomA);

        idSeqB1 = (char *) hashGetElement(domToSeq, c->idDomB);
        if((idSeqB1 = (char *) hashGetElement(domToSeq, c->idDomB)) != NULL)
            if((seqToGroup != NULL) && ((seqGroupB = (LIST *) hashGetElement(seqToGroup, idSeqB1)) != NULL))
                sprintf(idB, "G%d", seqGroupB->id);
            else
                sprintf(idB, "S%s", idSeqB1);
        else
            sprintf(idB, "D%s", c->idDomB);

        memset(key, 100, '\0');
        sprintf(key, "%s:%s", idA, idB);

        if((group = (LIST *) hashGetElement(groupsBySeqIds, key)) == NULL) {
            if((group = listCreate(key)) == NULL) return NULL;
            group->id = ++(*idGroup);
            hashAddElement(groupsBySeqIds, key, group);
        }
        listAddElement(group, 1, c);
    }

    if((groups = hashGetAllValues(groupsBySeqIds)) == NULL) return NULL;
    listSort(groups, listSortById);
    hashDelete(groupsBySeqIds, NULL);
    if(seqToGroup != NULL) hashDelete(seqToGroup, NULL);

    return groups;
}

int contactsJaccards(LIST *group, HASH *domToSeq, float minJaccard, HASH *hsps) {
    int            i, j;
    CONTACT        *c1, *c2;
    int            ud, n; // ud = size of upper-diagonal
    float          (*calcJaccard)(CONTACT *, CONTACT *, HASH *, HASH *);
    float          jaccard;

    // FIXME - put pairs of contacts with jaccard >= threshold in to the same group

    ud = (group->n * (group->n - 1)) / 2;
    n = 0;
    calcJaccard = (hsps == NULL) ? &contactJaccard : &contactJaccardFromHsps;

    for(i = 0; i < group->n; i++) {
        c1 = (CONTACT *) group->all[i];
        for(j = i + 1; j < group->n; j++) {
            c2 = (CONTACT *) group->all[j];

            // max possible jaccard is if one contact is a complete subset of the other
            jaccard = (c1->nResRes < c2->nResRes) ? ((float) c1->nResRes / c2->nResRes) : ((float) c2->nResRes / c1->nResRes);
            if(jaccard < minJaccard) {
                //printf("%d/%d\t%d\t%d\t%d\t%d\t%f\n", n, ud, c1->id, c1->nResRes, c2->id, c2->nResRes, jaccard);
                continue;
            }
            jaccard = (*calcJaccard)(c1, c2, domToSeq, hsps);
            ++n;
            //printf("%d/%d\t%d\t%d\t%d\t%d\t%f\n", n, ud, c1->id, c1->nResRes, c2->id, c2->nResRes, jaccard);
        }
    }

    return 0;
}

LIST *contactGroupByJaccards(LIST *contacts, HASH *domToSeq, float minJaccard, HASH *hsps, unsigned int *idGroup) {
    LIST          *groups;
    unsigned int  i, j, idMax;
    unsigned char *visited;
    LIST          *queue;
    LIST          *members;
    CONTACT       *c1, *c2;
    unsigned char unvisited = 0;
    unsigned char seen      = 1;
    unsigned char finished  = 2;
    float         (*calcJaccard)(CONTACT *, CONTACT *, HASH *, HASH *);
    float         jaccard;

    calcJaccard = (hsps == NULL) ? &contactJaccard : &contactJaccardFromHsps;

    if((groups = listCreate(NULL)) == NULL) return NULL;

    // order contact list by increasing nResRes
    listSort(contacts, contactSortByNResRes);

    /*
     * FIXME - change visited to 'HASH *' if/when I
     * find a good way to allow hashes to use integer keys
     * or string keys, not just string keys. The following
     * might use a lot of memory, although the current
     * idMax is 9626862, and (9626862 + 1) * sizeof(unsigned int)
     * is 'only' about 37mb
     */
    idMax = 0;
    for(i = 0; i < contacts->n; i++) {
        c1 = (CONTACT *) contacts->all[i];
        if(c1->id > idMax) idMax = c1->id;
    }

    if((visited = (unsigned char *) calloc((idMax + 1), sizeof(unsigned int))) == NULL) {
        fprintf(stderr, "Error: contactGroupByJaccards: calloc failed.\n");
        return NULL;
    }

    if((queue = listCreate(NULL)) == NULL) return NULL;
    for(i = 0; i < contacts->n; i++) {
        c1 = (CONTACT *) contacts->all[i];
        if(visited[c1->id] != unvisited) continue;
        visited[c1->id] = seen;

        if((members = listCreate(NULL)) == NULL) continue;
        while(c1 != NULL) {
            listAddElement(members, 1, c1);
            for(j = 0; j < contacts->n; j++) { // don't start with j = i + 1
                c2 = (CONTACT *) contacts->all[j];
                if(visited[c2->id] != unvisited) continue;

                // max possible jaccard is if one contact is a complete subset of the other
                if(c1->nResRes < c2->nResRes) {
                    jaccard = (float) c1->nResRes / c2->nResRes;
                    /*
                     * since the contact list is ordered by increasing nResRes,
                     * c1->nResRes will be less than all subsequent c2->nResRes
                     * and so comparisons of c1 to subsequent c2s will also have
                     * a max possible jaccard that is below the minJaccard threshold
                     */
                    if(jaccard < minJaccard) {
                        //printf("JACCARD\t%u\t%u\t%u\t%u\t%.2f\t(MAX POSSIBLE)\n", c1->id, c2->id, c1->nResRes, c2->nResRes, jaccard);
                        break;
                    }
                }
                else if(c2->nResRes < c1->nResRes) {
                    jaccard = (float) c2->nResRes / c1->nResRes;
                    if(jaccard < minJaccard) {
                        //printf("JACCARD\t%u\t%u\t%u\t%u\t%.2f\t(MAX POSSIBLE)\n", c1->id, c2->id, c1->nResRes, c2->nResRes, jaccard);
                        continue;
                    }
                }
                /*
                else {
                    printf("JACCARD\t%u\t%u\t%u\t%u\t%.2f\t(MAX POSSIBLE)\n", c1->id, c2->id, c1->nResRes, c2->nResRes, 1.0);
                }
                */

                // now calculate the actual jaccard
                jaccard = (*calcJaccard)(c1, c2, domToSeq, hsps);
                //printf("JACCARD\t%u\t%u\t%u\t%u\t%.2f\n", c1->id, c2->id, c1->nResRes, c2->nResRes, jaccard);
                if(jaccard < minJaccard) continue;
                listAddElement(queue, 1, c2);
                visited[c2->id] = seen;
            }
            visited[c1->id] = finished;
            c1 = listShift(queue);
        }

        if(members->n > 0) {
            members->id = ++(*idGroup);
            listAddElement(groups, 1, members);
        }
        else {
            listDelete(members, NULL);
        }
    }
    listDelete(queue, NULL);
    free(visited);

    return groups;
}

