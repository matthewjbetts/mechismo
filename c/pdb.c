#include "pdb.h"

const RESATOMS standardRes[MAXSTANDARDRES] = {
    {
        "Alanine\0", // fullName
        "ALA\0", // threeCode
        'A', // oneCode
        0, // idx
        0, // idx_unmod
        6, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SCE,    SC} // atomClasses
    },

    {
        "Arginine\0", // fullName
        "ARG\0", // threecode
        'R', // oneCode
        1, // idx
        1, // idx_unmod
        12, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD\0", "NE\0", "CZ\0", "NH1\0", "NH2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,     SCHD,      SC,   SCHDSE,  SCHDSE, SC} // atomClasses
    },

    {
        "Asparagine\0", // fullName
        "ASN\0", // threeCode
        'N', // oneCode
        2, // idx
        2, // idx_unmod
        11, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "OD1\0", "ND2\0", "AD1\0", "AD2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SCHAE,   SCHDE,   SCHADE,  SCHADE,  SC} // atomClasses
        /*
         * AD1 and AD2 are used in pdb files in place of OD1
         * and ND2 when those who solved the structure were
         * unable to say which atom is O and which is N.
         */
    },

    {
        "Aspartic acid\0", // fullName
        "ASP\0", // threeCode
        'D', // oneCode
        3, // idx
        3, // idx_unmod
        9, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "OD1\0", "OD2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SCHASE,  SCHASE,  SC} // atomClasses
    },

    {
        "Cysteine\0", // fullName
        "CYS\0", // threeCode
        'C', // oneCode
        4, // idx
        4, // idx_unmod
        7, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "SG\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SCHADE, SC} // atomClasses
    },

    {
        "Glutamine\0", // fullName
        "GLN\0", // threeCode
        'Q', // oneCode
        5, // idx
        5, // idx_unmod
        12, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD\0", "OE1\0", "NE2\0", "AE1\0", "AE2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,     SCHAE,   SCHDE,   SCHADE,  SCHADE,  SC} // atomClasses
        /*
         * AE1 and AE2 are used in pdb files in place of OE1
         * and NE2 when those who solved the structure were
         * unable to say which atom is O and which is N.
         */
    },

    {
        "Glutamic acid\0", // fullName
        "GLU\0", // threeCode
        'E', // oneCode
        6, // idx
        6, // idx_unmod
        10, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD\0", "OE1\0", "OE2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,     SCHASE,  SCHASE,  SC} // atomClasses
    },

    {
        "Glycine\0", // fullName
        "GLY\0", // threeCode
        'G', // oneCode
        7, // idx
        7, // idx_unmod
        5, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC} // atomClasses
    },

    {
        "Histidine\0", // fullName
        "HIS\0", // threeCode
        'H', // oneCode
        8, // idx
        8, // idx_unmod
        15, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "ND1\0", "CD2\0", "CE1\0", "NE2\0", "AD1\0", "AD2\0", "AE1\0", "AE2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SCHAD,    SC,      SC,     SCHADE,  SCHAD,   SCHADE,  SCHAD,   SCHADE,  SC} // atomClasses
    },

    {
        "Isoleucine\0", // fullName
        "ILE\0", // threeCode
        'I', // oneCode
        9, // idx
        9, // idx_unmod
        9, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG1\0", "CG2\0", "CD1\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,      SC,      SCE,     SC} // atomClasses
    },

    {
        "Leucine\0", // fullName
        "LEU\0", // threeCode
        'L', // oneCode
        10, // idx
        10, // idx_unmod
        10, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD1\0", "CD2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SCE,     SCE,     SC} // atomClasses
    },

    {
        "Lysine\0", // fullName
        "LYS\0", // threeCode
        'K', // oneCode
        11, // idx
        11, // idx_unmod
        10, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD\0", "CE\0", "NZ\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,     SC,     SCHDSE, SC} // atomClasses
    },

        {
        "Acetyllysine\0", // fullName
        "ALY\0", // threeCode
        'K', // oneCode
        12, // idx
        11, // idx_unmod
        13, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD\0", "CE\0", "NZ\0", "CH3\0", "CH\0", "OH\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,     SC,     SCHDS,  SCE,     SC,     SCHADE, SC} // atomClasses
    },

    {
        "Methionine\0", // fullName
        "MET\0", // threeCode
        'M', // oneCode
        13, // idx
        13, // idx_unmod
        9, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "SD\0", "CE\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,     SCE,    SC} // atomClasses
    },

    {
        "Phenylalanine\0", // fullName
        "PHE\0", // threeCode
        'F', // oneCode
        14, // idx
        14, // idx_unmod
        12, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD1\0", "CD2\0", "CE1\0", "CE2\0", "CZ\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,      SC,      SC,      SC,      SCE,    SC} // atomClasses
    },

    {
        "Proline\0", // fullName
        "PRO\0", // threeCode
        'P', // oneCode
        15, // idx
        15, // idx_unmod
        8, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SCE,     SC,    SC} // atomClasses
    },

    {
        "Serine\0", // fullName
        "SER\0", // threeCode
        'S', // oneCode
        16, // idx
        16, // idx_unmod
        7, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "OG\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SCHADE, SC} // atomClasses
    },

    {
        "Phosphoserine\0", // fullName
        "SEP\0", // threeCode
        'S', // oneCode
        17, // idx
        16, // idx_unmod
        11, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "OG\0", "P\0", "O1P\0", "O2P\0", "O3P\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SCHA,   SC,    SCHAE,   SCHAE,   SCHAE,   SC} // atomClasses
    },

    {
        "Threonine\0", // fullName
        "THR\0", // threeCode
        'T', // oneCode
        18, // idx
        18, // idx_unmod
        8, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "OG1\0", "CG2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SCHADE,  SCE,     SC} // atomClasses
    },

    {
        "Phosphothreonine\0", // fullName
        "TPO\0", // threeCode
        'T', // oneCode
        19, // idx
        18, // idx_unmod
        12, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "OG1\0", "CG2\0", "P\0", "O1P\0", "O2P\0", "O3P\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SCHA,    SC,       SC,   SCHAE,   SCHAE,   SCHAE,   SC} // atomClasses
    },

    {
        "Tryptophan\0", // fullName
        "TRP\0", // threeCode
        'W', // oneCode
        20, // idx
        20, // idx_unmod
        15, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD1\0", "CD2\0", "NE1\0", "CE2\0", "CE3\0", "CZ2\0", "CZ3\0", "CH2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,      SC,      SCHD,    SC,      SC,      SC,      SC,      SCE,     SC} // atomClasses
    },

    {
        "Tyrosine\0", // fullName
        "TYR\0", // threeCode
        'Y', // oneCode
        21, // idx
        21, // idx_unmod
        13, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD1\0", "CD2\0", "CE1\0", "CE2\0", "CZ\0", "OH\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,      SC,      SC,      SC,      SC,     SCHADE, SC} // atomClasses
    },

    {
        "Phosphotyrosine\0", // fullName
        "PTR\0", // threeCode
        'Y', // oneCode
        22, // idx
        21, // idx_unmod
        17, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD1\0", "CD2\0", "CE1\0", "CE2\0", "CZ\0", "OH\0", "P\0", "O1P\0", "O2P\0", "O3P\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,      SC,      SC,      SC,      SC,     SCHA,   SC,    SCHAE,   SCHAE,   SCHAE,   SC} // atomClasses
    },

    {
        "Valine\0", // fullName
        "VAL\0", // threeCode
        'V', // oneCode
        23, // idx
        23, // idx_unmod
        8, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG1\0", "CG2\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SCE,     SCE,     SC} // atomClasses
    },

    {
        "\0", // fullName
        "PCA\0", // threeCode
        'X', // oneCode
        24, // idx
        24, // idx_unmod
        8, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD\0", "OE\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,     SC} // atomClasses
    },

    {
        "Acetic acid\0", // fullName
        "ACE\0", // threeCode
        'X', // oneCode
        25, // idx
        25, // idx_unmod
        3, // atomCount
        {"C\0", "O\0", "CH3\0"}, // atomTypes
        {MC,    MC,    MC} // atomClasses
    },

    {
        "Formic acid\0", // fullName
        "FOR\0", // threeCode
        'X', // oneCode
        26, // idx
        26, // idx_unmod
        2, // atomCount
        {"C\0", "O\0"}, // atomTypes
        {0,     0} // atomClasses
    },

    {
        "ASP/ASN\0", // fullName
        "ASX\0", // threeCode
        'B', // oneCode
        27, // idx
        27, // idx_unmod
        8, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "AD1\0", "AD2\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,      SC} // atomClasses
    },

    {
        "GLU/GLN\0", // fullName
        "GLX\0", // threeCode
        'Z', // oneCode
        28, // idx
        28, // idx_unmod
        9, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "CG\0", "CD\0", "AE1\0", "AE2\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SC,     SC,     SC,      SC} // atomClasses
    },

    {
        "Unknown\0", // fullName
        "UNK\0", // threeCode
        'X', // oneCode
        29, // idx
        29, // idx_unmod
        7, // atomCount
        {"N\0", "CA\0", "C\0", "O\0", "CB\0", "UNK\0", "OXT\0"}, // atomTypes
        {MCHD,  MC,     MC,    MCHA,  SC,     SCE,      SC} // atomClasses
    },
};

