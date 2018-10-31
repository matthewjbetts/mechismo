#include "hash.h"

int main(int argc, char **argv) {
    HASH         *hash;
    int          i;
    char         *key;
    void         *value;
    char         *string;

    hash = hashCreate(0);
    if(hash == NULL)
        exit(1);

    for(i = 1; i < argc; i++) {
        key = argv[i];
        value = (void *) argv[i];
        hashAddElement(hash, key, value);
    }
    //hashOutput(hash, NULL);

    for(i = 2; i < argc; i++) {
        key = argv[i];
        value = hashGetElement(hash, key);
        string = (char *) value;
        if(strcmp(string, argv[i]) != 0) {
            fprintf(stderr, "Error: entry '%s' does not match.\n", argv[i]);
            exit(1);
        }
    }
    printf("nUniqueKeys = %d\n", hash->nKeys);

    hashDelete(hash, NULL);

    exit(0);
}
