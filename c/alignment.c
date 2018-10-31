#include "alignment.h"

#define MAXSTRINGLEN 100000
#define SEQLINELEN 60

ALIGNMENT *alignmentCreate() {
    ALIGNMENT *aln;

    aln = (ALIGNMENT *) malloc(sizeof(ALIGNMENT));
    if(aln == NULL) {
        fprintf(stderr, "Error: alignmentCreate: malloc failed.\n");
        return NULL;
    }
    aln->len = 0;
    aln->aseqs = hashCreate(0);

    return aln;
}

ALIGNEDSEQ *alignedSeqCreate(unsigned short start, unsigned short end, unsigned short seqLen, char *aseq) {
    ALIGNEDSEQ *alnSeq;

    if((alnSeq = (ALIGNEDSEQ *) malloc(sizeof(ALIGNEDSEQ))) == NULL) {
        fprintf(stderr, "Error: alignedSeqCreate: malloc failed.\n");
        return NULL;
    }

    alnSeq->start = start;
    alnSeq->end = end;
    alnSeq->seqLen = seqLen;
    alnSeq->aseq = aseq;
    alnSeq->nEdits = 0;
    alnSeq->edits = NULL;

    return alnSeq;
}

int alignedSeqDelete(void *thing) {
    ALIGNEDSEQ *alnSeq;

    alnSeq = (ALIGNEDSEQ *) thing;

    if(alnSeq->aseq != NULL)
        free(alnSeq->aseq);
    if(alnSeq->edits != NULL)
        free(alnSeq->edits);
    free(alnSeq);

    return 0;
}

unsigned short **alignedSeqPosMapping(unsigned short seqLen, unsigned short start, short *edits, unsigned short nEdits, unsigned int alnLen) {
    unsigned short i, pos, posStart, posEnd, apos, aposStart, aposEnd;
    short          edit;
    unsigned short **mapping;
    unsigned short *posToApos, *aposToPos;

    if((mapping = (unsigned short **) malloc(2 * sizeof(unsigned short *))) == NULL) {
        fprintf(stderr, "Error: alignedSeqPosMapping: malloc failed.\n");
        return NULL;
    }

    if((posToApos = (unsigned short *) calloc((seqLen + 1), sizeof(unsigned short))) == NULL) { // '+ 1' because seq positions are 1-based
        fprintf(stderr, "Error: alignedSeqPosMapping: malloc failed.\n");
        return NULL;
    }

    if((aposToPos = (unsigned short *) calloc((alnLen + 1), sizeof(unsigned short))) == NULL) { // '+ 1' because seq positions are 1-based
        fprintf(stderr, "Error: alignedSeqPosMapping: malloc failed.\n");
        return NULL;
    }

    mapping[0] = posToApos;
    mapping[1] = aposToPos;
    aposStart = 0;
    aposEnd   = 0;
    posStart  = 0;
    posEnd    = start - 1;
    for(i = 0; i < nEdits; i++) {
        edit = edits[i];
        aposStart = aposEnd + 1;
        aposEnd += abs(edit);
        if(edit > 0) {
            posStart = posEnd + 1;
            posEnd += edit;
            for(pos = posStart, apos = aposStart; pos <= posEnd; pos++, apos++) {
                posToApos[pos] = apos;
                aposToPos[apos] = pos;
            }
        }
    }

    return mapping;
}

int alignedSeqKVPDelete(void *thing) {
    KEYVALUEPAIR *kvp;

    kvp = (KEYVALUEPAIR *) thing;
    free(kvp->key); // seq id
    alignedSeqDelete(kvp->value); // aligned seq
    free(kvp);

    return 0;
}

int alignmentDelete(void *thing) {
    ALIGNMENT *aln;

    aln = (ALIGNMENT *) thing;

    hashDelete(aln->aseqs, alignedSeqKVPDelete);
    free(aln);

    return 0;
}

