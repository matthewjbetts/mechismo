#include "alignment.h"

void usage() {
    fprintf(stderr, "\n");
    fprintf(stderr, "Usage: parse_alignment [options]\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "option    parameter  description                     default\n");
    fprintf(stderr, "--------  ---------  ------------------------------  -------\n");
    fprintf(stderr, "--help    [none]     print this usage info and exit\n");
    fprintf(stderr, "--fn      string     name of input file\n");
    fprintf(stderr, "--in      string     input format, one of:           fasta\n");
    fprintf(stderr, "                     - fasta");
 
    fprintf(stderr, "\n");
 
    exit(-1);
}

typedef struct args {
    char fn[FILENAMELEN];
    char inFormat[100];
} ARGS;

ARGS *getArgs(int argc, char **argv) {
    ARGS *args;
    int  i, j;
    int  len;

    if(argc <= 1)
        return NULL;

    // initialise defaults
    args = (ARGS *) malloc(sizeof(ARGS));
    if(args == NULL) {
        fprintf(stderr, "Error: main: malloc failed for args.\n");
        return NULL;
    }
    memset(args->fn, '\0', FILENAMELEN);
    strcpy(args->inFormat, "fasta");

    // parse args
    for(i = 1; i < argc; ++i) {
        len = strlen(argv[i]);

        if(argv[i][0] != '-')
            return NULL;

        j = (argv[i][1] == '-') ? 2 : 1; // allow for '--' style
        len -= j; // allow for short versions

        if(strncmp(&argv[i][j], "help", len) == 0) { 
            return NULL;
        }
        else if(strncmp(&argv[i][j], "fn", len) == 0) { 
            strncpy(args->fn, argv[++i], FILENAMELEN);
        }
        else if(strncmp(&argv[i][j], "in", len) == 0) { 
            strncpy(args->inFormat, argv[++i], 100);
        }
        else {
            return NULL;
        }
    }

    return args;
}

int main(int argc, char **argv) {
    ARGS      *args;
    MYFILE    *file;
    ALIGNMENT *aln;

    args = getArgs(argc, argv);
    if(args == NULL) 
        usage();

    file = myFileOpen(args->fn);
    if(file == NULL)
        exit(1);
    if(myFileRead(file) != 0)
        exit(-1);

    aln = alignmentParseFasta(file);
    alignmentOutputFasta(aln, stdout);

    alignmentDelete(aln);
    myFileDelete(file);
    free(args);

    exit(0);
}
