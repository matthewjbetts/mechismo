#if !defined(HASH_H)
#define HASH_H

#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "list.h"
#include "strings.h"
#include "myFile.h"

typedef struct key_value_pair {
    char *key;
    void *value;
} KEYVALUEPAIR;

typedef struct hash {
    LIST         **elements;
    unsigned int nKeys, size;
} HASH;

HASH *hashCreate(unsigned int size);
HASH *hashParseTsv(char *fileName, void *(*convert)(char *));
int hashDelete(HASH *hash, int (*deleteKeyValuePair)(void *));
int hashDeleteTsv(HASH *hash);
int hashDeleteList(void *thing);
int hashResize(HASH *hash, unsigned int sizeNew);
int hashAddElement(HASH *hash, const char *key, void *value);
void *hashGetElement(HASH *hash, const char *key);
int hashOutput(HASH *hash, int valueOutput(void *value));
LIST *hashGetAllKeys(HASH *hash);
LIST *hashGetAllValues(HASH *hash);
int hash2DAddElement(HASH *hash1, const char *key1, const char *key2, void *value);
void *hash2DGetElement(HASH *hash1, const char *key1, const char *key2);

#endif