ALIGNMENT *alignmentParseFasta(MYFILE *file) {
    ALIGNMENT      *aln;
    char           *line;
    char           tmpString[MAXSTRINGLEN];
    char           *id;
    char           *aseq;
    ALIGNEDSEQ     *alnSeq;
    unsigned short len;

    // read the alignment
    aln = alignmentCreate();
    if(aln == NULL)
        return NULL;

    id = NULL;
    alnSeq = NULL;
            
    line = (*file->nextLine)(file);
    while(line != NULL) {
        if(line[0] == '>') {
            if(id != NULL) {
                len = strlen(aseq);
                if((alnSeq = alignedSeqCreate(1, len, len, aseq)) == NULL)
                    return NULL;
                alignmentAddAseq(aln, id, alnSeq);
                free(id); // no longer needed because its value is copied by alignmentAddAseq
            }

            memset(tmpString, '\0', MAXSTRINGLEN);
            sscanf(&line[1], "%s", tmpString);

            if(stringInit(&id, tmpString) != 0)
                return NULL;

            if(stringInit(&aseq, "") != 0)
                return NULL;
        }
        else {
            stringCat(&aseq, line);
        }

        // get next line of input
        line = (*file->nextLine)(file);
    }

    if(id != NULL) {
        len = strlen(aseq);
        if((alnSeq = alignedSeqCreate(1, len, len, aseq)) == NULL)
            return NULL;
        alignmentAddAseq(aln, id, alnSeq);
        free(id); // no longer needed because its value is copied by alignmentAddAseq
    }

    return aln;
}

float alignedSeqLengthFraction(ALIGNEDSEQ *aseq) {
    float lf;

    lf = (float) (aseq->end - aseq->start + 1) / aseq->seqLen;

    return lf;
}

int alignmentOutputFasta(ALIGNMENT *aln, FILE *fh) {
    int        i;
    int        start;
    char       *id;
    ALIGNEDSEQ *alnSeq;
    LIST       *keys;

    if((keys = hashGetAllKeys(aln->aseqs)) == NULL) return 1;
    for(i = 0; i < keys->n; i++) {
        id = (char *) keys->all[i];
        alnSeq = (ALIGNEDSEQ *) hashGetElement(aln->aseqs, id);
        if(alnSeq == NULL) {
            fprintf(stderr, "Error: alignmentOutputFasta: no alnSeq with id '%s'.", id);
            return 1;
        }
        fprintf(fh, ">%s\n", id);
        if(alnSeq->aseq == NULL) {
            fprintf(stderr, "Error: alignmentOutputFasta: alnSeq '%s' has no aseq string.", id);
            continue;
        }
        else {
            for(start = 0; start < aln->len; start += SEQLINELEN) {
                fprintf(fh, "%.*s\n", SEQLINELEN, alnSeq->aseq + start);
            }
        }
    }
    listDelete(keys, NULL);

    return 0;
}

int alignmentAddAseq(ALIGNMENT *aln, char *id, ALIGNEDSEQ *alnSeq) {
    int seqLen;

    if(hashGetElement(aln->aseqs, id) != NULL) {
        fprintf(stdout, "Error: alignmentAddAseq: non-unique sequence identifier '%s'.\n", id);
        return 1;
    }
    hashAddElement(aln->aseqs, id, alnSeq);

    if(alnSeq->aseq != NULL) {
        seqLen = strlen(alnSeq->aseq);
        if(aln->len == 0) {
            aln->len = seqLen;
        }
        else if(aln->len != seqLen) {
            fprintf(stderr, "Error: alignmentAddAseq: sequences of different lengths.");
            return 1;
        }
    }

    return 0;
}

ALIGNEDSEQ *alignmentGetAseq(ALIGNMENT *aln, char *id) {
    ALIGNEDSEQ *aseq;

    if((aseq = (ALIGNEDSEQ *) hashGetElement(aln->aseqs, id)) == NULL) return NULL;

    return aseq;
}

unsigned short alignedSeqEditsStringToArray(short *edits, LIST *editStrings) {
    unsigned short len;
    int            edit;
    int            i;

    len = 0;
    for(i = 0; i < editStrings->n; i++) {
        edit = atoi(editStrings->all[i]);
        if((edit < -32768) || (edit > 32767))
            fprintf(stderr, "Error: alignedSeqEditsStringToArray: edit=%d out of range.\n", edit);
        edits[i] = (short) edit;
        len += abs(edits[i]);
    }

    return len;
}