ATOM *atomCreate() {
    ATOM *atom;

    atom = (ATOM *) malloc(sizeof(ATOM));
    if(atom == NULL) {
        fprintf(stderr, "Error: atomCreate: malloc failed.\n");
        return NULL;
    }
    memset(atom->name, '\0', 5);
    atom->sphere.centre[0] = 0;
    atom->sphere.centre[1] = 0;
    atom->sphere.centre[2] = 0;
    atom->sphere.r = 0.0;
    atom->residue = NULL;

    return atom;
};

int atomDelete(void *thing) {
    ATOM *atom;

    atom = (ATOM *) thing;
    free(atom);

    return 0;
}

int domainAddAtom(DOMAIN_LOC *domain, RESIDUE *residue, ATOM *atom) {
    if(listAddElement(residue->atoms, 1, atom) == 0) {
        atom->residue = residue;
        domain->n_atoms++;
        return 0;
    }

    return 1;
}

ASSEMBLY *assemblyCreate(int id) {
    ASSEMBLY *assembly;

    assembly = (ASSEMBLY *) malloc(sizeof(ASSEMBLY));
    if(assembly == NULL) {
        fprintf(stderr, "Error: assemblyCreate: malloc failed.\n");
        return NULL;
    }
    assembly->id = id;
    assembly->models = listCreate("models");
    assembly->grid = NULL;
    assembly->sphere.centre[0] = 0.0;
    assembly->sphere.centre[1] = 0.0;
    assembly->sphere.centre[2] = 0.0;
    assembly->sphere.r = 0.0;
    assembly->rMaxModel = 0.0;
    assembly->minCoord[0] = 99999999.0;
    assembly->minCoord[1] = 99999999.0;
    assembly->minCoord[2] = 99999999.0;
    assembly->maxCoord[0] = -99999999.0;
    assembly->maxCoord[1] = -99999999.0;
    assembly->maxCoord[2] = -99999999.0;

    return assembly;
}

MODEL *modelCreate(int id) {
    MODEL *model;

    model = (MODEL *) malloc(sizeof(MODEL));
    if(model == NULL) {
        fprintf(stderr, "Error: modelCreate: malloc failed.\n");
        return NULL;
    }
    model->id = id;
    model->domains = listCreate("domains");
    model->grid = NULL;
    model->sphere.centre[0] = 0.0;
    model->sphere.centre[1] = 0.0;
    model->sphere.centre[2] = 0.0;
    model->sphere.r = 0.0;
    model->rMaxDomain = 0.0;
    model->minCoord[0] = 99999999.0;
    model->minCoord[1] = 99999999.0;
    model->minCoord[2] = 99999999.0;
    model->maxCoord[0] = -99999999.0;
    model->maxCoord[1] = -99999999.0;
    model->maxCoord[2] = -99999999.0;
    model->assembly = NULL;

    return model;
}

int modelAddDomain(MODEL *model, DOMAIN_LOC *domain) {
    listAddElement(model->domains, 1, domain);

    return 0;
}

int assemblyAddModel(ASSEMBLY *assembly, MODEL *model) {
    model->assembly = assembly;
    listAddElement(assembly->models, 1, model);

    return 0;
}

RESIDUE *residueCreate(unsigned short pos) {
    RESIDUE *residue;

    residue = (RESIDUE *) malloc(sizeof(RESIDUE));
    if(residue == NULL) {
        fprintf(stderr, "Error: residueCreate: malloc failed.\n");
        return NULL;
    }
    residue->pos = pos;
    memset(residue->resName, '\0', 4);
    residue->atoms = listCreate("atoms");
    residue->grid = NULL;
    residue->sphere.centre[0] = 0;
    residue->sphere.centre[1] = 0;
    residue->sphere.centre[2] = 0;
    residue->sphere.r = 0.0;
    residue->minCoord[0] = 99999999.0;
    residue->minCoord[1] = 99999999.0;
    residue->minCoord[2] = 99999999.0;
    residue->maxCoord[0] = -99999999.0;
    residue->maxCoord[1] = -99999999.0;
    residue->maxCoord[2] = -99999999.0;
    residue->domain = NULL;

    return residue;
};

