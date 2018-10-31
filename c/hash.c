#include <limits.h>
#include "hash.h"

#define MINHASHSIZE 2
#define MAXHASHLOAD 0.75

/********************************************************************************/
/*
 * This hashing function adapted from 'SuperFastHash', which I
 * copied from http://www.azillionmonkeys.com/qed/hash.html,
 * which was licensed under LGPL 2.1 (http://www.gnu.org/licenses/lgpl-2.1.txt)
 * (I only changed some variable names...)
 */

#undef get16bits
#if (defined(__GNUC__) && defined(__i386__)) || defined(__WATCOMC__) \
  || defined(_MSC_VER) || defined (__BORLANDC__) || defined (__TURBOC__)
#define get16bits(d) (*((const uint16_t *) (d)))
#endif

#if !defined (get16bits)
#define get16bits(d) ((((uint32_t)(((const uint8_t *)(d))[1])) << 8)\
                       +(uint32_t)(((const uint8_t *)(d))[0]) )
#endif

int keyToIdx(HASH *hash, const char *key) {
    uint32_t idx, tmp;
    uint32_t keyLen;
    int rem;

    if(key == NULL) {
        fprintf(stderr, "Error: keyToIdx: can't get idx of NULL key.\n");
        return 0;
    }

    keyLen = strlen(key);
    if(keyLen <= 0)
        return 0;
    
    idx = keyLen;

    rem = keyLen & 3;
    keyLen >>= 2;

    /* Main loop */
    for(; keyLen > 0; keyLen--) {
        idx += get16bits (key);
        tmp  = (get16bits (key + 2) << 11) ^ idx;
        idx  = (idx << 16) ^ tmp;
        key += 2 * sizeof (uint16_t);
        idx += idx >> 11;
    }

    /* Handle end cases */
    switch (rem) {
        case 3: idx += get16bits(key);
                idx ^= idx << 16;
                idx ^= ((signed char)key[sizeof (uint16_t)]) << 18;
                idx += idx >> 11;
                break;
        case 2: idx += get16bits(key);
                idx ^= idx << 11;
                idx += idx >> 17;
                break;
        case 1: idx += (signed char)*key;
                idx ^= idx << 10;
                idx += idx >> 1;
    }

    /* Force "avalanching" of final 127 bits */
    idx ^= idx << 3;
    idx += idx >> 5;
    idx ^= idx << 4;
    idx += idx >> 17;
    idx ^= idx << 25;
    idx += idx >> 6;

    // convert to a number in the range of the Hash size
    idx = idx % hash->size;

    return((int) idx);
}
/********************************************************************************/

KEYVALUEPAIR *createKeyValuePair(const char *key, void *value) {
    KEYVALUEPAIR *kvp;
    int          keyLen;

    kvp = (KEYVALUEPAIR *) malloc(sizeof(KEYVALUEPAIR));
    if(kvp == NULL) {
        fprintf(stderr, "Error: createKvp: malloc failed.\n");
        return NULL;
    }

    kvp->value = value;

    /*
     * need to copy the key rather than just assign otherwise later
     * re-use of the same pointer will change the key here too...
     */
    keyLen = strlen(key) + 1; // inc. '\0' at end
    kvp->key = (char *) malloc(keyLen * sizeof(char));
    if(kvp->key == NULL) {
        fprintf(stderr, "Error: createKvp: malloc failed.\n");
        return NULL;
    }
    strcpy(kvp->key, key);

    return kvp;
}

int deleteKVP(void *thing) {
    KEYVALUEPAIR *kvp;

    kvp = (KEYVALUEPAIR *) thing;
    free(kvp->key);
    free(kvp);

    return 0;
}

int deleteKVPincValue(void *thing) {
    KEYVALUEPAIR *kvp;

    kvp = (KEYVALUEPAIR *) thing;
    free(kvp->key);
    free(kvp->value);
    free(kvp);

    return 0;
}