HSP *hspCreate(
               unsigned short start1,
               unsigned short end1,
               unsigned short seqLen1,
               unsigned short nEdits1,
               unsigned short start2,
               unsigned short end2,
               unsigned short seqLen2,
               unsigned short nEdits2,
               unsigned int   len,
               unsigned char  pcid,
               double         eValue,
               LIST           *editStrings1,
               LIST           *editStrings2
               ) {
    HSP            *hsp;
    unsigned short len1, len2;

    if((hsp = (HSP *) malloc(sizeof(HSP))) == NULL) {
        fprintf(stderr, "Error: hspCreate: malloc failed.\n");
        return NULL;
    }

    if((hsp->edits = (short *) malloc((nEdits1 + nEdits2) * sizeof(short))) == NULL) {
        fprintf(stderr, "Error: hspCreate: malloc failed.\n");
        return NULL;
    }

    hsp->start1  = start1;
    hsp->end1    = end1;
    hsp->seqLen1 = seqLen1;
    hsp->nEdits1 = nEdits1;

    hsp->start2  = start2;
    hsp->end2    = end2;
    hsp->seqLen2 = seqLen2;
    hsp->nEdits2 = nEdits2;

    hsp->len     = len;
    hsp->pcid    = pcid;
    hsp->eValue  = eValue;

    len1 = alignedSeqEditsStringToArray(hsp->edits, editStrings1);
    hsp->len = len1;
    len2 = alignedSeqEditsStringToArray(hsp->edits + editStrings1->n, editStrings2);
    if(len2 != len1) {
        fprintf(stderr, "Error: hspCreate: sequences of different lengths.");
        hspDelete(hsp);
        return NULL;
    }

    return hsp;
}

HSP *hspReverse(HSP *hsp) {
    HSP *hspR;

    if((hspR = (HSP *) malloc(sizeof(HSP))) == NULL) {
        fprintf(stderr, "Error: hspReverse: malloc failed.\n");
        return NULL;
    }

    if((hspR->edits = (short *) malloc((hsp->nEdits2 + hsp->nEdits1) * sizeof(short))) == NULL) {
        fprintf(stderr, "Error: hspReverse: malloc failed.\n");
        return NULL;
    }

    hspR->start1  = hsp->start2;
    hspR->end1    = hsp->end2;
    hspR->seqLen1 = hsp->seqLen2;
    hspR->nEdits1 = hsp->nEdits2;

    hspR->start2  = hsp->start1;
    hspR->end2    = hsp->end1;
    hspR->seqLen2 = hsp->seqLen1;
    hspR->nEdits2 = hsp->nEdits1;

    hspR->len     = hsp->len;
    hspR->pcid    = hsp->pcid;
    hspR->eValue  = hsp->eValue;

    memcpy(hspR->edits, hsp->edits + hsp->nEdits1, hsp->nEdits2 * sizeof(short));
    memcpy(hspR->edits + hspR->nEdits1, hsp->edits, hsp->nEdits1 * sizeof(short));

    return hspR;
}

int hspDelete(void *thing) {
    HSP *hsp;

    hsp = (HSP *) thing;
    free(hsp->edits);
    free(hsp);

    return 0;
}

int hspSortByEvalue(const void *a, const void *b) {
    const HSP *hsp_a = *(const HSP **) a;
    const HSP *hsp_b = *(const HSP **) b;

    if(hsp_a->eValue < hsp_b->eValue) {
        return -1;
    }
    else if(hsp_a->eValue > hsp_b->eValue) {
        return 1;
    }

    return 0;
}

int hspSaveForward(HASH *hsps, char *idSeq1, char *idSeq2, HSP *hsp) {
    LIST *hsps12; // list of hsps between idSeq1 and idSeq2

    if((hsps12 = (LIST *) hash2DGetElement(hsps, idSeq1, idSeq2)) == NULL) {
        if((hsps12 = listCreate(NULL)) == NULL)
            return 1;
        hash2DAddElement(hsps, idSeq1, idSeq2, hsps12);
    }
    listAddElement(hsps12, 1, hsp);

    return 0;
}

int hspSaveReverse(HASH *hsps, char *idSeq1, char *idSeq2, HSP *hsp) {
    HSP  *hspR;

    if((hspR = hspReverse(hsp)) == NULL)
        return 1;
    hspSaveForward(hsps, idSeq2, idSeq1, hspR);
    hspDelete(hsp);

    return 0;
}

int hspSaveBoth(HASH *hsps, char *idSeq1, char *idSeq2, HSP *hsp) {
    HSP  *hspR;

    if((hspR = hspReverse(hsp)) == NULL)
        return 1;

    hspSaveForward(hsps, idSeq1, idSeq2, hsp);
    hspSaveForward(hsps, idSeq2, idSeq1, hspR);

    return 0;
}