int domainAddResidue(DOMAIN_LOC *domain, RESIDUE *residue) {
    //printf("%c %d %c\n", residue->chain, residue->resSeq, residue->iCode);

    if(listAddElement(domain->residues, 1, residue) == 0) {
        residue->domain = domain;
        domain->n_res++;
        return 0;
    }

    return 1;
}

int residueDelete(void *thing) {
    RESIDUE *residue;

    residue = (RESIDUE *) thing;
    listDelete(residue->atoms, atomDelete);
    if(residue->grid != NULL)
        spatialPartitionDelete(residue->grid);
    free(residue);

    return 0;
}

SPHERE *assemblySphere(void *thing) {
    ASSEMBLY *assembly;

    assembly = (ASSEMBLY *) thing;

    return &(assembly->sphere);
}

SPHERE *modelSphere(void *thing) {
    MODEL *model;

    model = (MODEL *) thing;

    return &(model->sphere);
}

SPHERE *domainSphere(void *thing) {
    DOMAIN_LOC *domain;

    domain = (DOMAIN_LOC *) thing;

    return &(domain->sphere);
}

SPHERE *residueSphere(void *thing) {
    RESIDUE *residue;

    residue = (RESIDUE *) thing;

    return &(residue->sphere);
}

SPHERE *atomSphere(void *thing) {
    ATOM *atom;

    atom = (ATOM *) thing;

    return &(atom->sphere);
}

int assemblyOutput(void *thing) {
    ASSEMBLY *assembly;

    assembly = (ASSEMBLY *) thing;

    printf("ASSEMBLY\t%d\n", assembly->id);

    return 1;
}

int modelOutput(void *thing) {
    MODEL *model;

    model = (MODEL *) thing;

    printf("MODEL\t%d\n", model->id);

    return 1;
}

int domainOutput(void *thing) {
    DOMAIN_LOC *domain;

    domain = (DOMAIN_LOC *) thing;

    printf(
           "DOMAIN\t%s\t[%10.6f, %10.6f, %10.6f] %10.6f\n",
           domain->id,
           domain->sphere.centre[0],
           domain->sphere.centre[1],
           domain->sphere.centre[2],
           domain->sphere.r
           );

    return 0;
}

int residueOutput(void *thing) {
    RESIDUE *residue;

    residue = (RESIDUE *) thing;

    printf("RESIDUE '%c%d%c'\n", residue->chain, residue->resSeq, residue->iCode);

    return 0;
}

int atomOutput(void *thing) {
    ATOM *atom;

    atom = (ATOM *) thing;

    printf("ATOM '%s'\n", atom->name);

    return 0;
}

DOMAINS_TO_FRAGS *domainsToFragsCreate() {
    DOMAINS_TO_FRAGS *ds2fs;

    ds2fs = (DOMAINS_TO_FRAGS *) malloc(sizeof(DOMAINS_TO_FRAGS));
    if(ds2fs == NULL) {
        fprintf(stderr, "Error: domainsToFragsCreate: malloc failed.\n");
        return NULL;
    }

    ds2fs->all = (DOMAIN_TO_FRAG **) malloc(sizeof(DOMAIN_TO_FRAG *));
    if(ds2fs->all == NULL) {
        fprintf(stderr, "Error: domainCreates: malloc failed.\n");
        return NULL;
    }

    ds2fs->n = 0;

    ds2fs->frags_to_assemblies = (int **) malloc(sizeof(int *));
    if(ds2fs->frags_to_assemblies == NULL) {
        fprintf(stderr, "Error: domainCreates: malloc failed.\n");
        return NULL;
    }

    ds2fs->n_frags = 0;
    ds2fs->n_assemblies = 0;

    return ds2fs;
}

DOMAIN_TO_FRAG *domainToFragCreate() {
    DOMAIN_TO_FRAG *d2f;

    d2f = (DOMAIN_TO_FRAG *) malloc(sizeof(DOMAIN_TO_FRAG));
    if(d2f == NULL) {
        fprintf(stderr, "Error: domainToFragCreate: malloc failed.\n");
        return NULL;
    }
    d2f->id_frag = 0;
    memset(d2f->id_domain, '\0', DOMIDLEN);
    d2f->domain = NULL;
    d2f->assembly = 0;
    d2f->model = 0;

    return d2f;
}

int modelAddDomainsToFrags(DOMAINS_TO_FRAGS *ds2fs, DOMAIN_TO_FRAG *d2f) {
    int i;

    i = ds2fs->n++;
    ds2fs->all = (DOMAIN_TO_FRAG **) realloc(ds2fs->all, ds2fs->n * sizeof(DOMAIN_TO_FRAG *));
    if(ds2fs->all == NULL) {
        fprintf(stderr, "Error: modelAddDomainsToFrags: realloc failed\n");
        return 1;
    }
    ds2fs->all[i] = d2f;

    return 0;
}

int domainToFragDelete(DOMAIN_TO_FRAG *d2f) {
    free(d2f);

    return 1;
}

int domainsToFragsDelete(DOMAINS_TO_FRAGS *ds2fs) {
    int i;

    for(i = 0; i < ds2fs->n; i++) {
        domainToFragDelete(ds2fs->all[i]);
    }
    free(ds2fs->all);
    for(i = 0; i < ds2fs->n_frags; i++) {
        free(ds2fs->frags_to_assemblies[i]);
    }
    free(ds2fs->frags_to_assemblies);
    free(ds2fs);

    return 1;
}

int ds2fsByFrag(const void *a, const void *b) {
    const DOMAIN_TO_FRAG *d2f_a = *(const DOMAIN_TO_FRAG **) a;
    const DOMAIN_TO_FRAG *d2f_b = *(const DOMAIN_TO_FRAG **) b;

    if(d2f_a->id_frag < d2f_b->id_frag)
        return -1;
    else if(d2f_a->id_frag > d2f_b->id_frag)
        return 1;
    else
        return 0;

    return 0;
}

int findFragsToAssemblies(DOMAINS_TO_FRAGS *ds2fs) {
    int            i, j, k;
    DOMAIN_TO_FRAG *d2f;
    int            id_frag_p;

    qsort((const DOMAIN_TO_FRAG **) ds2fs->all, ds2fs->n, sizeof(DOMAIN_TO_FRAG *), ds2fsByFrag);
    id_frag_p = -1;
    j = -1;
    for(i = 0; i < ds2fs->n; i++) {
        d2f = ds2fs->all[i];
        if(d2f->id_frag != id_frag_p) {
            j = ds2fs->n_frags++;
            ds2fs->frags_to_assemblies = (int **) realloc(ds2fs->frags_to_assemblies, ds2fs->n_frags * sizeof(int *));
            if(ds2fs->frags_to_assemblies == NULL) {
                fprintf(stderr, "Error: findFragsToAssemblies: realloc failed.\n");
                return 1;
            }

            ds2fs->frags_to_assemblies[j] = (int *) malloc(ds2fs->n_assemblies * sizeof(int *));
            if(ds2fs->frags_to_assemblies[j] == NULL) {
                fprintf(stderr, "Error: findFragsToAssemblies: malloc failed.\n");
                return 1;
            }
            ds2fs->frags_to_assemblies[j][0] = d2f->id_frag;
            for(k = 1; k <= ds2fs->n_assemblies; ++k) {
                ds2fs->frags_to_assemblies[j][k] = 0;
            }
        }
        ds2fs->frags_to_assemblies[j][d2f->assembly + 1]++;

        id_frag_p = d2f->id_frag;
    }

    /*
    for(i = 0; i < ds2fs->n_frags; ++i) {
        printf("FRAGS_TO_ASSEMBLIES %d", ds2fs->frags_to_assemblies[i][0]);
        for(j = 1; j <= ds2fs->n_assemblies; ++j) {
            printf(" %d", ds2fs->frags_to_assemblies[i][j]);
        }
        printf("\n");
    }
    */

    return 0;
}