HASH *hashCreate(unsigned int size) {
    HASH *hash;
    int  idx;

    if(size < MINHASHSIZE)
        size = MINHASHSIZE;

    hash = (HASH *) malloc(sizeof(HASH));
    if(hash == NULL) {
        fprintf(stderr, "Error: hashCreate: malloc failed.\n");
        return NULL;
    }
    hash->size = size;

    hash->elements = (LIST **) malloc(hash->size * sizeof(LIST *));
    if(hash->elements == NULL) {
        fprintf(stderr, "Error: hashCreate: malloc failed.\n");
        return NULL;
    }
    for(idx = 0; idx < hash->size; idx++) {
        hash->elements[idx] = NULL;
    }
    hash->nKeys = 0;

    return hash;
}

HASH *hashParseTsv(char *fileName, void *(*convert)(char *)) {
    MYFILE *file;
    HASH   *hash;
    char   *line;
    LIST   *tokens;
    int    i;
    void   *key;
    void   *value;

    file = myFileOpen(fileName);
    if(file == NULL)
        exit(-1);
    if(myFileRead(file) != 0)
        exit(-1);

    if((hash = hashCreate(0)) == NULL) {
        myFileDelete(file);
        return NULL;
    }

    if(convert == NULL)
        convert = &stringToString;

    line = (*file->nextLine)(file);
    while(line != NULL) {
        if((tokens = stringSplit(line, "\t", NULL)) != NULL) {
            key = tokens->all[0]; // keys are always strings
            for(i = 1; i < tokens->n; i++) {
                value = (*convert)(tokens->all[i]);
                hashAddElement(hash, key, value);
                break; // just getting the second column
            }
            free(tokens->all[0]); // subsequent elements are just pointers in to a block of memory from the same malloc
            listDelete(tokens, NULL);
        }
        line = (*file->nextLine)(file);
    }

    myFileDelete(file);

    return hash;
}

int hashDeleteMembers(HASH *hash, int (*deleteKeyValuePair)(void *)) {
    int i;

    // doing this separately from free(hash) so that I can use the same hash pointer after resizing
    if(deleteKeyValuePair == NULL)
        deleteKeyValuePair = &deleteKVP;

    for(i = 0; i < hash->size; i++) {
        if(hash->elements[i] != NULL)
            listDelete(hash->elements[i], deleteKeyValuePair);
    }
    free(hash->elements);
    hash->elements = NULL;
    hash->nKeys = 0;

    return 1;
}

int hashDelete(HASH *hash, int (*deleteKeyValuePair)(void *)) {
    hashDeleteMembers(hash, deleteKeyValuePair);
    free(hash);

    return 0;
}

int hashDeleteTsv(HASH *hash) {
    hashDeleteMembers(hash, deleteKVPincValue);
    free(hash);

    return 0;
}

int hashDeleteList(void *thing) {
    KEYVALUEPAIR *kvp;

    kvp = (KEYVALUEPAIR *) thing;
    free(kvp->key);
    listDelete(kvp->value, NULL);
    free(kvp);

    return 0;
}

int hashResize(HASH *hash, unsigned int sizeNew) {
    HASH         *hash2;
    uint32_t     idx;
    LIST         *list;
    KEYVALUEPAIR *kvp;
    int          i;

    // create a new hash of given size and move values to it
    //printf("hashResize: n_keys = %d, size = %d, load = %f, new size = %d\n", hash->nKeys, hash->size, (float) hash->nKeys / hash->size, sizeNew);
    hash2 = hashCreate(sizeNew);
    for(idx = 0; idx < hash->size; idx++) {
        list = hash->elements[idx];
        if(list != NULL) {
            for(i = 0; i < list->n; i++) {
                kvp = (KEYVALUEPAIR *) list->all[i];
                hashAddElement(hash2, kvp->key, kvp->value);
            }
        }
    }
    hashDeleteMembers(hash, NULL);
    hash->elements = hash2->elements;
    hash->nKeys = hash2->nKeys;
    hash->size = hash2->size;
    free(hash2);

    return 0;
}

