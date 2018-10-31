#include "contactHit.h"
#include "maths.h"

char *chType(HASH *domToChemType, char *idDomA2, char *idDomB2, char *idSeqA1, char *idSeqB1, char *idSeqA2, char *idSeqB2) {
    char *chType, *typeA2, *typeB2;

    chType = (char *) malloc(7 * sizeof(char));
    if(chType == NULL) {
        fprintf(stderr, "Error: chType: malloc failed.\n");
        return NULL;
    }
    memset(chType, '\0', 7);

    if(domToChemType == NULL) {
        sprintf(chType, "UNK");
        return chType;
    }

    if((typeA2 = (char *) hashGetElement(domToChemType, idDomA2)) == NULL) {
        fprintf(stderr, "Error: chType: no type for dom %s.\n", idDomA2);
        sprintf(chType, "UNK");
        return chType;
    }

    if((typeB2 = (char *) hashGetElement(domToChemType, idDomB2)) == NULL) {
        fprintf(stderr, "Error: chType: no type for dom %s.\n", idDomB2);
        sprintf(chType, "UNK");
        return chType;
    }

    if(strcmp(typeA2, "peptide") == 0) {
        if(strcmp(typeB2, "peptide") == 0) {
            sprintf(chType, "PPI%s", (idSeqB1 == NULL) ? "nqm" : ""); // 'nqm' = no query match
        }
        else if(strcmp(typeB2, "nucleotide") == 0) {
            sprintf(chType, "PDI%s", (idSeqB1 == NULL) ? "nqm" : "");
        }
        else {
            sprintf(chType, "PCI%s", (idSeqB1 == NULL) ? "nqm" : "");
        }
    }
    else {
        // should always be a peptide interacting with something else for now
        sprintf(chType, "UNK");
    }

    return chType;
}

CONTACTHIT *contactHitCreate(unsigned int idCh, char *idSeqA1, char *idSeqB1, char *idSeqA2, char *idSeqB2, CONTACT *cA2B2, HSP *hspA1A2, HSP *hspB2B1, HASH *domToChemType) {
    CONTACTHIT     *ch;

    if((ch = (CONTACTHIT *) malloc(sizeof(CONTACTHIT))) == NULL) {
        fprintf(stderr, "Error: contactHitCreate: malloc failed.\n");
        return NULL;
    }
    ch->id = idCh;
    ch->type = chType(domToChemType, cA2B2->idDomA, cA2B2->idDomB, idSeqA1, idSeqB1, idSeqA2, idSeqB2);
    ch->idSeqA1 = idSeqA1;
    ch->idSeqB1 = idSeqB1;
    ch->idSeqA2 = idSeqA2;
    ch->idSeqB2 = idSeqB2;
    ch->cA2B2 = cA2B2;
    ch->hspA1A2 = hspA1A2;
    ch->hspB2B1 = hspB2B1;
    ch->rc = NULL;
    ch->residues = NULL;
    ch->nResA1 = 0;
    ch->nResB1 = 0;
    ch->nResResA1B1 = 0;

    if(hspA1A2 == NULL) {
        ch->pcidA = 100;
        ch->eValueA = 0.0;
    }
    else {
        ch->pcidA = hspA1A2->pcid;
        ch->eValueA = hspA1A2->eValue;
    }

    if(hspB2B1 == NULL) {
        ch->pcidB = 100;
        ch->eValueB = 0.0;
    }
    else {
        ch->pcidB = hspB2B1->pcid;
        ch->eValueB = hspB2B1->eValue;
    }
    ch->nResA1 = 0;
    ch->nResB1 = 0;
    ch->nResResA1B1 = 0;
    ch->rc = NULL;
    ch->residues = NULL;

    //contactHitResiduesCreate(ch);

    return ch;
}

int outputMapping(char *id, unsigned short start, unsigned short end, short *edits, unsigned short nEdits) {
    int i;

    printf("MAPPING\t%s:%d-%d\t", id, start, end);
    for(i = 0; i < nEdits; i++) {
        printf("%d,", edits[i]);
    }
    printf("\n");

    return 0;
}