DOMAIN_LOC *domainCreate() {
    DOMAIN_LOC *domain;
    int        i;

    domain = (DOMAIN_LOC *) malloc(sizeof(DOMAIN_LOC));
    if(domain == NULL) {
        fprintf(stderr, "Error: domainCreate: malloc failed.\n");
        return NULL;
    }
    memset(domain->filename, '\0', FILENAMELEN);
    domain->residues = listCreate("residues");
    domain->grid = NULL;
    domain->sphere.centre[0] = 0;
    domain->sphere.centre[1] = 0;
    domain->sphere.centre[2] = 0;
    domain->sphere.r = 0.0;
    domain->rMaxResidue = 0.0;
    domain->minCoord[0] = 99999999.0;
    domain->minCoord[1] = 99999999.0;
    domain->minCoord[2] = 99999999.0;
    domain->maxCoord[0] = -99999999.0;
    domain->maxCoord[1] = -99999999.0;
    domain->maxCoord[2] = -99999999.0;
    domain->n_res = 0;
    domain->n_atoms = 0;
    domain->assembly = NULL;
    domain->model = NULL;

    domain->reverse = (int *) malloc(sizeof(int));
    if(domain->reverse == NULL) {
        fprintf(stderr, "Error: domainCreate: malloc failed for domain->reverse.\n");
        return NULL;
    }

    domain->type = (int *) malloc(sizeof(int));
    if(domain->type == NULL) {
        fprintf(stderr, "Error: domainCreate: malloc failed for domain->type.\n");
        return NULL;
    }

    domain->start = (BROOKN *) malloc(sizeof(BROOKN));
    if(domain->start == NULL) {
        fprintf(stderr, "Error: domainCreate: malloc failed for domain->start.\n");
        return NULL;
    }

    domain->end = (BROOKN *) malloc(sizeof(BROOKN)); 
    if(domain->end == NULL) {
        fprintf(stderr, "Error: domainCreate: malloc failed for domain->end.\n");
        return NULL;
    }

    domain->V = (float *) malloc(3 * sizeof(float));
    if(domain->V == NULL) {
        fprintf(stderr, "Error: domainCreate: malloc failed for domain->V.\n");
        return NULL;
    }

    domain->v = (float *) malloc(3 * sizeof(float));
    if(domain->v == NULL) {
        fprintf(stderr, "Error: domainCreate: malloc failed for domain->v.\n");
        return NULL;
    }

    domain->R = (float **) malloc(3 * sizeof(float *));
    if(domain->R == NULL) {
        fprintf(stderr, "Error: domainCreate: malloc failed for domain->R.\n");
        return NULL;
    }

    domain->r = (float **) malloc(3 * sizeof(float *));
    if(domain->r == NULL) {
        fprintf(stderr, "Error: domainCreate: malloc failed for domain->r.\n");
        return NULL;
    }

    for(i = 0; i < 3; ++i) {
        domain->R[i] = (float *) malloc(3 * sizeof(float));
        if(domain->R[i] == NULL) {
            fprintf(stderr, "Error: domainCreate: malloc failed for domain->R[i].\n");
            return NULL;
        }

        domain->r[i] = (float *) malloc(3 * sizeof(float));
        if(domain->r[i] == NULL) {
            fprintf(stderr, "Error: domainCreate: malloc failed for domain->r[i].\n");
            return NULL;
        }
    }

    return domain;
}

int domainDelete(void *thing) {
    DOMAIN_LOC *domain;
    int        i;

    domain = (DOMAIN_LOC *) thing;
    free(domain->reverse);
    free(domain->type);
    free(domain->start);
    free(domain->end);
    free(domain->V);
    free(domain->v);
    for(i = 0; i < 3; ++i) {
        free(domain->R[i]);
        free(domain->r[i]);
    }
    free(domain->R);
    free(domain->r);
    listDelete(domain->residues, residueDelete);
    if(domain->grid != NULL)
        spatialPartitionDelete(domain->grid);
    free(domain);

    return 0;
}

int modelDelete(void *thing) {
    MODEL *model;

    model = (MODEL *) thing;

    listDelete(model->domains, domainDelete);

    if(model->grid != NULL)
        spatialPartitionDelete(model->grid);

    free(model);

    return 1;
}

int assemblyDelete(void *thing) {
    ASSEMBLY *assembly;

    assembly = (ASSEMBLY *) thing;

    listDelete(assembly->models, modelDelete);

    if(assembly->grid != NULL)
        spatialPartitionDelete(assembly->grid);

    free(assembly);

    return 1;
}

void domainParseError(char *buff) {
    fprintf(stderr, "error in domain descriptors\n");
    fprintf(stderr, "Last domain read:\n'%s'\n", buff);
    exit(-1);
}

