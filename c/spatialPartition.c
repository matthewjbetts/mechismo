#include "spatialPartition.h"

float toPrecisionFloor(float value, float maxDist) {
    value = floor(value / maxDist) * maxDist;

    return value;
}

float toPrecisionCeil(float value, float maxDist) {
    value = ceil(value / maxDist) * maxDist;

    return value;
}

int coordToIdx(SPATIAL_PARTITION *grid, float x, float y, float z, int *i, int *j, int *k) {
    /*
    *i = (int) ((x - grid->minCoord[0]) / grid->elementSize);
    *j = (int) ((y - grid->minCoord[1]) / grid->elementSize);
    *k = (int) ((z - grid->minCoord[2]) / grid->elementSize);
    */

    *i = (int) floor((x - grid->minCoord[0]) / grid->elementSize);
    *j = (int) floor((y - grid->minCoord[1]) / grid->elementSize);
    *k = (int) floor((z - grid->minCoord[2]) / grid->elementSize);

    return 0;
}

int idxToCoord(SPATIAL_PARTITION *grid, int i, int j, int k, float *x, float *y, float *z) {
    *x = grid->minCoord[0] + i * grid->elementSize;
    *y = grid->minCoord[1] + j * grid->elementSize;
    *z = grid->minCoord[2] + k * grid->elementSize;

    return 0;
}

int idxToIdx(SPATIAL_PARTITION *grid1, SPATIAL_PARTITION *grid2, int i1, int j1, int k1, int *i2, int *j2, int *k2) {
    float x, y, z;
    float x2, y2, z2;
    int i3, j3, k3;

    idxToCoord(grid1, i1, j1, k1, &x, &y, &z);
    coordToIdx(grid2, x, y, z, i2, j2, k2);
    idxToCoord(grid2, *i2, *j2, *k2, &x2, &y2, &z2);
    coordToIdx(grid1, x2, y2, z2, &i3, &j3, &k3);

    if((i3 != i1) || (j3 != j1) || (k3 != k1)) {
        fprintf(stderr, "Error: IDXTOIDX != (grid1 = [%6.1f, %6.1f, %6.1f, %6.1f], grid2 = [%6.1f, %6.1f, %6.1f, %6.1f]) ## [%02d, %02d, %02d] => [%6.1f, %6.1f, %6.1f] => [%02d, %02d, %02d] => [%6.1f, %6.1f, %6.1f] => [%02d, %02d, %02d]\n",
               grid1->minCoord[0], grid1->minCoord[1], grid1->minCoord[2], grid1->elementSize,
               grid2->minCoord[0], grid2->minCoord[1], grid2->minCoord[2], grid2->elementSize,
               i1, j1, k1,
               x, y, z,
               *i2, *j2, *k2,
               x2, y2, z2,
               i3, j3, k3);
    }

    return 0;
}

int idxInBounds(SPATIAL_PARTITION *grid, int i, int j, int k) {
    if((i < 0) || (i >= grid->dimensions[0]))
        return 1;
    
    if((j < 0) || (j >= grid->dimensions[1]))
        return 1;

    if((k < 0) || (k >= grid->dimensions[2]))
        return 1;

    return 0;
}

int idx1d(SPATIAL_PARTITION *grid, int i, int j, int k) { // index to one-dimensional array
    int idx;

    idx = i + (j * grid->dimensions[0]) + (k * grid->dimensions[0] * grid->dimensions[1]);

    return idx;
}

int coordToIdx1d(SPATIAL_PARTITION *grid, float x, float y, float z) {
    int i, j, k;
    int idx;

    coordToIdx(grid, x, y, z, &i, &j, &k);
    idx = idx1d(grid, i, j, k);
    idx = (idx >= grid->nElements) ? grid->nElements - 1 : idx; // WARNING: this is to cover edge cases... but will also put things in to the last cell that are way off

    return idx;
}