int contactHitResiduesCreate(CONTACTHIT *ch) {
    unsigned short tPosA2, nPosA2, idx2, idx2Start, idx2End, posA2, posB2, aposA, aposB, posA1, posB1, nPos, idx1, idx1nPosB;
    unsigned short idxResRes;
    unsigned short **mappingA1 = NULL;
    unsigned short **mappingA2 = NULL;
    unsigned short **mappingB1 = NULL;
    unsigned short **mappingB2 = NULL;
    unsigned short (*mapFuncA1)(unsigned short **mapping, unsigned short idx, unsigned short pos);
    unsigned short (*mapFuncA2)(unsigned short **mapping, unsigned short idx, unsigned short pos);
    unsigned short (*mapFuncB1)(unsigned short **mapping, unsigned short idx, unsigned short pos);
    unsigned short (*mapFuncB2)(unsigned short **mapping, unsigned short idx, unsigned short pos);
    int            cRcLength, chRcLength;
    unsigned short *posnsB1; // for counting
    unsigned short *rcNew;
    unsigned short *residuesNew;

    //printf("contactHitResiduesCreate\tch->id\t%d\tch->cA2B2->id\t%d\tnResRes\t%d\n", ch->id, ch->cA2B2->id, ch->cA2B2->nResResA1B1);

    if(ch->hspA1A2 == NULL) {
        mappingA1 = NULL;
        mapFuncA1 = &posPassThrough;
        mappingA2 = NULL;
        mapFuncA2 = &posPassThrough;
    }
    else {
        mappingA1 = alignedSeqPosMapping(ch->hspA1A2->seqLen1, ch->hspA1A2->start1, ch->hspA1A2->edits, ch->hspA1A2->nEdits1, ch->hspA1A2->len);
        mapFuncA1 = &posFromMapping;
        mappingA2 = alignedSeqPosMapping(ch->hspA1A2->seqLen2, ch->hspA1A2->start2, ch->hspA1A2->edits + ch->hspA1A2->nEdits1, ch->hspA1A2->nEdits2, ch->hspA1A2->len);
        mapFuncA2 = &posFromMapping;
        //outputMapping(ch->idSeqA1, ch->hspA1A2->start1, ch->hspA1A2->end1, ch->hspA1A2->edits, ch->hspA1A2->nEdits1);
        //outputMapping(ch->idSeqA2, ch->hspA1A2->start2, ch->hspA1A2->end2, ch->hspA1A2->edits + ch->hspA1A2->nEdits1, ch->hspA1A2->nEdits2);
    }

    if(ch->hspB2B1 == NULL) {
        mappingB1 = NULL;
        mapFuncB1 = &posPassThrough;
        mappingB2 = NULL;
        mapFuncB2 = &posPassThrough;
        posnsB1 = NULL;
    }
    else {
        mappingB2 = alignedSeqPosMapping(ch->hspB2B1->seqLen1, ch->hspB2B1->start1, ch->hspB2B1->edits, ch->hspB2B1->nEdits1, ch->hspB2B1->len);
        mapFuncB2 = &posFromMapping;
        mappingB1 = alignedSeqPosMapping(ch->hspB2B1->seqLen2, ch->hspB2B1->start2, ch->hspB2B1->edits + ch->hspB2B1->nEdits1, ch->hspB2B1->nEdits2, ch->hspB2B1->len);
        mapFuncB1 = &posFromMapping;
        //outputMapping(ch->idSeqB2, ch->hspB2B1->start1, ch->hspB2B1->end1, ch->hspB2B1->edits, ch->hspB2B1->nEdits1);
        //outputMapping(ch->idSeqB1, ch->hspB2B1->start2, ch->hspB2B1->end2, ch->hspB2B1->edits + ch->hspB2B1->nEdits1, ch->hspB2B1->nEdits2);

        // initialise array to count posB1s involved in interactions
        if((posnsB1 = (unsigned short *) calloc((ch->hspB2B1->seqLen2 + 1), sizeof(unsigned short))) == NULL) {
            fprintf(stderr, "Error: contactHitResiduesCreate: calloc failed for posnsB1.\n");
            return 1;
        }
    }
    ch->nResA1 = 0;
    ch->nResB1 = 0;
    ch->nResResA1B1 = 0;

    // calculate contact hit residues, ie. posB1 and posB1

    // store as 1d array of positions, cf. contact->rc
    cRcLength = 1; // first element gives the number of posAs
    tPosA2 = ch->cA2B2->nResA;
    nPosA2 = 0;
    idx2End = 0;
    while(nPosA2 < tPosA2) {
        ++nPosA2;
        idx2Start = idx2End + 2;
        cRcLength += (1 + ch->cA2B2->rc[idx2End + 1]); // 1 for the element that gives the number of positions, + the number of positions
        idx2End += (ch->cA2B2->rc[idx2End + 1] + 1);
    }
    if((ch->rc = (unsigned short *) malloc(cRcLength * sizeof(unsigned short))) == NULL) {
        fprintf(stderr, "Error: contactHitResiduesCreate: malloc failed for ch->rc.\n");
        return 1;
    }
    idx1 = 0;
    ch->rc[idx1] = 0;

    // store as 1d array of positions paired with contact positions
    if((ch->residues = (unsigned short *) malloc((4 * ch->cA2B2->nResRes) * sizeof(unsigned short))) == NULL) {
        fprintf(stderr, "Error: contactHitResiduesCreate: malloc failed for ch->rc.\n");
        return 1;
    }
    idxResRes = 0;

    tPosA2 = ch->cA2B2->rc[0];
    nPosA2 = 0;
    idx2End = 0;
    while(nPosA2 < tPosA2) {
        ++nPosA2;
        idx2Start = idx2End + 2;
        idx2End += (ch->cA2B2->rc[idx2End + 1] + 1);
        posA2 = ch->cA2B2->rc[idx2Start++];

        // map posA2 to posA1
        if((aposA = (*mapFuncA2)(mappingA2, 0, posA2)) == 0) continue;
        if((posA1 = (*mapFuncA1)(mappingA1, 1, aposA)) == 0) continue;
        nPos = 0;
        ch->rc[++idx1] = nPos;
        idx1nPosB = idx1;
        ch->rc[++idx1] = posA1;
        nPos++;

        for(idx2 = idx2Start; idx2 <= idx2End; idx2++) {
            posB2 = ch->cA2B2->rc[idx2];

            // map posB2 to posB1
            if((aposB = (*mapFuncB2)(mappingB2, 0, posB2)) == 0) continue;
            if((posB1 = (*mapFuncB1)(mappingB1, 1, aposB)) == 0) continue;
            ch->rc[++idx1] = posB1;
            nPos++;
            ch->nResResA1B1++;

            //printf("%u\t%u\t%u\t%u\t%u\n", ch->id, posA1, posB1, posA2, posB2);
            ch->residues[idxResRes++] = posA1;
            ch->residues[idxResRes++] = posB1;
            ch->residues[idxResRes++] = posA2;
            ch->residues[idxResRes++] = posB2;
            if(posnsB1 != NULL) posnsB1[posB1]++;
        }

        if(nPos > 1) { // at least one posB1 was mapped to the interaction with posA1
            ch->rc[idx1nPosB] = nPos;
            ch->nResA1++;
        }
        else {
            idx1 = idx1nPosB - 1;
        }
    }

    if(ch->nResA1 > 0) {
        ch->rc[0] = ch->nResA1;
        chRcLength = idx1 + 1;
        //printf("chRcLength = %d\n", chRcLength);
        if((rcNew = (unsigned short *) realloc(ch->rc, chRcLength * sizeof(unsigned short))) == NULL) {
            fprintf(stderr, "Error: contactHitResiduesCreate: realloc failed for ch->rc.\n");
            return 1;
        }
        ch->rc = rcNew;

        //printf("nResResA1B1 = %d\n", ch->nResResA1B1);
        if((residuesNew = (unsigned short *) realloc(ch->residues, (4 * ch->nResResA1B1) * sizeof(unsigned short))) == NULL) {
            fprintf(stderr, "Error: contactHitResiduesCreate: malloc failed for ch->rc.\n");
            return 1;
        }
        ch->residues = residuesNew;

        // count nResB1
        ch->nResB1 = 0;
        if(posnsB1 != NULL) {
            for(posB1 = 1; posB1 <= ch->hspB2B1->seqLen2; posB1++) {
                if(posnsB1[posB1] > 0) ch->nResB1++;
            }
        }
    }
    else {
        free(ch->rc);
        ch->rc = NULL;
    }
    if(posnsB1 != NULL) free(posnsB1);

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

    return 0;
}