HSP *hspParseLine(char *line, float minPcid, float minLf1, float minLf2, char **idSeq1, char **idSeq2) {
    LIST           *tokens;
    unsigned int   idHsp;
    unsigned short len1, start1, end1, len2, start2, end2;
    float          pcid, lf1, lf2;
    double         eValue;
    LIST           *editStrings1, *editStrings2;
    HSP            *hsp;

    hsp = NULL;

    if(((tokens = stringSplit(line, "\t", NULL)) != NULL) && (tokens->n >= 14)) {
        /*
         * 00 - id_hsp
         * 01 - pcid
         * 02 - score
         * 03 - eValue
         * 04 - id_seq1
         * 05 - id_seq2
         * 06 - len1
         * 07 - start1
         * 08 - end1
         * 09 - editStr1
         * 10 - len2
         * 11 - start2
         * 12 - end2
         * 13 - editStr2
         */

        if((pcid = (float) strtod(tokens->all[1], NULL)) < 0) {
            pcid = 0.0;

            // FIXME - calculate pcid from alignment
        }

        if(pcid >= minPcid) {
            idHsp  = (unsigned int) strtoul(tokens->all[0], NULL, 0);
            eValue = strtod(tokens->all[3], NULL);
            *idSeq1 = tokens->all[4];
            *idSeq2 = tokens->all[5];

            len1   = (unsigned short) strtoul(tokens->all[6], NULL, 0);
            start1 = (unsigned short) strtoul(tokens->all[7], NULL, 0);
            end1   = (unsigned short) strtoul(tokens->all[8], NULL, 0);
            lf1    = (float) (end1 - start1 + 1) / len1;

            if(lf1 >= minLf1) {
                len2   = (unsigned short) strtoul(tokens->all[10], NULL, 0);
                start2 = (unsigned short) strtoul(tokens->all[11], NULL, 0);
                end2   = (unsigned short) strtoul(tokens->all[12], NULL, 0);
                lf2    = (float) (end2 - start2 + 1) / len2;

                if(lf2 >= minLf2) {
                    /*
                     * don't store edits as my LIST objects, since those store an array of
                     * pointers to NULL, which will be bigger than an array of short integers
                     * (eight bytes per element rather than two on a 64bit OS)
                     */

                    if((editStrings1 = stringSplit(tokens->all[9],  ",", NULL)) == NULL) return NULL;
                    if((editStrings2 = stringSplit(tokens->all[13], ",", NULL)) == NULL) return NULL;

                    /*
                     * FIXME - take in to account N and C-terminal
                     * overhang to fix start and end positions
                     */

                    hsp = hspCreate(
                                    start1,
                                    end1,
                                    len1,
                                    editStrings1->n,
                                    start2,
                                    end2,
                                    len2,
                                    editStrings2->n,
                                    0,
                                    (unsigned char) pcid,
                                    eValue,
                                    editStrings1,
                                    editStrings2
                                    );
                    *idSeq1 = stringCopy(tokens->all[4]);
                    *idSeq2 = stringCopy(tokens->all[5]);

                    free(editStrings1->all[0]); // subsequent elements are just pointers in to a block of memory from the same malloc
                    listDelete(editStrings1, NULL);
                    free(editStrings2->all[0]); // subsequent elements are just pointers in to a block of memory from the same malloc
                    listDelete(editStrings2, NULL);
                }
            }
        }
        free(tokens->all[0]); // subsequent elements are just pointers in to a block of memory from the same malloc
        listDelete(tokens, NULL);
    }

    return hsp;
}

HASH *hspParse(char *fileName, float minPcid, float minLf1, float minLf2, int (*hspSave)(HASH *, char *, char *, HSP *)) {
    MYFILE         *file;
    HASH           *hsps; // hash of hashes for all hsps, keyed by idSeq1 and idSeq2
    char           *line;
    HSP            *hsp;
    char           *idSeq1, *idSeq2;

    if((file = myFileOpen(fileName)) == NULL)
        return NULL;

    if((hsps = hashCreate(0)) == NULL)
        return NULL;

    line = (*file->nextLine)(file);
    while(line != NULL) {
        if((hsp = hspParseLine(line, minPcid, minLf1, minLf2, &idSeq1, &idSeq2)) != NULL) {
            (*hspSave)(hsps, idSeq1, idSeq2, hsp);
            free(idSeq1);
            free(idSeq2);
        }
        line = (*file->nextLine)(file);
    }
    myFileDelete(file);
    hashResize(hsps, hsps->nKeys * 4 / 3);

    return hsps;
}

