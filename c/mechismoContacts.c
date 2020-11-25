#include "contact.h"

void usage() {
    fprintf(stderr, "\n");
    fprintf(stderr, "Usage: mechismoContacts [options] < domfile\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "option              parameter  description                                                 default\n");
    fprintf(stderr, "------------------  ---------  ----------------------------------------------------------  -------\n");
    fprintf(stderr, "--help              [none]     print this usage info and exit\n");
    fprintf(stderr, "--both_directions   [none]     output contacts in both directions                          output in one direction\n");
    fprintf(stderr, "--id_contact        integer    start contact ids at 1 + this number                        0\n");
    fprintf(stderr, "--contacts_out      string     name of file for Contact output                             stdout\n");
    fprintf(stderr, "--res_contacts_out  string     name of file for ResContact output                          stdout\n");
    fprintf(stderr, "--intra             [none]     calculate contacts intra-domain as well as inter-domain\n");
    fprintf(stderr, "--assemblies        string     name of file giving assembly and model numbers \n");
    fprintf(stderr, "                               for each domain, for checking for crystal contacts\n");
    fprintf(stderr, "                               Also: intra-model inter-domain contacts only calculated\n");
    fprintf(stderr, "                               for assembly 0, and intra-domain contacts (if requested)\n");
    fprintf(stderr, "                               also only calculated for assembly 0.\n");
    fprintf(stderr, "\n");
 
    exit(-1);
}

typedef struct args {
    int  bothDirections; // if true, output contacts in both directions
    int  id_contact;
    char fn_contact[FILENAMELEN];
    char fn_res_contact[FILENAMELEN];
    char fn_assemblies[FILENAMELEN];
    char file_write_type[2];
    int  intra;
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

    args->bothDirections = 0;
    args->id_contact = 0;
    memset(args->fn_contact, '\0', FILENAMELEN);
    memset(args->fn_res_contact, '\0', FILENAMELEN);
    memset(args->fn_assemblies, '\0', FILENAMELEN);
    strcpy(args->file_write_type, "w\0");
    args->intra = 0;

    for(i = 1; i < argc; ++i) {
        len = strlen(argv[i]);

        if(argv[i][0] != '-')
            return NULL;

        j = (argv[i][1] == '-') ? 2 : 1; // allow for '--' style
        len -= j; // allow for short versions

        // FIXME - check for ambiguous arguments (especially if short versions are given)
            
        //printf("getArgs: '%s', len = %d\n", argv[i], len);

        if(strncmp(&argv[i][j], "help", len) == 0) { 
            return NULL;
        }
        else if(strncmp(&argv[i][j], "both_directions", len) == 0) { 
            args->bothDirections = 1;
        }
        else if(strncmp(&argv[i][j], "id_contact", len) == 0) { 
            sscanf(argv[++i], "%d", &args->id_contact);
        }
        else if(strncmp(&argv[i][j], "contacts_out", len) == 0) { 
            strncpy(args->fn_contact, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "res_contacts_out", len) == 0) { 
            strncpy(args->fn_res_contact, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "assemblies", len) == 0) {
            strncpy(args->fn_assemblies, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "append", len) == 0) {
            strcpy(args->file_write_type, "a\0");
        }
        else if(strncmp(&argv[i][j], "intra", len) == 0) {
            args->intra = 1;
        }
        else {
            return NULL;
        }
    }

    return args;
}

int main(int argc, char **argv) {
    ARGS              *args;
    LIST              *domains;
    DOMAIN_LOC        *domain;
    int               i, j;
    int               trans;
    int               n;
    int               id_contact;
    FILE              *fhContact;
    FILE              *fhResContact;
    LIST              *assemblies;
    ASSEMBLY          *assembly;
    MODEL             *model;
    LIST              *domainContactArgs;
    DOMAINS_TO_FRAGS  *ds2fs;
    SPATIAL_PARTITION *grid;
    float             rMaxAllDomains, rMaxAllResidues;
    float             minCoord[3];
    float             maxCoord[3];
    MYFILE            *file;
    char              fnPdb[FILENAMELEN];

    args = getArgs(argc, argv);
    if(args == NULL) 
        usage();

    // open output files
    if(args->fn_contact[0] != '\0') {
        fhContact = myFileOpenWrite(args->fn_contact, args->file_write_type);
        if(fhContact == NULL) {
            fprintf(stderr, "Error: cannot open '%s' file for writing.\n", args->fn_contact);
            exit(-1);
        }
    }
    else {
        fhContact = stdout;
    }

    if(args->fn_res_contact[0] != '\0') {
        fhResContact = myFileOpenWrite(args->fn_res_contact, args->file_write_type);
        if(fhResContact == NULL) {
            fprintf(stderr, "Error: cannot open '%s' file for writing.\n", args->fn_res_contact);
            exit(-1);
        }
    }
    else {
        fhResContact = stdout;
    }

    // read domains
    domains = listCreate("domains");
    if(domainParseAll(stdin, domains, &trans) == -1)
        exit(-1);

    // initialise the boundaries and max radii
    rMaxAllDomains = 0.0;
    rMaxAllResidues = 0.0;
    for(i = 0; i < 3; i++) {
        minCoord[i] = 1000000000.0;
        maxCoord[i] = -1000000000.0;
    }

    // sort domains by filename so that each file only has to be read from disk once
    qsort((const DOMAIN_LOC **) domains->all, domains->n, sizeof(DOMAIN_LOC *), domainSortByPDBFile);

    memset(fnPdb, '\0', FILENAMELEN);
    file = NULL;
    for(i = 0, n = 1; i < domains->n; ++i, ++n) {
        domain = (DOMAIN_LOC *) domains->all[i];

        //printf("%d { %c %d %c to %c %d %c }\n", i, domain->start->chain, domain->start->resSeq, domain->start->iCode, domain->end->chain, domain->end->resSeq, domain->end->iCode);
        if(strcmp(fnPdb, domain->filename) != 0) {
            memset(fnPdb, '\0', FILENAMELEN);
            strcpy(fnPdb, domain->filename);
            if(file != NULL)
                myFileDelete(file);

            file = myFileOpen(domain->filename);
            if(file == NULL)
                exit(-1);
            if(myFileRead(file) != 0)
                exit(-1);
        }

        //printf("DOMAIN %s\n", domain->id);
        if(domainGetAllCoords(domain, file) != 0) {
            myFileDelete(file);
            exit(-1);
        }

        domainCalcBoundingSpheres(domain, &rMaxAllResidues);
        if(domain->sphere.r > rMaxAllDomains)
            rMaxAllDomains = domain->sphere.r;

        for(j = 0; j < 3; j++) {
            if(domain->minCoord[j] < minCoord[j])
                minCoord[j] = domain->minCoord[j];

            if(domain->maxCoord[j] > maxCoord[j])
                maxCoord[j] = domain->maxCoord[j];
        }
    }

    if(file != NULL)
        myFileDelete(file);

    /*
    printf(
           "rMaxAllDomains = %f, rMaxAllResidues = %f, minCoord = [%.6f, %.6f, %.6f], maxCoord = [%.6f, %.6f, %.6f]\n",
           rMaxAllDomains,
           rMaxAllResidues,
           minCoord[0],
           minCoord[1],
           minCoord[2],
           maxCoord[0],
           maxCoord[1],
           maxCoord[2]
           );
    */

    // WARNING: spatial partitions at the same level (eg domains) should have the same elementSize

    // find contacts
    id_contact = args->id_contact;

    /*
     * - spatial partition for all assemblies
     * - for each assembly, spatial partition for all models
     * - for each model, spatial partition for all domains
     * - for each domain, spatial partition for all residues
     * - for each residue, spatial partition for all atoms
     *
     * sub-grids should be exact subdivisions of their parents, so that
     * different sub-grids at the same level can be more easily compared
     * (if they overlap each other, some of their cells coincide exactly)
     *
     * easiest way to achieve this is to have all grid element sizes as a
     * multiple of the lowest/smallest, i.e. the element size of the spatial
     * partition for atoms, = MAXDIST
     *
     * only need spatial partition of domains for those models that might interact
     * only need spatial partition of residues for those domains that might interact
     * only need spatial partition of atoms for those residues that might interact
     */

    domainContactArgs = listCreate("args");
    if(args->fn_assemblies[0] != '\0') {
        /*
         * domains are in different assemblies and these
         * should be considered when calculating contacts
         */
        assemblies = assemblyParseAll(args->fn_assemblies, domains, &ds2fs);
        if(assemblies == NULL)
            exit(1);

        listAddElement(domainContactArgs, 8, &(args->intra), &(args->bothDirections), &id_contact, ds2fs, fhContact, fhResContact, &rMaxAllResidues, &rMaxAllDomains);

        /*
        for(i = 0; i < assemblies->n; ++i) {
            assembly = (ASSEMBLY *) assemblies->all[i];
            printf(
                   "ASSEMBLY\t%d\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\n",
                   assembly->id,
                   assembly->minCoord[0],
                   assembly->minCoord[1],
                   assembly->minCoord[2],
                   assembly->maxCoord[0],
                   assembly->maxCoord[1],
                   assembly->maxCoord[2],
                   assembly->sphere.centre[0],
                   assembly->sphere.centre[1],
                   assembly->sphere.centre[2],
                   assembly->sphere.r
                   );
        }
        */

        if(args->intra == 1) {
            // only need to calculate intra-domain contacts for domains in the first assembly (id = 0, i.e. the original pdb)
            assembly = (ASSEMBLY *) assemblies->all[0];
            for(i = 0; i < assembly->models->n; i++) {
                model = (MODEL *) assembly->models->all[i];
                for(i = 0; i < model->domains->n; i++) {
                    domainContact(model->domains->all[i], NULL, domainContactArgs);
                }
            }
        }

        // only need to calculate intra-assembly intra-model domain contacts for the first assembly, (assembly = 0, model = 0)
        assembly = (ASSEMBLY *) assemblies->all[0];
        model = (MODEL *) assembly->models->all[0];
        if(model->grid == NULL) {
            model->grid = spatialPartitionCreate(model->domains, domainSphere, MAXDIST, rMaxAllDomains, model->minCoord, model->maxCoord);
            if(model->grid == NULL)
                exit(1);
        }
        spatialPartitionFindContacts(model->grid, NULL, domainContact, domainContactArgs);

        // only need to calculate inter-model domain contacts for the other assemblies
        for(i = 1; i < assemblies->n; ++i) {
            assembly = (ASSEMBLY *) assemblies->all[i];
            if(assembly->models->n > 1) {
                if(assembly->grid == NULL) {
                    assembly->grid = spatialPartitionCreate(assembly->models, modelSphere, MAXDIST, assembly->rMaxModel, assembly->minCoord, assembly->maxCoord);
                    if(assembly->grid == NULL)
                        continue;
                    //spatialPartitionOutput(assembly->grid, "ASSEMBLY", modelOutput);
                }
                spatialPartitionFindContacts(assembly->grid, NULL, modelContact, domainContactArgs);
            }
        }

        listDelete(assemblies, assemblyDelete);
        listDelete(domains, NULL);
        domainsToFragsDelete(ds2fs);
    }
    else {
        listAddElement(domainContactArgs, 8, &(args->intra), &(args->bothDirections), &id_contact, NULL, fhContact, fhResContact, &rMaxAllResidues, &rMaxAllDomains);

        if(args->intra == 1) {
            for(i = 0; i < domains->n; i++) {
                domainContact(domains->all[i], NULL, domainContactArgs);
            }
        }

        // find contacts between all pairs of domains
        grid = spatialPartitionCreate(domains, domainSphere, MAXDIST, rMaxAllDomains, minCoord, maxCoord);
        if(grid == NULL)
            exit(1);
        //spatialPartitionOutput(grid, "DOMAIN", domainOutput);
        spatialPartitionFindContacts(grid, NULL, domainContact, domainContactArgs);
        spatialPartitionDelete(grid);

        listDelete(domains, domainDelete);
    }
    listDelete(domainContactArgs, NULL);

    //residueStandardOutput();

    // close output files
    if(args->fn_contact[0] != '\0')
        fclose(fhContact);

    if(args->fn_res_contact[0] != '\0')
        fclose(fhResContact);

    free(args);

    printf("id_contact = %d\n", id_contact);

    exit(0);
}