int hashAddElement(HASH *hash, const char *key, void *value) {
    uint32_t     idx;
    LIST         *list;
    KEYVALUEPAIR *kvp;
    void         *oldValue;
    int          i;
    float        load;

    load = (float) hash->nKeys / hash->size;
    if((hash->nKeys > MINHASHSIZE) && (load > MAXHASHLOAD)) {
        if(hashResize(hash, (hash->size + 1) * 2) != 0) return 1;
    }

    // stores values in LIST objects, in case multiple keys map to the same idx
    // FIXME - a binary tree might be better, if their are a lot of collisions (different keys mapping to the same idx)

    idx = keyToIdx(hash, key);
    //printf("hashAddElement: key = '%s', idx = %d\n", key, idx);

    list = hash->elements[idx];
    oldValue = NULL; // the same key might be used twice
    if(list == NULL) {
        list = listCreate(NULL);
        if(list == NULL)
            return 1;
        hash->elements[idx] = list;
    }
    else {
        // check to see whether this key has already been used
        for(i = 0; i < list->n; i++) {
            kvp = (KEYVALUEPAIR *) list->all[i];
            if(strcmp(kvp->key, key) == 0) {
                oldValue = kvp->value;
                kvp->value = value;
                break;
            }
        }
    }

    if(oldValue == NULL) {
        kvp = createKeyValuePair(key, value);
        listAddElement(list, 1, kvp);
        hash->nKeys++;
    }

    return 0;
}

void *hashGetElement(HASH *hash, const char *key) {
    void         *value;
    uint32_t     idx;
    LIST         *list;
    int          i;
    KEYVALUEPAIR *kvp;

    value = NULL;
    if((idx = keyToIdx(hash, key)) < hash->size) {
        list = hash->elements[idx];
        if(list != NULL) {
            // now find the particular pair from the set whose keys all map to this idx
            for(i = 0; i < list->n; i++) {
                kvp = (KEYVALUEPAIR *) list->all[i];
                if(strcmp(kvp->key, key) == 0) {
                    //printf("kvp->key = '%s', key = '%s'\n", kvp->key, key);
                    value = kvp->value;
                    break;
                }
            }
        }
    }

    return value;
}

int hashOutput(HASH *hash, int valueOutput(void *value)) {
    int  idx;
    LIST *list;
    int  i;

    for(idx = 0; idx < hash->size; idx++) {
        list = hash->elements[idx];
        if(list == NULL)
            continue;
        printf("[%d], n = %d\n", idx, list->n);
        if(valueOutput == NULL)
            continue;
        for(i = 0; i < list->n; i++)
            valueOutput(list->all[i]);
    }

    return 1;
}

LIST *hashGetAllKeys(HASH *hash) {
    LIST         *keys;
    LIST         *list;
    int          i, j;
    KEYVALUEPAIR *kvp;
    char         *key;
    
    if((keys = listCreate(NULL)) == NULL)
        return NULL;

    for(i = 0; i < hash->size; i++) {
        if((list = hash->elements[i]) == NULL) continue;
        for(j = 0; j < list->n; j++) {
            kvp = (KEYVALUEPAIR *) list->all[j];
            key = kvp->key;
            listAddElement(keys, 1, key);
        }
    }

    return keys;
}

LIST *hashGetAllValues(HASH *hash) {
    LIST         *values;
    LIST         *list;
    int          i, j;
    KEYVALUEPAIR *kvp;
    void         *value;
    
    if((values = listCreate(NULL)) == NULL)
        return NULL;

    for(i = 0; i < hash->size; i++) {
        if((list = hash->elements[i]) == NULL) continue;
        for(j = 0; j < list->n; j++) {
            kvp = (KEYVALUEPAIR *) list->all[j];
            value = kvp->value;
            listAddElement(values, 1, value);
        }
    }

    return values;
}

int hash2DAddElement(HASH *hash1, const char *key1, const char *key2, void *value) {
    HASH *hash2;

    if((hash2 = (HASH *) hashGetElement(hash1, key1)) == NULL) {
        if((hash2 = hashCreate(0)) == NULL)
            return 1;
        hashAddElement(hash1, key1, hash2);
    }
    hashAddElement(hash2, key2, value);

    return 0;
}

void *hash2DGetElement(HASH *hash1, const char *key1, const char *key2) {
    HASH *hash2;

    if((hash2 = (HASH *) hashGetElement(hash1, key1)) == NULL)
        return NULL;
    return hashGetElement(hash2, key2);
}
