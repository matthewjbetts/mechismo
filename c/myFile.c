#include "myFile.h"
#include "strings.h"
#include <errno.h>

/*
 * FIXME
 *
 * add a member 'nextLine' to MYFILE structure that is a pointer to function
 * that either returns the next line from an existing split-in-to-lines from
 * myFileOpen, or the next line from a one-chunk-at-a-time read.
 *
 */

char *myFileNextLineFromArray(MYFILE *self) {
    char   *line;

    if(self->next < self->lines->n) {
        line = (char *) self->lines->all[self->next];
        self->next++;
    }
    else {
        return NULL;
    }

    return line;
}

char *myFileNextLineFromGzStream(MYFILE *self) {
    if(gzgets(self->fh, self->buffer, CHUNK) == Z_NULL)
        return NULL;
    else
        stringChomp(self->buffer); // remove training new line

    return self->buffer;
}

char *myFileNextLineFromNormalStream(MYFILE *self) {
    if(fgets(self->buffer, CHUNK, self->fh) == NULL)
        return NULL;
    else
        stringChomp(self->buffer); // remove training new line

    return self->buffer;
}

int myFileRewind(MYFILE *self) {
    self->next = 0;

    return 0;
}

int myFileCannotRewind(MYFILE *self) {
    fprintf(stderr, "Error: can only rewind files that have been read entirely in to memory.\n");
    return 1;
}

MYFILE *myFileCreate(char *name) {
    MYFILE *file;

    file = (MYFILE *) malloc(sizeof(MYFILE));
    if(file == NULL) {
        fprintf(stderr, "Error: myFileCreate: malloc failed.\n");
        return NULL;
    }

    if(stringInit(&(file->name), name) != 0) {
        myFileDelete(file);
        return NULL;
    }

    file->buffer = (char *) malloc(CHUNK * sizeof(char));
    if(file->buffer == NULL) {
        fprintf(stderr, "Error: myFileCreate: malloc failed for file '%s'.\n", file->name);
        myFileDelete(file);
        return NULL;
    }
    file->size = 0;
    file->lines = listCreate(NULL);
    if(file->lines == NULL) {
        myFileDelete(file);
        return NULL;
    }
    file->next = 0;
    file->nextLine = NULL;
    file->rewind = &myFileCannotRewind;

    return file;
}

int myFileDelete(MYFILE *file) {
    if(file->buffer != NULL)
        free(file->buffer);
    listDelete(file->lines, NULL);
    if(file->fh != NULL)
        myFileClose(file);
    free(file->name);
    free(file);

    return 0;
}

MYFILE *myFileOpen(char *fileName) {
    MYFILE *file;

    file = myFileCreate(fileName);
    if(file == NULL)
        return NULL;

    if(
       ((strlen(file->name) > 3) && (strcmp(&file->name[strlen(file->name) - 3], ".gz") == 0)) ||
       ((strlen(file->name) > 2) && (strcmp(&file->name[strlen(file->name) - 2], ".Z") == 0))
       ) {
        file->fh = gzopen(file->name, "rb");
        //printf("myFileOpen\t%s\t%d\n", file->name, file->fh);
        if(file->fh == NULL) {
            if(errno == EMFILE)
                fprintf(stderr, "Error: myFileOpen: cannot open '%s' file for reading: too many open files.\n", file->name);
            else 
                fprintf(stderr, "Error: myFileOpen: cannot open '%s' file for reading.\n", file->name);
            myFileDelete(file);
            return NULL;
        }
        file->nextLine = &myFileNextLineFromGzStream;
    }
    else if(strcmp(file->name, "-") == 0) {
        file->fh = stdin;
        file->nextLine = &myFileNextLineFromNormalStream;
    }
    else {
        file->fh = fopen(file->name, "r");
        if(file->fh == NULL) {
            fprintf(stderr, "Error: myFileOpen: cannot open '%s' file for reading.\n", file->name);
            myFileDelete(file);
            return NULL;
        }
        file->nextLine = &myFileNextLineFromNormalStream;
    }

    return file;
}

int myFileClose(MYFILE *file) {
    int ret;

    //printf("myFileClose\t%s\t%d\n", file->name, file->fh);
    if((strcmp(&file->name[strlen(file->name) - 3], ".gz") == 0) || (strcmp(&file->name[strlen(file->name) - 2], ".Z") == 0)) {
        ret = gzclose(file->fh);
        //printf("ret = %d\n", ret);
        switch(ret) {
        case Z_OK:// success
            break;
        case Z_STREAM_ERROR:
            fprintf(stderr, "Error: myFileClose: error reading file '%s': is not a valid gz file.\n", file->name);
            return 1;
        case Z_ERRNO:
            fprintf(stderr, "Error: myFileClose: error reading file '%s': operation error.\n", file->name);
            return 1;
        case Z_MEM_ERROR:
            fprintf(stderr, "Error: myFileClose: error reading file '%s': out of memory.\n", file->name);
            return 1;
        case Z_BUF_ERROR:
            fprintf(stderr, "Error: myFileClose: error reading file '%s': the last read ended in the middle of a gzip stream.\n", file->name);
            return 1;
        default: // success
            break;
        }
    }
    else if(strcmp(file->name, "-") != 0) { // not stdin
        if(fclose(file->fh) != 0) {
            fprintf(stderr, "Error: myFileClose: '%s' file not closed properly.\n", file->name);
            return 1;
        }
    }
    file->fh = NULL;

    return 0;
}