SPATIAL_PARTITION *spatialPartitionCreate(LIST *list, SPHERE *(*thingSphere)(void *), float maxDist, float rMax, float minCoord[3], float maxCoord[3]) {
    SPATIAL_PARTITION *grid;
    int               i, j;
    SPHERE            *sphere;
    int               idx;

    grid = (SPATIAL_PARTITION *) malloc(sizeof(SPATIAL_PARTITION));
    if(grid == NULL) {
        fprintf(stderr, "Error: spatialPartitionCreate: malloc failed.\n");
        return NULL;
    }

    //printf("spatialPartitionCreate\t%d\n", list->n);

    if(rMax > 0.0) {
        grid->elementSize = rMax;
        for(i = 0; i < 3; i++) {
            grid->minCoord[i] = minCoord[i];
            grid->maxCoord[i] = maxCoord[i];
        }
    }
    else {
        // initialise the boundaries covered by the grid
        sphere = (*thingSphere)(list->all[0]);
        for(i = 0; i < 3; i++) {
            grid->minCoord[i] = sphere->centre[i];
            grid->maxCoord[i] = sphere->centre[i];
        }
        grid->elementSize = 0;

        // get max and min coords and max radius
        for(i = 0; i < list->n; i++) {
            sphere = (*thingSphere)(list->all[i]);

            if(sphere->r > grid->elementSize)
                grid->elementSize = sphere->r;

            for(j = 0; j < 3; j++) {
                if(sphere->centre[j] < grid->minCoord[j])
                    grid->minCoord[j] = sphere->centre[j];

                if(sphere->centre[j] > grid->maxCoord[j])
                    grid->maxCoord[j] = sphere->centre[j];
            }
        }
    }

    /*
    if(grid->elementSize <= 0) {
        fprintf(stderr, "Error: spatialPartitionCreate: elementSize is too small.\n");
        return NULL;
    }
    */
    if(grid->elementSize <= 0)
        grid->elementSize = 0; // will be zero for a single atom

    /*
     * to ensure that two things whose bounding spheres are separated
     * by <= maxDist are in the same or adjacent grid elements,
     * elementSize should be the maximum diameter (not radius) plus maxDist
     */
    grid->elementSize *= 2;
    grid->elementSize += maxDist;

    /*
     * elementSize should be an exact multiple of maxDist, and min and max coords should
     * be exact multiples of elementSize, so that sub-grids fit exactly in to this
     * one, and so that overlapping elements of overlapping sub-grids exactly coincide
     */
    //printf("elementSize = %f, coords = [%f..%f, %f..%f, %f..%f]\n", grid->elementSize, grid->minCoord[0], grid->maxCoord[0], grid->minCoord[1], grid->maxCoord[1], grid->minCoord[2], grid->maxCoord[2]);
    grid->elementSize = toPrecisionCeil(grid->elementSize, maxDist);
    for(i = 0; i < 3; i++) {
        grid->minCoord[i] = toPrecisionFloor(grid->minCoord[i], grid->elementSize);
        grid->maxCoord[i] = toPrecisionCeil(grid->maxCoord[i], grid->elementSize);
    }
    //printf("elementSize = %f, coords = [%f..%f, %f..%f, %f..%f]\n", grid->elementSize, grid->minCoord[0], grid->maxCoord[0], grid->minCoord[1], grid->maxCoord[1], grid->minCoord[2], grid->maxCoord[2]);

    /*
    coordToIdx(grid, grid->maxCoord[0], grid->maxCoord[1], grid->maxCoord[2], &(grid->dimensions[0]), &(grid->dimensions[1]), &(grid->dimensions[2]));
    for(i = 0; i < 3; i++)
        grid->dimensions[i]++; // the call coordToIdx above gives the max index in 3d, but indices start at zero so the sizes are one bigger than this 
    */
    for(i = 0; i < 3; i++) {
        grid->dimensions[i] = (int) ceil((grid->maxCoord[i] - grid->minCoord[i]) / grid->elementSize);
        if(grid->dimensions[i] == 0) // can happen for single atom domains
            grid->dimensions[i] = 1;
    }
    //grid->nElements = idx1d(grid, grid->dimensions[0], grid->dimensions[1], grid->dimensions[2]);
    grid->nElements = grid->dimensions[0] * grid->dimensions[1] * grid->dimensions[2];

    grid->elements = (LIST **) malloc(grid->nElements * sizeof(LIST *));
    if(grid->elements == NULL) {
        fprintf(stderr, "Error: spatialPartitionCreate: malloc failed.\n");
        return NULL;
    }
    for(i = 0; i < grid->nElements; i++) {
        grid->elements[i] = NULL;
    }

    for(i = 0; i < list->n; i++) {
        sphere = (*thingSphere)(list->all[i]);
        idx = coordToIdx1d(grid, sphere->centre[0], sphere->centre[1], sphere->centre[2]);
        if(grid->elements[idx] == NULL)
            grid->elements[idx] = listCreate(NULL);
        listAddElement(grid->elements[idx], 1, list->all[i]);
    }

    return grid;
}

