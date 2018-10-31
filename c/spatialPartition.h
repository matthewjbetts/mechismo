#if !defined(SPATIAL_PARTITION_H)
#define SPATIAL_PARTITION_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "sphere.h"
#include "list.h"

typedef struct spatial_partition {
    float minCoord[3];
    float maxCoord[3];
    float elementSize;
    int   dimensions[3];
    int   nElements;
    LIST  **elements;
} SPATIAL_PARTITION;

SPATIAL_PARTITION *spatialPartitionCreate(LIST *list, SPHERE *(*thingSphere)(void *), float maxDist, float rMax, float minCoord[3], float maxCoord[3]);
int spatialPartitionOutput(SPATIAL_PARTITION *grid, char *name, int (*thingOutput)(void *thing));
int spatialPartitionFindContacts(SPATIAL_PARTITION *grid1, SPATIAL_PARTITION *grid2, int (*thingContact)(void *thing1, void *thing2, LIST *args), LIST *args);
int spatialPartitionDelete(SPATIAL_PARTITION *grid);

#endif
