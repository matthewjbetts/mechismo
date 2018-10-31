#include "myFile.h"

int main(int argc, char **argv) {
    MYFILE *file;
    int    i;
    char   *line;

    for(i = 1; i < argc; i++) {
        // reading the whole file line-by-line
        file = myFileOpen(argv[i]);
        if(file == NULL)
            exit(-1);

        line = (*file->nextLine)(file);
        while(line != NULL) {
            printf("%s\n", line);
            line = (*file->nextLine)(file);
        }

        myFileDelete(file);

        // reading the whole file in to memory
        /*
        file = myFileOpen(argv[i]);
        if(file == NULL)
            exit(-1);
        if(myFileRead(file) != 0)
            exit(-1);

        line = (*file->nextLine)(file);
        while(line != NULL) {
            printf("%s\n", line);
            line = (*file->nextLine)(file);
        }

        myFileDelete(file);
        */
    }

    exit(0);
}