int hspOutput(HASH *hsps, FILE *fh) {
    LIST       *keys, *keys1;
    int        i, j, k;
    char       *idSeq1, *idSeq2;
    HASH       *hsps1;
    LIST       *hsps12;
    ALIGNMENT  *aln;

    fprintf(fh, "hsps->nKeys = %d\n", hsps->nKeys);
    if((keys = hashGetAllKeys(hsps)) == NULL) return 1;
    for(i = 0; i < hsps->nKeys; i++) {
        idSeq1 = keys->all[i];
        if((hsps1 = (HASH *) hashGetElement(hsps, idSeq1)) != NULL) { 
            if((keys1 = hashGetAllKeys(hsps1)) == NULL) continue;
            for(j = 0; j < keys1->n; j++) {
                idSeq2 = keys1->all[j];
                if((hsps12 = (LIST *) hashGetElement(hsps1, idSeq2)) != NULL) {
                    for(k = 0; k < hsps12->n; k++) {
                        aln = (ALIGNMENT *) hsps12->all[k];
                        fprintf(fh, "%s\t%s\t%.2f\t%d\t%d\t%d\n", idSeq1, idSeq2, (float) aln->pcid, i, j, k);
                    }
                }
            }
            listDelete(keys1, NULL);
        }
    }
    listDelete(keys, NULL);

    return 0;
}

int hspListDelete(void *thing) {
    KEYVALUEPAIR *kvp;

    kvp = (KEYVALUEPAIR *) thing;
    free(kvp->key);
    listDelete(kvp->value, hspDelete);
    free(kvp);

    return 0;
}

int hspsDelete(void *thing) {
    KEYVALUEPAIR *kvp;

    kvp = (KEYVALUEPAIR *) thing;
    free(kvp->key);
    hashDelete(kvp->value, hspListDelete);
    free(kvp);

    return 0;
}

//LIST *seqGroupByHsps(LIST *seqIds, HASH *hsps, float minPcid, float minLf, unsigned int *idGroup) {
LIST *hspGroupSeqs(LIST *seqIds, HASH *hsps, float minPcid, float minLf, unsigned int *idGroup) {
    LIST          *groups;
    unsigned int  i, j;
    HASH          *visited;
    LIST          *queue;
    LIST          *members;
    char          *idSeq1, *idSeq2;
    HASH          *hsps1;
    LIST          *keys1;
    LIST          *hsps12;
    int           seen     = 1;
    int           finished = 2;
    HSP           *hsp;
    float         lf1, lf2;

    if((groups = listCreate(NULL)) == NULL) return NULL;
    if((visited = hashCreate(seqIds->n)) == NULL) return NULL;
    if((queue = listCreate(NULL)) == NULL) return NULL;
    for(i = 0; i < seqIds->n; i++) {
        idSeq1 = (char *) seqIds->all[i];
        if(hashGetElement(visited, idSeq1) != NULL) continue;
        hashAddElement(visited, idSeq1, &seen);
        if((members = listCreate(NULL)) == NULL) continue;
        while(idSeq1 != NULL) {
            listAddElement(members, 1, idSeq1);
            if((hsps1 = (HASH *) hashGetElement(hsps, idSeq1)) != NULL) {
                if((keys1 = hashGetAllKeys(hsps1)) == NULL) continue;
                for(j = 0; j < keys1->n; j++) {
                    idSeq2 = keys1->all[j];
                    if(hashGetElement(visited, idSeq2) == NULL) {
                        if((hsps12 = (LIST *) hashGetElement(hsps1, idSeq2)) != NULL) {
                            if(hsps12->n > 1) listSort(hsps12, hspSortByEvalue);
                            hsp = (HSP *) hsps12->all[0];
                            if(hsp->pcid >= minPcid) {
                                if((lf1 = (float) (hsp->end1 - hsp->start1 + 1) / hsp->seqLen1) < minLf) continue;
                                if((lf2 = (float) (hsp->end2 - hsp->start2 + 2) / hsp->seqLen2) < minLf) continue;

                                listAddElement(queue, 1, idSeq2);
                                hashAddElement(visited, idSeq2, &seen);
                            }
                        }
                    }
                }
                listDelete(keys1, NULL);
                hashAddElement(visited, idSeq1, &finished);
            }
            idSeq1 = listShift(queue);
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
    hashDelete(visited, NULL);

    return groups;
}

unsigned short posFromMapping(unsigned short **mapping, unsigned short idx, unsigned short pos) {
    return mapping[idx][pos];
}

unsigned short posPassThrough(unsigned short **mapping, unsigned short idx, unsigned short pos) {
    return pos;
}

