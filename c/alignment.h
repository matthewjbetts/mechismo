#if !defined(ALIGNMENT_H)
#define ALIGNMENT_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "myFile.h"
#include "hash.h"
#include "strings.h"

typedef struct alignment {
    HASH          *aseqs;
    unsigned int  len;
    unsigned char pcid; // only really makes sense for pairwise alignments. value stored = pcid * 100

    // FIXME - need a hash table to store aligned sequences by their ids
} ALIGNMENT;

typedef struct alignedseq {
    char           *aseq;
    short          *edits;
    unsigned short start;
    unsigned short end;
    unsigned short seqLen;
    unsigned short nEdits;
} ALIGNEDSEQ;

typedef struct hsp {
    short          *edits;
    unsigned short start1;
    unsigned short end1;
    unsigned short seqLen1;
    unsigned short nEdits1;
    unsigned short start2;
    unsigned short end2;
    unsigned short seqLen2;
    unsigned short nEdits2;
    unsigned int   len;
    unsigned char  pcid;
    double         eValue;
} HSP;

ALIGNMENT *alignmentCreate();
ALIGNMENT *alignmentParseFasta(MYFILE *file);
int alignmentAddAseq(ALIGNMENT *aln, char *id, ALIGNEDSEQ *alnSeq);
ALIGNEDSEQ *alignmentGetAseq(ALIGNMENT *aln, char *id);
int alignmentDelete(void *thing);
int alignmentOutputFasta(ALIGNMENT *aln, FILE *fh);
ALIGNEDSEQ *alignedSeqCreate(unsigned short start, unsigned short end, unsigned short len, char *aseq);
float alignedSeqLengthFraction(ALIGNEDSEQ *aseq);
int alignedSeqDelete(void *thing);
unsigned short alignedSeqEditsStringToArray(short *edits, LIST *editStrings);
unsigned short **alignedSeqPosMapping(unsigned short seqLen, unsigned short start, short *edits, unsigned short nEdits, unsigned int alnLen);
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
               );
HSP *hspReverse(HSP *hsp);
int hspDelete(void *thing);
int hspSortByEvalue(const void *a, const void *b);
int hspSaveForward(HASH *hsps, char *idSeq1, char *idSeq2, HSP *hsp);
int hspSaveReverse(HASH *hsps, char *idSeq1, char *idSeq2, HSP *hsp);
int hspSaveBoth(HASH *hsps, char *idSeq1, char *idSeq2, HSP *hsp);
HSP *hspParseLine(char *line, float minPcid, float minLf1, float minLf2, char **idSeq1, char **idSeq2);
HASH *hspParse(char *fileName, float minPcid, float minLf1, float minLf2, int (*hspSave)(HASH *, char *idSeq1, char *idSeq2, HSP *));
int hspOutput(HASH *hsps, FILE *fh);
int hspsDelete(void *thing);
LIST *hspGroupSeqs(LIST *seqIds, HASH *hsps, float minPcid, float minLf, unsigned int *idGroup);
unsigned short posFromMapping(unsigned short **mapping, unsigned short idx, unsigned short pos);
unsigned short posPassThrough(unsigned short **mapping, unsigned short idx, unsigned short pos);

#endif
