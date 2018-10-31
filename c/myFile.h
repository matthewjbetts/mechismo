#if !defined(FILE_H)
#define FILE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>
#include "list.h"

#define FILENAMELEN 4096
#define CHUNK 1048576

typedef struct myfile {
    char         *name;
    FILE         *fh;
    char         *buffer;
    long         size;
    LIST         *lines;
    unsigned int next;
    char         *(*nextLine)(struct myfile *self);
    int          (*rewind)(struct myfile *self);
} MYFILE;

MYFILE *myFileCreate();
int myFileDelete(MYFILE *file);
MYFILE *myFileOpen(char *fileName);
int myFileClose(MYFILE *file);
int myFileRead(MYFILE *file);
FILE *myFileOpenWrite(char *filename, char *type);

#endif