int contactHitResiduesDelete(void *thing) {
    CONTACTHIT *ch;

    ch = (CONTACTHIT *) thing;

    if(ch->residues != NULL) free(ch->residues);
    ch->residues = NULL;

    if(ch->rc != NULL) free(ch->rc);
    ch->rc = NULL;

    return 0;
}

int contactHitDelete(void *thing) {
    CONTACTHIT *ch;

    ch = (CONTACTHIT *) thing;

    contactHitResiduesDelete(ch);
    if(ch->type != NULL)
        free(ch->type);
    free(ch);

    return 0;
}

CONTACTHIT *contactHitParseSimple(char *idLine, char *cA2B2Line, char *hspA1A2Line, char *hspB2B1Line) {
    // parse minimum info needed to run contactHitResiduesCreate

    unsigned int id;
    char         type[7] = "UNK";
    char         *idSeqA1, *idSeqA2, *idSeqB1, *idSeqB2;
    CONTACT      *cA2B2;
    HSP          *hspA1A2;
    HSP          *hspB2B1;
    CONTACTHIT   *ch;

    id = (unsigned int) strtoul(idLine, NULL, 0);
    if((cA2B2 = contactParseLine(cA2B2Line)) == NULL) return NULL;
    //if((hspA1A2 = hspParseLine(hspA1A2Line, 0, 0, 0, &idSeqA1, &idSeqA2)) == NULL) return NULL;
    //if((hspB2B1 = hspParseLine(hspB2B1Line, 0, 0, 0, &idSeqB2, &idSeqB1)) == NULL) return NULL;
    hspA1A2 = hspParseLine(hspA1A2Line, 0, 0, 0, &idSeqA1, &idSeqA2);
    hspB2B1 = hspParseLine(hspB2B1Line, 0, 0, 0, &idSeqB2, &idSeqB1);
    ch = contactHitCreate(id, idSeqA1, idSeqB1, idSeqA2, idSeqB2, cA2B2, hspA1A2, hspB2B1, NULL);

    // FIXME - need idSeqB1 from somewhere, even if there's no hspB2B1

    return ch;
}