int spatialPartitionOutput(SPATIAL_PARTITION *grid, char *name, int thingOutput(void *thing)) {
    int  i, j, k, l;
    int  idx;

    printf(
           "GRID\t%s\tnElements = %d, elementSize = %f, coords = [%f..%f, %f..%f, %f..%f], dimensions = [%d, %d, %d]\n",
           name,
           grid->nElements,
           grid->elementSize,
           grid->minCoord[0],
           grid->maxCoord[0],
           grid->minCoord[1],
           grid->maxCoord[1],
           grid->minCoord[2],
           grid->maxCoord[2],
           grid->dimensions[0],
           grid->dimensions[1],
           grid->dimensions[2]
           );

    for(i = 0; i < grid->dimensions[0]; i++) {
        for(j = 0; j < grid->dimensions[1]; j++) {
            for(k = 0; k < grid->dimensions[2]; k++) {
                idx = idx1d(grid, i, j, k);
                if(grid->elements[idx] != NULL) {
                    printf("ELEMENT\t[%02d, %02d, %02d], idx = %d, n_things = %d\n", i, j, k, idx, grid->elements[idx]->n);

                    if(thingOutput != NULL) {
                        for(l = 0; l < grid->elements[idx]->n; l++) {
                            thingOutput(grid->elements[idx]->all[l]);
                        }
                    }
                }
                else {
                    printf("ELEMENT\t[%02d, %02d, %02d], n_things = 0\n", i, j, k);
                }
            }
        }
    }
           
    return 0;
}

int spatialPartitionFindContactsBetweenLists(
                             LIST  *list1,
                             LIST  *list2,
                             int   (*thingContact)(void *thing1, void *thing2, LIST *args),
                             LIST  *args
                             ) {
    int  i, j;
    void *thing1;
    void *thing2;
    //int  nComp;

    if(list2 == NULL) {
        if(list1->n > 0) {
            for(i = 0; i < list1->n; i++) {
                thing1 = list1->all[i];
                for(j = i + 1; j < list1->n; j++) {
                    thing2 = list1->all[j];
                    (*thingContact)(thing1, thing2, args);
                }
            }
        }
    }
    else {
        if((list1->n > 0) && (list2->n > 0)) {
            for(i = 0; i < list1->n; i++) {
                thing1 = list1->all[i];
                for(j = 0; j < list2->n; j++) {
                    thing2 = list2->all[j];
                    (*thingContact)(thing1, thing2, args);
                }
            }
        }
    }

    return 0;
}