int domainParse(DOMAIN_LOC *domain, int *gottrans, FILE *INPUT) {
    int i, j;
    int nobjects;
    int pt;
    int indom;

    char *descriptor;
    char *buff, *guff;
	
    FILE *TEST;

    buff = (char *) malloc(2000 * sizeof(char));
    if(buff == NULL) {
        fprintf(stderr, "Error: domainParse: malloc failed for buff.\n");
        return 1;
    }

    guff = (char *) malloc(2000 * sizeof(char));
    if(guff == NULL) {
        fprintf(stderr, "Error: domainParse: malloc failed for guff.\n");
        return 1;
    }

    descriptor = (char *) malloc(2000 * sizeof(char));
    if(descriptor == NULL) {
        fprintf(stderr, "Error: domainParse: malloc failed for descriptor.\n");
        return 1;
    }

    (*gottrans) = 0;
    
    /* Now then, the best way to do this is to skip the comments, and
     * then just read in a buff starting after the last newline, and
     * ending at the end brace */
    indom = 0;
    buff[0] = '\0';
    while(fgets(guff, 1999, INPUT) != NULL) {
        if((guff[0] != '%') && (guff[0] != '#')) {
            if(strstr(guff,"{") != NULL)
                indom = 1;

            if(indom)
                sprintf(&buff[strlen(buff)], "%s", guff);
            
            if(strstr(guff, "}") != NULL) {
                indom = 0;
                break;
            }
        }
    }
		 
    if(strlen(buff) > 0) {
        /* First read the file name */
        sscanf(buff, "%s", domain->filename); /* read the filename */
        pt = 0;
        if((pt = stringSkipToNonSpace(buff, pt)) == -1)
            domainParseError(buff);
        sscanf(&buff[pt], "%s", domain->id); /* read the identifier */
        /* printf("Read in file %s\n",domain->filename);  */

        if((TEST = fopen(domain->filename, "r")) == NULL) {
            fprintf(stderr, "Error: could not open '%s' file for reading.\n", domain->filename); 
            return -1;
        }
        else {
            fclose(TEST);
        }

        if((pt = stringSkipToNonSpace(buff, pt)) == -1)
            domainParseError(buff);

        /* copy the bit between the braces into the string called descriptor */
        i = 0; 
        while(buff[pt] != '{' && buff[pt] != '\n' && buff[pt] != '\0')
            pt++;

        if(buff[pt] == '\n' || buff[pt] == '\0')
            domainParseError(buff);
        pt++;

        if(buff[pt] == '\n' || buff[pt] == '\0')
            domainParseError(buff);

        j = 0;
        while(buff[pt] != '}' && buff[pt] != '\0') {
            if(buff[pt] == '\0')
                domainParseError(buff);
            descriptor[j] = buff[pt];
            pt++; 
            j++;
        }
        descriptor[j] = '\0';

        for(i = 0; i < 3; ++i) {
            for(j = 0; j < 3; ++j) {
                if(i == j)
                    domain->R[i][j] = domain->r[i][j] = 1.0;
                else
                    domain->R[i][j] = domain->r[i][j] = 0.0;
            }
            domain->V[i] = domain->v[i] = 0.0;
        }
    
        nobjects = 0;
        pt = 0;

        if(strlen(descriptor) == 0)
            domainParseError(buff);

        while(descriptor[pt] == ' ' && descriptor[pt] != '\0')
            pt++;

        if(descriptor[pt] == '\0' || descriptor[pt] == '}')
            domainParseError(buff);

        while(pt != -1 && descriptor[pt] != '\0' && descriptor[pt] != '\n') { /* read until end of string */
            if(strncmp(&descriptor[pt], "REVERSE", 7) == 0) { /* coordinates are to be reversed */
                domain->reverse[nobjects] = 1;
                pt = stringSkipToNonSpace(descriptor, pt);
            }
            else {
                domain->reverse[nobjects] = 0;
                /* don't skip over the text if the word "REVERSE" isn't there */
            }
            if(strncmp(&descriptor[pt], "ALL", 3) == 0) { /* want all the coordinates in the file */
                domain->type[nobjects] = 1;
                domain->start[nobjects].chain = domain->start[nobjects].iCode
                    = domain->end[nobjects].chain=domain->end[nobjects].iCode
                    = '?';
                domain->start[nobjects].resSeq = domain->end[nobjects].resSeq = 0;
                pt = stringSkipToNonSpace(descriptor, pt);
                nobjects++;
            }
            else if(strncmp(&descriptor[pt], "CHAIN", 5) == 0) { /* want specific chain only */
                domain->type[nobjects] = 2;
                if((pt = stringSkipToNonSpace(descriptor, pt)) == -1)
                    domainParseError(buff); /* no chain given */
                domain->start[nobjects].chain = domain->end[nobjects].chain = descriptor[pt];
                domain->start[nobjects].iCode = domain->end[nobjects].iCode = '?';
                domain->start[nobjects].resSeq = domain->end[nobjects].resSeq = 0;
                pt = stringSkipToNonSpace(descriptor,pt);
                nobjects++;
            }
            else { /* assume that otherwise a specific start and end will be provided */
                domain->type[nobjects] = 3;
                /* cid 1 */
                if(descriptor[pt] == '_')
                    domain->start[nobjects].chain = ' ';
                else
                    domain->start[nobjects].chain = descriptor[pt];

                if((pt = stringSkipToNonSpace(descriptor, pt)) == -1)
                    domainParseError(buff); 

                /* n 1 */
                sscanf(&descriptor[pt], "%d", &(domain->start[nobjects].resSeq));
                if((pt = stringSkipToNonSpace(descriptor, pt)) == -1)
                    domainParseError(buff); 

                /* ins 1 */
                if(descriptor[pt] == '_')
                    domain->start[nobjects].iCode = ' ';
                else
                    domain->start[nobjects].iCode = descriptor[pt];

                if((pt = stringSkipToNonSpace(descriptor,pt)) == -1)
                    domainParseError(buff); 

                /* skipping over 'to' */
                if(strncmp(&descriptor[pt], "to", 2) != 0)
                    if(strncmp(&descriptor[pt], "TO", 2) != 0)
                        domainParseError(buff);

                if((pt = stringSkipToNonSpace(descriptor,pt)) == -1)
                    domainParseError(buff); 

                /* cid 2 */
                if(descriptor[pt] == '_')
                    domain->end[nobjects].chain = ' ';
                else
                    domain->end[nobjects].chain = descriptor[pt];

                if((pt = stringSkipToNonSpace(descriptor, pt)) == -1)
                    domainParseError(buff); 

                /* n 2 */
                sscanf(&descriptor[pt], "%d", &(domain->end[nobjects].resSeq));
                if((pt = stringSkipToNonSpace(descriptor, pt)) ==-1)
                    domainParseError(buff); 

                /* ins 2 */
                if(descriptor[pt] == '_')
                    domain->end[nobjects].iCode = ' ';
                else
                    domain->end[nobjects].iCode = descriptor[pt];

                pt = stringSkipToNonSpace(descriptor,pt);
                nobjects++;
            }

            if(pt != -1 && descriptor[pt] == '\n')
                break;

            /* reallocing if necessary */
            if(pt != -1 && strlen(&descriptor[pt]) > 0 && descriptor[pt] != '\0' && descriptor[pt] != '\n') {
                /* printf("Allocating memory for a new object !\n"); */
                domain->reverse = (int *) realloc(domain->reverse, (nobjects + 1) * sizeof(int));
                if(domain->reverse == NULL) {
                    fprintf(stderr, "Error: domainParse: realloc failed for domain->reverse.\n");
                    return 1;
                }

                domain->type = (int *) realloc(domain->type, (nobjects +1 ) * sizeof(int));
                if(domain->type == NULL) {
                    fprintf(stderr, "Error: domainParse: realloc failed for domain->type.\n");
                    return 1;
                }

                domain->start = (BROOKN *) realloc(domain->start, (nobjects + 1) * sizeof(BROOKN));
                if(domain->start == NULL) {
                    fprintf(stderr, "Error: domainParse: realloc failed for domain->starr.\n");
                    return 1;
                }

                domain->end = (BROOKN *) realloc(domain->end, (nobjects + 1) * sizeof(BROOKN));
                if(domain->end == NULL) {
                    fprintf(stderr, "Error: domainParse: realloc failed for domain->end.\n");
                    return 1;
                }
            }
            /* now either stop, or move onto the next descriptor */
        } 
	 
        /* check to see whether there is a transformation */
        if(pt != -1) {
            /* there is */
            while(descriptor[pt] != '\n' && descriptor[pt] != '\0')
                pt++;

            if(descriptor[pt] == '\0')
                domainParseError(buff);

            (*gottrans) = 1;
            if(
               sscanf(
                      &descriptor[pt],
                      "%f%f%f%f%f%f%f%f%f%f%f%f",
                      &(domain->R[0][0]), &(domain->R[0][1]), &(domain->R[0][2]), &(domain->V[0]),
                      &(domain->R[1][0]), &(domain->R[1][1]), &(domain->R[1][2]), &(domain->V[1]),
                      &(domain->R[2][0]), &(domain->R[2][1]), &(domain->R[2][2]), &(domain->V[2]))
               == (char) EOF
               )
                domainParseError(buff);
        }
        domain->nobj = nobjects;
        free(descriptor);
        free(buff);
        free(guff);

        return 0;
    }
    free(descriptor);
    free(buff);
    free(guff);

    return 1;
}

