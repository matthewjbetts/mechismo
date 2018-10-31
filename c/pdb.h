#if !defined(PDB_H)
#define PDB_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include "myFile.h"
#include "spatialPartition.h"
#include "sphere.h"
#include "list.h"
#include "strings.h"
#include "maths.h"

#define MAX_SEQ_LEN 100000
#define ANGLE 0.942477
#define DISTANCE 1.54
#define A3TO1_ACIDS3 "ALA ARG ASN ASP CYS GLN GLU GLY HIS ILE LEU LYS MET PHE PRO SER THR TRP TYR VAL ASX GLX UNK CYH HET"
#define A3TO1_ACIDS1 "ARNDCQEGHILKMFPSTWYVBZXch"
#define AA1A "A_CDEFGHI_KLMN_PQRST_VW_Y_"
#define DOMIDLEN 100

#define	MAXSTANDARDRES   30
#define	MAXSTANDARDATOMS 17

// bit-masks for different atom classes
#define SIDECHAIN         1
#define HBOND_DONOR       2
#define HBOND_ACCEPTOR    4
#define SALT              8
#define RES_END          16

// bit-mask combinations of atom classes for convenience below
// FIXME - can I make these local to this file only?
#define MC               0
#define MCHD             HBOND_DONOR
#define MCHA             HBOND_ACCEPTOR
#define SC               SIDECHAIN
#define SCHA             SIDECHAIN + HBOND_ACCEPTOR
#define SCHAE            SIDECHAIN + HBOND_ACCEPTOR + RES_END
#define SCHASE           SIDECHAIN + HBOND_ACCEPTOR + SALT + RES_END
#define SCHD             SIDECHAIN + HBOND_DONOR
#define SCHDE            SIDECHAIN + HBOND_DONOR + RES_END
#define SCHDS            SIDECHAIN + HBOND_DONOR + SALT
#define SCHDSE           SIDECHAIN + HBOND_DONOR + SALT + RES_END
#define SCHAD            SIDECHAIN + HBOND_ACCEPTOR + HBOND_DONOR
#define SCHADE           SIDECHAIN + HBOND_ACCEPTOR + HBOND_DONOR + RES_END
#define SCE              SIDECHAIN + RES_END

typedef	struct resAtoms {
    char          fullName[20];
    char          threeCode[4];
    char          oneCode;
    int           idx;
    int           idx_unmod; // index in the array of the unmodified equivalent of this residue
    int	          atomCount;
    char          atomTypes[MAXSTANDARDATOMS][4];
    unsigned char atomClasses[MAXSTANDARDATOMS];
} RESATOMS;

// WARNING - be careful with idx and idx_unmod when editing this file

extern const RESATOMS standardRes[MAXSTANDARDRES];

typedef struct brookn {
    char chain;
    int  resSeq;
    char iCode;
} BROOKN;

typedef struct assembly {
    int               id;
    LIST              *models;
    SPATIAL_PARTITION *grid;
    SPHERE            sphere; // bounding sphere
    float             rMaxModel; // maximum radius of all models in this assembly
    float             minCoord[3];
    float             maxCoord[3];
} ASSEMBLY;

typedef struct model {
    int               id;
    LIST              *domains;
    SPATIAL_PARTITION *grid;
    SPHERE            sphere; // bounding sphere
    ASSEMBLY          *assembly;
    float             rMaxDomain; // maximum radius of all domains in this model
    float             minCoord[3];
    float             maxCoord[3];
} MODEL;

typedef struct domain_loc { /* This structure allows rather complex domains to be described */
    char              filename[FILENAMELEN];
    char              id[DOMIDLEN];
    ASSEMBLY          *assembly; // for dealing with biounit assemblies
    MODEL             *model;
    int               nobj;     /* The number of objects considered within the named file */
    int               *type;    /* The type that each object is:
                                   0 ==> an error
                                   1 ==> All of the residues in the file
                                   2 ==> A particular chain
                                   3 ==> A particular named region (eg. A 25 _ to B 10 _ ) */
    BROOKN            *start;   /* There will be a start and end for each 'object' */
    BROOKN            *end;
    int               *reverse; /* if 1, then reverse invert the object N to C */
    char              *aa;
    char              *align;
    char              *oldalign;
    char              *sec;
    BROOKN            *numb;
    int               *use;
    float             **R;      /* Initial transformation */
    float             *V;
    float             **r;      /* current transformation, when STAMP is done, we must update(r,v,R,V) to get the final transformation */
    float             *v;
    float             value;
    LIST              *residues;
    SPATIAL_PARTITION *grid;
    int               n_res;
    int               n_atoms; // counter of atoms for convenience (could be found by looping through residues->all...)
    SPHERE            sphere; // bounding sphere
    float             rMaxResidue; // maximum radius of all residues in this domain
    float             minCoord[3];
    float             maxCoord[3];
} DOMAIN_LOC;