int myFileRead(MYFILE *file) {
    // reads entire contents of file->name in to memory and breaks it in to lines

    long   nRead;
    char   buff[CHUNK];
    int    bytesRead;
    long   p;
    char   *line;

    file->nextLine = &myFileNextLineFromArray;
    file->rewind = &myFileRewind;
    if(
       ((strlen(file->name) > 3) && (strcmp(&file->name[strlen(file->name) - 3], ".gz") == 0)) ||
       ((strlen(file->name) > 2) && (strcmp(&file->name[strlen(file->name) - 2], ".Z") == 0))
       ) {
        file->size = 0;

        p = 0;
        do {
            memset(buff, '\0', CHUNK);
            bytesRead = gzread(file->fh, buff, CHUNK);
            if(bytesRead == -1) {
                fprintf(stderr, "Error: myFileRead: gzread failed for '%s'.\n", file->name);
                myFileClose(file);
                myFileDelete(file);
                return 1;
            }
            file->size += bytesRead;

            file->buffer = (char *) realloc(file->buffer, file->size * sizeof(char));
            if(file->buffer == NULL) {
                fprintf(stderr, "Error: myFileRead: realloc failed for file '%s'.\n", file->name);
                myFileDelete(file);
                return 1;
            }
            memcpy(file->buffer + p, buff, bytesRead);
            p += bytesRead;
        } while(bytesRead != 0);
    }
    else if(strcmp(file->name, "-") == 0) {
        file->size = 0;
        /*
        file->buffer = (char *) malloc(CHUNK * sizeof(char));
        if(file->buffer == NULL) {
            fprintf(stderr, "Error: myFileRead: malloc failed for file '%s'.\n", file->name);
            myFileDelete(file);
            return 1;
        }
        */

        p = 0;
        do {
            memset(buff, '\0', CHUNK);
            nRead = fread(buff, sizeof(char), CHUNK, file->fh);

            if(ferror(file->fh) != 0) {
                fprintf(stderr, "Error: myFileRead: error reading file '%s'.\n", file->name);
                myFileDelete(file);
                return 1;
            }

            file->size += nRead;

            file->buffer = (char *) realloc(file->buffer, file->size * sizeof(char));
            if(file->buffer == NULL) {
                fprintf(stderr, "Error: myFileRead: realloc failed for file '%s'.\n", file->name);
                myFileDelete(file);
                return 1;
            }
            memcpy(file->buffer + p, buff, nRead);
            p += nRead;
        } while(nRead == CHUNK);
    }
    else {
        // get size of the file contents
        if(fseek(file->fh, 0, SEEK_END) != 0) {
            fprintf(stderr, "Error: myFileRead: fseek to end of file '%s' failed.\n", file->name);
            myFileDelete(file);
            return 1;
        }
        file->size = ftell(file->fh);
        if(file->size == -1L) {
            fprintf(stderr, "Error: myFileRead: ftell on file '%s' failed.\n", file->name);
            myFileDelete(file);
            return 1;
        }

        // read contents in to a buffer of appropriate size
        if(fseek(file->fh, 0, SEEK_SET) != 0) {
            fprintf(stderr, "Error: myFileRead: fseek to beginning of file '%s' failed.\n", file->name);
            myFileDelete(file);
            return 1;
        }

        file->buffer = (char *) realloc(file->buffer, file->size * sizeof(char));
        if(file->buffer == NULL) {
            fprintf(stderr, "Error: myFileRead: realloc failed for file '%s'.\n", file->name);
            myFileDelete(file);
            return 1;
        }

        nRead = fread(file->buffer, sizeof(char), file->size, file->fh);
        if(nRead != file->size) {
            fprintf(stderr, "Error: myFileRead: requested %ld characters from file '%s', read %ld.\n", file->size, file->name, nRead);
            myFileDelete(file);
            return 1;
        }
        if(ferror(file->fh) != 0) {
            fprintf(stderr, "Error: myFileRead: error reading file '%s'.\n", file->name);
            myFileDelete(file);
            return 1;
        }
    }

    // make sure the buffer ends with '\0'
    file->size++;
    file->buffer = (char *) realloc(file->buffer, file->size * sizeof(char));
    if(file->buffer == NULL) {
        fprintf(stderr, "Error: myFileRead: realloc failed for file '%s'.\n", file->name);
        myFileDelete(file);
        return 1;
    }
    file->buffer[file->size - 1] = '\0';

    // split in to lines

    // FIXME - add newline back on end of each line

    line = stringStrtokSingle(file->buffer, "\n");
    while(line != NULL) {
        listAddElement(file->lines, 1, line);
        line = stringStrtokSingle(NULL, "\n");
    }

    return 0;
}

FILE *myFileOpenWrite(char *filename, char *type) {
    FILE *handle;
    char command[1000];

    memset(command, '\0', 1000);

    // FIXME - use zlib.h and merge in to myFileOpen

    if(strcmp(type, "w") == 0) {
        if(strcmp(&filename[strlen(filename) - 3], ".gz") == 0) {
            // sprintf(command,"gunzip -c %s 2> /dev/null",filename);
            sprintf(command, "gzip > %s", filename); 
            handle = popen(command, "w");
        }
        else {
            handle = fopen(filename, "w");
        }
    }
    else if(strcmp(type, "a+")) {
        // no compression
        handle = fopen(filename, "a");
    }
    else {
        fprintf(stderr, "Error: myFileOpenWrite: unrecognised type '%s'.\n", type);
    }

    return handle;
}