int contactHitResiduesOutput(CONTACTHIT *ch, FILE *fhContactHitResidue) {
    int i, idxResRes;

    if((fhContactHitResidue != NULL) && (ch->residues != NULL)) {
        for(i = 0, idxResRes = 0; i < ch->nResResA1B1; i++, idxResRes += 4) {
            fprintf(
                    fhContactHitResidue,
                    "%u\t%u\t%u\t%u\t%u\n",
                    ch->id,                      // 00 - idCh
                    ch->residues[idxResRes],     // 01 - posA1
                    ch->residues[idxResRes + 1], // 02 - posB1
                    ch->residues[idxResRes + 2], // 03 - posA2
                    ch->residues[idxResRes + 3]  // 04 - posB2
                    );
        }
    }

    return 0;
}

int chrCompactA(CONTACTHIT *ch, char **str, int idxStart, int idxEnd, unsigned short a1, unsigned short a2) {
    char            strTemp[20];
    unsigned short  b1, b2;
    int             nNumbers, idxResRes;

    memset(strTemp, '\0', 20);
    sprintf(strTemp, "%u,%u", a1, a2);
    stringCat(str, strTemp);
    for(idxResRes = idxStart; idxResRes <= idxEnd; idxResRes += 4) {
        b1 = ch->residues[idxResRes + 1];
        b2 = ch->residues[idxResRes + 3];
        memset(strTemp, '\0', 20);
        sprintf(strTemp, ",%u,%u", b1, b2);
        stringCat(str, strTemp);
    }
    stringCat(str, ";");

    return 0;
}

int contactHitResiduesOutputCompact(CONTACTHIT *ch, FILE *fh) {
    char            *str, *strCompressed;
    int             len;
    int             i, idxResRes, idxStart, n;
    unsigned short  p_a1, p_a2, a1, b1, a2, b2;

    if(ch->residues != NULL) {
        if(stringInit(&str, "") != 0)
            return 1;

        p_a1 = 0;
        p_a2 = 0;
        idxStart = -1;
        n = 0;
        for(i = 0, idxResRes = 0; i < ch->nResResA1B1; i++, idxResRes += 4) {
            a1 = ch->residues[idxResRes];
            b1 = ch->residues[idxResRes + 1];
            a2 = ch->residues[idxResRes + 2];
            b2 = ch->residues[idxResRes + 3];

            if((a1 != p_a1) || (a2 != p_a2)) {
                if(n > 0)
                    chrCompactA(ch, &str, idxStart, idxResRes - 1, p_a1, p_a2);
                idxStart = idxResRes;
                n = 0;
            }
            n++;

            p_a1 = a1;
            p_a2 = a2;
        }
        if(n > 0)
            chrCompactA(ch, &str, idxStart, idxResRes - 1, p_a1, p_a2);

        /*
         * not outputting gzipped string as it isn't possible to mix this with
         * non-binary columns and still import to mysql with LOAD DATA LOCAL INFILE,
         * at least not without a lot of mucking about, because the gzipped string
         * may contain what appear to be field delimeters. Easier to output the
         * uncompressed string and use mysql COMPRESS on import
         */
        /*
        if((strCompressed = stringCompress(str)) != NULL) {
            fprintf(fh, "%s", strCompressed);
            stringDelete(strCompressed);
        }
        */
        fprintf(fh, "%s", str);
        stringDelete(str);
    }

    return 0;
}