char a3to1(char *a3) {
    /* Converts three letter amino acid code to one letter
     *  amino acid code 
     * Note: CYS refers to cystine, CYH refers to cysteine */
    int i;
    char new;

    new = 'X';
    for(i = 0; i < strlen(A3TO1_ACIDS1); i++) {
        if(strncmp(&A3TO1_ACIDS3[i * 4], a3, 3) == 0) 
            new = (char) A3TO1_ACIDS1[i];
    }

    return(new);
} 

int domainGetAllCoords(DOMAIN_LOC *domain, MYFILE *file) {
    /* This reads in all atoms for a set of residues specified by a
     *  domain descriptor.  See the end of file for a sort of historical
     *  derivation of how the amino acids should/could match */

    int     i;
    int     begin;
    int     resSeq;
    int     newres;
    int     onlastresidue;
    char    lastres[20];
    char    chain, iCode, altLoc;
    RESIDUE *residue;
    ATOM    *atom;
    float   x, y, z;
    char    coordStr[9];
    char    *line;

    memset(coordStr, 9, '\0');

    chain = ' ';
    iCode = ' ';
    begin = 0;
    residue = NULL;
    for(i = 0; i < domain->nobj; ++i) { 
        begin = 0;
        lastres[0] = '\0';
        newres = 0;
        onlastresidue = 0;

        // make sure we're at the beginning of the file
        // FIXME - if the domains were in order and non-overlapping, could skip this and parsing would be quicker...
        (*file->rewind)(file);
        line = (*file->nextLine)(file);
        while(line != NULL) {
            /*
             * replacing this line:
             *   if((strncmp(line, "ENDMDL", 6) == 0 || strncmp(line, "END   ", 6) == 0) && begin == 1) { 
             * with this:
             *   if(begin == 1 && strncmp(line, "END", 3) == 0) {
             * because '==' is cheaper than 'strncmp', and don't need to test for
             * both "END   " and "ENDMDL" since the only lines that begin with "END"
             * in the PDB format are those beginning with "END   " and "ENDMDL"
             */
            if(begin == 1 && strncmp(line, "END", 3) == 0) {
                /* printf("Ending at %s\n", line); */
                if(domain->type[i] == 2)
                    onlastresidue = 1;
                break; 
            }

            if((begin == 1) && (domain->type[i] == 2) && strncmp(line, "TER", 3) == 0) {
                onlastresidue = 1;
                break;
            }

	    if((strncmp(line, "ATOM  ", 6) == 0) || ((strncmp(line, "HETATM", 6) == 0) && (strncmp(&line[17], "HOH", 3) != 0) && (strncmp(&line[17], "DOD", 3) != 0))) {
                altLoc= line[16];
                chain = line[21];
                iCode = line[26];

                if((strncmp(lastres, &line[17], 11) != 0)) {
                    newres = 1;
                    sscanf(&line[22], "%4d", &resSeq);
                }
                else {
                    newres = 0;
                }

                /* Need to fix this */
                /* Fixed I think - I was stupid and this was at the end, not the begining where it belongs */
                if(
                   begin
                   && (
                       (domain->type[i] == 2 && domain->start[i].chain != chain)
                       || ((strncmp("ATOM  ", line, 6) != 0) && (strncmp("HETATM", line, 6) != 0))
                       )
                   ) {
		    onlastresidue = 1;
                }

                if(
                   !begin
                   && (
                       (domain->start[i].chain == chain && domain->start[i].resSeq == resSeq && domain->start[i].iCode == iCode) /* range */
                       || (domain->start[i].chain == chain && domain->type[i] == 2) /* chain */
                       || (domain->type[i] == 1) /* all residues */
                       )
                   ) {
                    begin = 1;
                    onlastresidue = 0;
                    //printf("BEGIN %c %d %c == %c %d %c }\n", domain->start[i].chain, domain->start[i].resSeq, domain->start[i].iCode, chain, resSeq, iCode);
                }

                /* Test if this is a new residue */
                if(newres == 1) {
                    if(begin) {
                        if(onlastresidue == 1)
                            break;
                        residue = residueCreate(domain->residues->n + 1);
                        residue->chain = chain;
                        residue->resSeq = resSeq;
                        residue->iCode = iCode;
                        sscanf(&line[17], "%3s", residue->resName);
                        domainAddResidue(domain, residue);
                        residue->aa = a3to1(&line[17]);

                        if(chain == ' ')
                            residue->pdbnum.chain = ' ';
                        else
                            residue->pdbnum.chain = chain;

                        if(iCode == ' ')
                            residue->pdbnum.iCode = ' ';
                        else
                            residue->pdbnum.iCode = iCode;

                        residue->pdbnum.resSeq = resSeq;
                    }
                }
                strncpy(lastres, &line[17], 11);
                lastres[11] = '\0';
                if(begin) {
                    atom = atomCreate();
                    strncpy(atom->name, &line[12], 4);
                    stringRemoveSpaces(atom->name);
                    if(
                       (atom->name[0] != 'H')                    // ignore hydrogen atoms...
                       || (strcmp(residue->resName, "HG") == 0)  //  ... but not mercury atoms...
                       || (strcmp(residue->resName, "MBO") == 0)
                       || (strcmp(residue->resName, "HGB") == 0)
                       || (strcmp(residue->resName, "MMC") == 0)
                       || (strcmp(residue->resName, "HO") == 0)  // ... or holmium atoms
                       || (strcmp(residue->resName, "HO3") == 0)
                       ) {
                        //sscanf(&line[30], "%8f%8f%8f", &x, &y, &z);

                        /*
                        strncpy(coordStr, &line[30], 8);
                        x = atof(coordStr);
                        strncpy(coordStr, &line[38], 8);
                        y = atof(coordStr);
                        strncpy(coordStr, &line[46], 8);
                        z = atof(coordStr);
                        */

                        /*
                        memcpy(coordStr, &line[30], 8);
                        x = atof(coordStr);
                        memcpy(coordStr, &line[38], 8);
                        y = atof(coordStr);
                        memcpy(coordStr, &line[46], 8);
                        z = atof(coordStr);
                        */
                        x = stringParse8_3f(line + 30);
                        y = stringParse8_3f(line + 38);
                        z = stringParse8_3f(line + 46);

                        atom->sphere.centre[0] = x;
                        atom->sphere.centre[1] = y;
                        atom->sphere.centre[2] = z;
                        domainAddAtom(domain, residue, atom);
                    }
                } 
            } 
            if(
               begin
               && (
                   domain->type[i] == 3
                   && domain->end[i].chain == chain
                   && domain->end[i].resSeq == resSeq
                   && domain->end[i].iCode == iCode
                   && domain->type[i] == 3
                   )
               ) {
                //printf("END %c %d %c == %c %d %c }\n", domain->end[i].chain, domain->end[i].resSeq, domain->end[i].iCode, chain, resSeq, iCode);
                onlastresidue = 1;
            }

            line = (*file->nextLine)(file);
	}

        if((((domain->type[i] == 2) || (domain->type[i] == 3))) && (onlastresidue == 0)) {
            fprintf(stderr, "error end of sequence for '%s' not found in PDB file '%s'\n", domain->id, domain->filename);
            return 1;
        }
    }

    if(!begin) {
        fprintf(stderr, "error: begin of sequence for '%s' not found in PDB file '%s'\n", domain->id, domain->filename);
        return 1;
    }

    return 0;
}