typedef struct residue {
    unsigned short    pos; // 1 + index in the list of residues, i.e. sequence position
    char              chain;
    int               resSeq;
    char              iCode;
    char              resName[4];
    char              aa;
    BROOKN            pdbnum;
    LIST              *atoms;
    SPATIAL_PARTITION *grid;
    SPHERE            sphere; // bounding sphere
    float             minCoord[3];
    float             maxCoord[3];
    DOMAIN_LOC        *domain;
} RESIDUE;

typedef struct atom {
    char    name[5];
    SPHERE  sphere;
    RESIDUE *residue;
} ATOM;

SPHERE *domainSphere(void *thing);
SPHERE *residueSphere(void *thing);

typedef struct domain_to_frag {
    int        id_frag; // all id_domains with the same id_frag are instances of the same domain, eg. in biounit
    char       id_domain[DOMIDLEN];
    DOMAIN_LOC *domain;
    int        assembly;
    int        model;
} DOMAIN_TO_FRAG;

typedef struct domains_to_frags {
    DOMAIN_TO_FRAG **all;
    int            n;
    int            n_frags;
    int            n_assemblies;
    int            **frags_to_assemblies; // first element is id_frag, rest are ids of assemblies in which this frag has an instance
} DOMAINS_TO_FRAGS;

typedef struct atom_details {
    char **orders;
    int  **use;
    int *functional;
    int *functional_start;
    int *found;
} ATOM_DETAILS;

typedef struct rdist {
    int i, j;
    int ii, jj;
    float d;
} RDIST;

ATOM *atomCreate();
int atomDelete(void *thing);
int domainAddAtom(DOMAIN_LOC *domain, RESIDUE *residue, ATOM *atom);
ASSEMBLY *assemblyCreate(int id);
MODEL *modelCreate(int id);
int modelAddDomain(MODEL *model, DOMAIN_LOC *domain);
int assemblyAddModel(ASSEMBLY *assembly, MODEL *model);
RESIDUE *residueCreate(unsigned short pos);
int domainAddResidue(DOMAIN_LOC *domain, RESIDUE *residue);
int residueDelete(void *thing);
SPHERE *assemblySphere(void *thing);
SPHERE *modelSphere(void *thing);
SPHERE *domainSphere(void *thing);
SPHERE *residueSphere(void *thing);
SPHERE *atomSphere(void *thing);
int assemblyOutput(void *thing);
int modelOutput(void *thing);
int domainOutput(void *thing);
int residueOutput(void *thing);
int atomOutput(void *thing);
DOMAINS_TO_FRAGS *domainsToFragsCreate();
DOMAIN_TO_FRAG *domainToFragCreate();
int modelAddDomainsToFrags(DOMAINS_TO_FRAGS *ds2fs, DOMAIN_TO_FRAG *d2f);
int domainToFragDelete(DOMAIN_TO_FRAG *d2f);
int domainsToFragsDelete(DOMAINS_TO_FRAGS *ds2fs);
DOMAIN_LOC *domainCreate();
int domainDelete(void *thing);
int modelDelete(void *thing);
int assemblyDelete(void *thing);
void domainParseError(char *buff);
int domainParse(DOMAIN_LOC *domain, int *gottrans, FILE *INPUT);
int domainGetAllCoords(DOMAIN_LOC *domain, MYFILE *file);
int residueStandardOutput();
int domainCalcBoundingSpheres(DOMAIN_LOC *domain, float *rMaxAllResidues);
int domainParseAll(FILE *IN, LIST *domains, int *gottrans);
int domainsByAssembly(const void *a, const void *b);
LIST *assemblyParseAll(char fn[FILENAMELEN], LIST *domains, DOMAINS_TO_FRAGS **ds2fs);
int domainSortByPDBFile(const void *a, const void *b);

#endif