int contactHitOutput(CONTACTHIT *ch, FILE *fhContactHit, FILE *fhContactHitResidue) {
    // FIXME - don't test (ch->hspB2B1 != NULL) etc. multiple times

    unsigned short startB1, endB1, startB2, endB2;
    int i, idxResRes, last;

    if(ch->hspB2B1 == NULL) {
        startB1 = 0;
        endB1   = 0;
        startB2 = 0;
        endB2   = 0;
    }
    else {
        // Note: hspB2B1 is in the direction B2 -> B1
        startB1 = ch->hspB2B1->start2;
        endB1 = ch->hspB2B1->end2;
        startB2 = ch->hspB2B1->start1;
        endB2 = ch->hspB2B1->end1;
    }

    fprintf(
            fhContactHit,
            "%u\t%s\t%s\t%u\t%u\t%s\t%u\t%u\t%s\t%u\t%u\t%s\t%u\t%u\t%u\t%u\t%u\t%u\t%.2f\t%.2e\t%.2f\t%.2e\t",

            ch->id,                                    // 00
            ch->type,                                  // 01

            ch->idSeqA1,                               // 02
            ch->hspA1A2->start1,                       // 03
            ch->hspA1A2->end1,                         // 04

            (ch->idSeqB1 != NULL) ? ch->idSeqB1 : "0", // 05
            startB1,                                   // 06
            endB1,                                     // 07

            ch->idSeqA2,                               // 08
            ch->hspA1A2->start2,                       // 09
            ch->hspA1A2->end2,                         // 10

            (ch->idSeqB2 != NULL) ? ch->idSeqB2 : "0", // 11
            startB2,                                   // 12
            endB2,                                     // 13

            ch->cA2B2->id,                             // 14

            ch->nResA1,                                // 15
            ch->nResB1,                                // 16
            ch->nResResA1B1,                           // 17
           
            (float) ch->pcidA,                         // 18
            ch->eValueA,                               // 19

            (float) ch->pcidB,                         // 20
            ch->eValueB                                // 21
            );

    if((ch->nResResA1B1 != 0) && (ch->residues != NULL)) {
        contactHitResiduesOutputCompact(ch, fhContactHit);
        if(fhContactHitResidue != NULL)
            contactHitResiduesOutput(ch, fhContactHitResidue);
    }
    fprintf(fhContactHit, "\n");

    return 0;
}

int contactHitSortBest(const void *a, const void *b) {
    const CONTACTHIT *chA = *(const CONTACTHIT **) a;
    const CONTACTHIT *chB = *(const CONTACTHIT **) b;
    double eValueA, eValueB;
    unsigned char pcidA, pcidB;

    /*
     * - biological interfaces first
     * - then lowest sum of e-values
     * - then highest sum of pcids
     */

    if(chA->cA2B2->crystal == 0) {
        if(chB->cA2B2->crystal == 0) {
            //eValueA = chA->eValueA + chA->eValueB;
            //eValueB = chB->eValueA + chB->eValueB;
            eValueA = MAXVALUE(chA->eValueA, chA->eValueB);
            eValueB = MAXVALUE(chB->eValueA, chB->eValueB);

            if(eValueA < eValueB)
                return -1;
            else if(eValueB > eValueA)
                return 1;
            else {
                // FIXME - use the minimum pcid
                //pcidA = chA->pcidA + chA->pcidB;
                //pcidB = chB->pcidA + chB->pcidB;
                pcidA = MINVALUE(chA->pcidA, chA->pcidB);
                pcidB = MINVALUE(chB->pcidA, chB->pcidB);

                if(pcidA > pcidB)
                    return -1;
                else if(pcidB > pcidA)
                    return 1;
                else {
                    if(chA->cA2B2->id < chB->cA2B2->id) {
                        return -1;
                    }
                    else if(chA->cA2B2->id > chB->cA2B2->id) {
                        return 1;
                    }
                    else {
                        return 0;
                    }
                }
            }
        }
        else {
            return -1;
        }
    }
    else {
        return 1;
    }

    return 0;
}