int residueStandardOutput() {
    int i, j;

    for(i = 0; i < MAXSTANDARDRES; ++i) {
        for(j = 0; j < standardRes[i].atomCount; ++j) {
            printf(
                   "%d\t%3s\t%c\t%d\t%s\t%s%s%s%s%s\n",
                   i,
                   standardRes[i].threeCode,
                   standardRes[i].oneCode,
                   standardRes[i].atomCount,
                   standardRes[i].atomTypes[j],
                   (standardRes[i].atomClasses[j] & SIDECHAIN)      ? "sidechain" : "mainchain",
                   (standardRes[i].atomClasses[j] & HBOND_DONOR)    ? ", H-bond donor" : "",
                   (standardRes[i].atomClasses[j] & HBOND_ACCEPTOR) ? ", H-bond acceptor" : "",
                   (standardRes[i].atomClasses[j] & SALT)           ? ", salt" : "",
                   (standardRes[i].atomClasses[j] & RES_END)        ? ", end" : ""
                   );
        }
        printf("//\n");
    }

    return 0;
}

int domainCalcBoundingSpheres(DOMAIN_LOC *domain, float *rMaxAllResidues) {
    int     i, j, k;
    RESIDUE *residue;
    ATOM    *atom;
    float   r2; // radius squared
    float   r;

    if(domain->residues->n == 0) {
        fprintf(stderr, "Error: domainCalcBoundingSpheres: domain %s has no residues.\n", domain->id);
        return 1;
    }

    for(i = 0; i < domain->residues->n; i++) {
        residue = domain->residues->all[i];

        if(residue->atoms->n == 0) {
            fprintf(
                    stderr,
                    "Error: domainCalcBoundingSpheres: residue '%c%d%c' (%s) of domain %s (%s) has no atoms.\n",
                    residue->chain,
                    residue->resSeq,
                    residue->iCode,
                    residue->resName,
                    domain->id,
                    domain->filename
                    );
            return 1;
        }

        // centre of residue
        for(j = 0; j < residue->atoms->n; j++) {
            atom = residue->atoms->all[j];
            for(k = 0; k < 3; k++) {
                residue->sphere.centre[k] += atom->sphere.centre[k];

                if(atom->sphere.centre[k] < residue->minCoord[k])
                    residue->minCoord[k] = atom->sphere.centre[k];

                if(atom->sphere.centre[k] > residue->maxCoord[k])
                    residue->maxCoord[k] = atom->sphere.centre[k];
            }
        }

        for(k = 0; k < 3; k++) {
            residue->sphere.centre[k] /= residue->atoms->n;

            if(residue->minCoord[k] < domain->minCoord[k])
                domain->minCoord[k] = residue->minCoord[k];

            if(residue->maxCoord[k] > domain->maxCoord[k])
                domain->maxCoord[k] = residue->maxCoord[k];
        }

        // radius of this residue
        r = 0.0;
        for(j = 0; j < residue->atoms->n; j++) {
            atom = residue->atoms->all[j];
            r2 = distanceSquared(residue->sphere.centre, atom->sphere.centre);
            if(r2 > r)
                r = r2;
        }
        r = sqrt(r);
        residue->sphere.r = r;
        if(r > domain->rMaxResidue)
            domain->rMaxResidue = r;

        // centre of domain
        for(k = 0; k < 3; k++) {
            domain->sphere.centre[k] += residue->sphere.centre[k];
        }
    }
    if(domain->rMaxResidue > *rMaxAllResidues)
        *rMaxAllResidues = domain->rMaxResidue;

    // centre of domain
    for(k = 0; k < 3; k++) {
        domain->sphere.centre[k] /= domain->residues->n;
    }

    // radius of domain
    r = 0.0;
    for(i = 0; i < domain->residues->n; i++) {
        residue = domain->residues->all[i];

        r2 = distanceSquared(domain->sphere.centre, residue->sphere.centre);
        if(r2 > r)
            r = r2;
    }
    r = sqrt(r);

    /*
     * add on the maximum radius of any residue.
     * this is conservative since the biggest residue might be buried,
     * but it means I can just loop through each residue, above, rather
     * than each atom again
     */
    r += domain->rMaxResidue;
    domain->sphere.r = r;

    return 0;
}