int spatialPartitionFindContacts(
                 SPATIAL_PARTITION *gridA,
                 SPATIAL_PARTITION *gridB,
                 int               (*thingContact)(void *thing1, void *thing2, LIST *args),
                 LIST              *args
                 ) {
    int     iA1, jA1, kA1, iA2, jA2, kA2, iB1, jB1, kB1, iB2, jB2, kB2;
    int     ds[13][3] = {
        {0,  0,  1},
        {0,  1, -1},
        {0,  1,  0},
        {0,  1,  1},
        {1, -1, -1},
        {1, -1,  0},
        {1, -1,  1},
        {1,  0, -1},
        {1,  0,  0},
        {1,  0,  1},
        {1,  1, -1},
        {1,  1,  0},
        {1,  1,  1},
    };
    int     d;
    int     idxA1, idxA2, idxB2;
    LIST    *elementA1;
    LIST    *elementA2;
    LIST    *elementB2;
    int     iStart, iEnd, jStart, jEnd, kStart, kEnd;

    for(iA1 = 0; iA1 < gridA->dimensions[0]; iA1++) {
        for(jA1 = 0; jA1 < gridA->dimensions[1]; jA1++) {
            for(kA1 = 0; kA1 < gridA->dimensions[2]; kA1++) {
                idxA1 = idx1d(gridA, iA1, jA1, kA1);
                elementA1 = gridA->elements[idxA1];
                if(elementA1 == NULL)
                    continue;

                if(gridB == NULL) {
                    // look for intra-element contacts
                    spatialPartitionFindContactsBetweenLists(elementA1, NULL, thingContact, args);

                    /*
                     * check contacts with everything in adjacent bins, = 26 bins in
                     * total (3^3 - 1). Do not need to check all 26 adjacent bins as the
                     * current bin will be an adjacent bin to bins already checked...
                     */
                    for(d = 0; d < 13; d++) {
                        iA2 = iA1 + ds[d][0];
                        jA2 = jA1 + ds[d][1];
                        kA2 = kA1 + ds[d][2];

                        if(idxInBounds(gridA, iA2, jA2, kA2) == 0) {
                            idxA2 = idx1d(gridA, iA2, jA2, kA2);
                            elementA2 = gridA->elements[idxA2];
                            if(elementA2 != NULL)
                                spatialPartitionFindContactsBetweenLists(elementA1, elementA2, thingContact, args);
                        }
                    }
                }
                else {
                    // if there's a second grid, look for contacts with things in equivalent element of gridB and all it's neighbours
                    idxToIdx(gridA, gridB, iA1, jA1, kA1, &iB1, &jB1, &kB1);
                    iStart = iB1 - 1;
                    iEnd   = iB1 + 1;
                    jStart = jB1 - 1;
                    jEnd   = jB1 + 1;
                    kStart = kB1 - 1;
                    kEnd   = kB1 + 1;
                    for(iB2 = iStart; iB2 <= iEnd; iB2++) {
                        for(jB2 = jStart; jB2 <= jEnd; jB2++) {
                            for(kB2 = kStart; kB2 <= kEnd; kB2++) {
                                //printf("[%02d, %02d, %02d] => [%02d, %02d, %02d]\n", iA1, jA1, kA1, iB2, jB2, kB2);
                                if(idxInBounds(gridB, iB2, jB2, kB2) == 0) {
                                    idxB2 = idx1d(gridB, iB2, jB2, kB2);
                                    elementB2 = gridB->elements[idxB2];
                                    //printf("idxA1 = %d (%s), idxB2 = %d (%s)\n", idxA1, (elementA1 == NULL) ? "no" : "yes", idxB2, (elementB2 == NULL) ? "no" : "yes");
                                    if(elementB2 != NULL)
                                        spatialPartitionFindContactsBetweenLists(elementA1, elementB2, thingContact, args);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return 0;
}

int spatialPartitionDelete(SPATIAL_PARTITION *grid) {
    int i;

    for(i = 0; i < grid->nElements; i++) {
        if(grid->elements[i] != NULL)
            listDelete(grid->elements[i], NULL);
    }
    free(grid->elements);
    free(grid);

    return 0;
}