int domainParseAll(FILE *IN, LIST *domains, int *gottrans) {
    /* Given a file containing a list of protein descriptors, returns
     *  a list of brookhaven starts and ends, or appropriate wild cards
     *  for subsequent use 
     *
     * New version to remove all the stupid wonk bugs that this used to contain 
     * it now seems very resilient to the placement of newlines, junk, etc */

    int i, j;
    int end;
    DOMAIN_LOC *domain_a;
    DOMAIN_LOC *domain_b;

    end = 0;
    (*gottrans) = 0;
    while(!end) {
        domain_a = domainCreate();
        end = domainParse(domain_a, &i, IN);

        switch(end) {
        case -1:
            fprintf(stderr, "error in domain specification file\n");
            return -1;
        case 1:
            // no domains read, end of file
            domainDelete(domain_a);
            break;
        default:
            listAddElement(domains, 1, domain_a);
        }

        if(i == 1)
            (*gottrans) = 1;
    }

    /* check for duplication */
    for(i = 0; i < domains->n; ++i) {
        domain_a = (DOMAIN_LOC *) domains->all[i];
        for(j = i + 1; j < domains->n; ++j) {
            domain_b = (DOMAIN_LOC *) domains->all[j];
            if(strcmp(domain_a->id, domain_b->id) == 0) {
                fprintf(stderr,"error: domain identifiers must not be the same\n");
                fprintf(stderr,"       found two copies of %s, domains %d & %d\n", domain_a->id, i + 1, j + 1);
                return -1; 
            }
        }
    }

    return 0;
}

int domainsByAssembly(const void *a, const void *b) {
    const DOMAIN_TO_FRAG *d2f_a = *(const DOMAIN_TO_FRAG **) a;
    const DOMAIN_TO_FRAG *d2f_b = *(const DOMAIN_TO_FRAG **) b;

    if(d2f_a->assembly == d2f_b->assembly)
        if(d2f_a->model == d2f_b->model)
            return 0;
        else if(d2f_a->model < d2f_b->model)
            return -1;
        else
            return 1;
    else if(d2f_a->assembly < d2f_b->assembly)
        return -1;
    else
        return 1;

    return 0;
}

LIST *assemblyParseAll(char fn[FILENAMELEN], LIST *domains, DOMAINS_TO_FRAGS **ds2fs) {
    LIST             *assemblies;
    ASSEMBLY         *assembly;
    MODEL            *model;
    MYFILE           *file;
    char             *line;
    int              p_assembly;
    int              p_model;
    int              i, j, k, l;
    DOMAIN_LOC       *domain;
    DOMAIN_TO_FRAG   *d2f;
    float            rAssembly, rAssemblyMax;
    float            rModel, rModelMax;

    assemblies = listCreate("assemblies");
    assembly = NULL;
    model = NULL;
    *ds2fs = domainsToFragsCreate();

    rAssemblyMax = 0;
    file = myFileOpen(fn);
    if(file == NULL)
        return NULL;
    if(myFileRead(file) != 0)
        return NULL;

    line = (*file->nextLine)(file);
    while(line != NULL) {
        d2f = domainToFragCreate();
        sscanf(line, "%s %d %d %d", d2f->id_domain, &(d2f->id_frag), &(d2f->assembly), &(d2f->model));
        modelAddDomainsToFrags(*ds2fs, d2f);
        for(i = 0; i < domains->n; ++i) {
            domain = domains->all[i];
            if(strcmp(d2f->id_domain, domain->id) == 0) {
                d2f->domain = domain;
                break;
            }
        }
        line = (*file->nextLine)(file);
    }
    myFileDelete(file);

    qsort((const DOMAIN_TO_FRAG **) (*ds2fs)->all, (*ds2fs)->n, sizeof(DOMAIN_TO_FRAG *), domainsByAssembly);
    p_assembly = -1;
    p_model = -1;
    for(i = 0; i < (*ds2fs)->n; i++) {
        d2f = (*ds2fs)->all[i];
        domain = d2f->domain;

        if(d2f->assembly != p_assembly) {
            assembly = assemblyCreate(d2f->assembly);
            listAddElement(assemblies, 1, assembly);
            p_model = -1;
        }

        if(d2f->model != p_model) {
            model = modelCreate(d2f->model);
            assemblyAddModel(assembly, model);
        }

        modelAddDomain(model, domain);
        domain->assembly = assembly;
        domain->model = model;

        p_assembly = d2f->assembly;
        p_model = d2f->model;
    }
    (*ds2fs)->n_assemblies = assemblies->n;
    findFragsToAssemblies(*ds2fs);

    // get assembly and model bounding sphere centres and min and max coordinates
    for(i = 0; i < assemblies->n; i++) {
        assembly = assemblies->all[i];
        for(j = 0; j < assembly->models->n; j++) {
            model = assembly->models->all[j];
            for(k = 0; k < model->domains->n; k++) {
                domain = model->domains->all[k];
                for(l = 0; l < 3; l++) {
                    model->sphere.centre[l] += domain->sphere.centre[l];

                    if(domain->minCoord[l] < model->minCoord[l])
                        model->minCoord[l] = domain->minCoord[l];

                    if(domain->maxCoord[l] > model->maxCoord[l])
                        model->maxCoord[l] = domain->maxCoord[l];
                }

                if(domain->sphere.r > model->rMaxDomain)
                    model->rMaxDomain = domain->sphere.r;
            }

            for(l = 0; l < 3; l++) {
                model->sphere.centre[l] /= model->domains->n;
                assembly->sphere.centre[l] += model->sphere.centre[l];

                if(model->minCoord[l] < assembly->minCoord[l])
                    assembly->minCoord[l] = model->minCoord[l];

                if(model->maxCoord[l] > assembly->maxCoord[l])
                    assembly->maxCoord[l] = model->maxCoord[l];
            }
        }

        for(l = 0; l < 3; l++) {
            assembly->sphere.centre[l] /= assembly->models->n;
        }
    }

    // get assembly and model bounding sphere radii
    for(i = 0; i < assemblies->n; i++) {
        assembly = assemblies->all[i];
        rAssemblyMax = 0.0;
        for(j = 0; j < assembly->models->n; j++) {
            model = assembly->models->all[j];

            rModelMax = 0.0;
            for(k = 0; k < model->domains->n; k++) {
                domain = model->domains->all[k];
                rModel = distance(model->sphere.centre, domain->sphere.centre) + domain->sphere.r;
                if(rModel > rModelMax)
                    rModelMax = rModel;
            }
            model->sphere.r = rModelMax;

            rAssembly = distance(assembly->sphere.centre, model->sphere.centre) + model->sphere.r;
            if(rAssembly > rAssemblyMax)
                rAssemblyMax = rAssembly;

            if(model->sphere.r > assembly->rMaxModel)
                assembly->rMaxModel = model->sphere.r;
        }
        assembly->sphere.r = rAssemblyMax;
    }

    return assemblies;
}

int domainSortByPDBFile(const void *a, const void *b) {
    const DOMAIN_LOC *domain_a = *(const DOMAIN_LOC **) a;
    const DOMAIN_LOC *domain_b = *(const DOMAIN_LOC **) b;

    return strcmp(domain_a->filename, domain_b->filename);
}
