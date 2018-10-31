#include "strings.h"

int stringRemoveSpaces(char *str1) {
    int  len;
    char *str2;
    int  i, j;

    len = strlen(str1) + 1;
    str2 = (char *) malloc(len * sizeof(char));
    if(str2 == NULL) {
        fprintf(stderr, "Error: stringRemoveSpaces: malloc failed.\n");
        return 1;
    }
    strcpy(str2, str1);
    memset(str1, '\0', len);
    
    for(i = 0, j = 0; i < len; ++i) {
        if(!isspace(str2[i])) {
            str1[j++] = str2[i];
        }
    }
    free(str2);

    return 0;
};

int stringSkipToNonSpace(char *string, int pointer) {
    while(string[pointer] != ' ' && string[pointer] != '\0' && string[pointer] != '\n')
        pointer++;

    if(string[pointer] == '\0')
        return -1;

    while(string[pointer] == ' ' && string[pointer] != '\0' && string[pointer] != '\n')
        pointer++;

    if(string[pointer] == '\0')
        return -1;

    return pointer;
}

float stringParse8_3f(char *str) {
    float sign;
    float f;
    int   i;
    float pow10;

    // skip leading spaces if any
    while(*str == ' ')
        ++str;

    // get sign if any
    if(*str == '-') {
        sign = -1.0;
        str += 1;
    }
    else if(*str == '+') {
        sign = +1.0;
        str += 1;
    }
    else {
        sign = +1.0;
    }

    // read numbers before decimal point
    for(f = 0.0; *str != '.'; str += 1) {
        f = f * 10.0 + (*str - '0'); // "- '0'" for implicit cast of char to float
    }
    str += 1;

    // read numbers after decimal point
    for(i = 0, pow10 = 10.0; i < 3; ++i, ++str) {
        f += (*str - '0') / pow10;
        pow10 *= 10.0;
    }

    f *= sign;

    return f;
}

int stringInit(char **string, char *initialString) {
    int initialLen;

    initialLen = strlen(initialString) + 1; // inc. '\0'

    *string = (char *) malloc(initialLen * sizeof(char));
    if(*string == NULL) {
        fprintf(stderr, "Error: stringInit: malloc failed.\n");
        return 1;
    }
    memset(*string, '\0', initialLen);
    strcpy(*string, initialString);

    return 0;
}

int stringCat(char **string1, char *string2) {
    int  len1;
    int  len2;
    int  len3;
    char *string3;

    len1 = strlen(*string1);
    len2 = strlen(string2);
    len3 = len1 + len2;
    string3 = (char *) realloc(*string1, (len3 + 1) * sizeof(char)); // '+ 1' because of '\0'
    if(string3 == NULL) {
        fprintf(stderr, "Error: stringCat: realloc failed.\n");
        return 1;
    }
    *string1 = string3;
    memcpy(*string1 + len1, string2, len2);
    (*string1)[len3] = '\0';

    return 0;
}

char *stringCopy(char *str) {
    int  len;
    char *copy;

    len = strlen(str) + 1; // '+ 1' because of '\0'
    copy = (char *) malloc(len * sizeof(char));
    if(copy == NULL) {
        fprintf(stderr, "Error: copyString: malloc failed.\n");
        return NULL;
    }
    strcpy(copy, str);

    return copy;
}

int stringChomp(char *str) {
    char *pos;

    if((pos = strchr(str, '\n')) != NULL)
        *pos = '\0';

    return 0;
}

char *stringStrtokSingle(char *string, char const *delims) {
    /*
     * strtok explicitly treats multiple characters as a single separator, so it will miss blank lines ("\n\n").
     * The following is from http://stackoverflow.com/questions/8705844/need-to-know-when-no-data-appears-between-two-token-separators-using-strtok
     */

    static char  *src = NULL;
    char         *p,  *ret = 0;

    if(string != NULL)
        src = string;

    if(src == NULL)
        return NULL;

    if((p = strpbrk(src, delims)) != NULL) {
        *p  = 0;
        ret = src;
        src = ++p;
    } else if (*src) {
        ret = src;
        src = NULL;
    }

    return ret;
}

/*
 * various conversions functions for use in stringSplit.
 * all return 'void *' to make them more easilt interchangeable,
 * and useable with LIST.
 */

void *stringToInt(char *str) {
    int *i;

    i = (int *) malloc(sizeof(int));
    if(i == NULL) {
        fprintf(stderr, "Error: stringToInt: malloc failed.\n");
        return NULL;
    }
    *i = atoi(str);

    return (void *) i;
}

void *stringToUnsignedInt(char *str) {
    unsigned int *i;

    i = (unsigned int *) malloc(sizeof(unsigned int));
    if(i == NULL) {
        fprintf(stderr, "Error: stringToUnsignedInt: malloc failed.\n");
        return NULL;
    }
    *i = (unsigned int) strtoul(str, NULL, 0);

    return (void *) i;
}

void *stringToShort(char *str) {
    short *i;

    i = (short *) malloc(sizeof(short));
    if(i == NULL) {
        fprintf(stderr, "Error: stringToShort: malloc failed.\n");
        return NULL;
    }
    *i = atoi(str);

    return (void *) i;
}

void *stringToDouble(char *str) {
    double *f;

    f = (double *) malloc(sizeof(double));
    if(f == NULL) {
        fprintf(stderr, "Error: stringToDouble: malloc failed.\n");
        return NULL;
    }
    *f = atof(str);

    return (void *) f;
}

void *stringToString(char *str) {
    char *str2;

    str2 = stringCopy(str);

    return (void *) str2;
}

LIST *stringSplit(char *str, char const *delims, void *(*convert)(char *)) {
    char *copy;
    LIST *tokens;
    char *token;

    /*
     * convert = pointer to function to convert the char * to something else, eg. a pointer to an interger
     */

    // copy the string so that the original string is not modified
    if((copy = stringCopy(str)) == NULL)
        return NULL;
    
    tokens = listCreate(NULL);
    if(tokens == NULL)
        return NULL;

    if(convert == NULL) {
        token = stringStrtokSingle(copy, delims);
        while(token != NULL) {
            listAddElement(tokens, 1, token);
            token = stringStrtokSingle(NULL, delims);
        }
        // tokens are pointers in to string 'copy', so don't free that now
    }
    else {
        token = stringStrtokSingle(copy, delims);
        while(token != NULL) {
            listAddElement(tokens, 1, (*convert)(token));
            token = stringStrtokSingle(NULL, delims);
        }
        free(copy);
    }

    return tokens;
}

int stringDelete(void *thing) {
    char *str;

    str = (char *) thing;
    free(str);

    return 0;
}

// stringCompress adapted from https://gist.github.com/arq5x/5315739
// FIXME - add stringUncompress (need to deal with malloc for uncompressed length)

char *stringCompress(const char *str) {
    int      len;
    char     *strCompressed;
    z_stream defstream;

    len = strlen(str) + 1; // string + terminator
    strCompressed = (char *) malloc(len * sizeof(char));
    if(strCompressed == NULL) {
        fprintf(stderr, "Error: stringCompress: malloc failed.");
        return NULL;
    }
    memset(strCompressed, '\0', len);

    // zlib struct
    defstream.zalloc = Z_NULL;
    defstream.zfree = Z_NULL;
    defstream.opaque = Z_NULL;

    // setup "a" as the input and "b" as the compressed output
    defstream.avail_in = (uInt) len; // size of input
    defstream.next_in = (Bytef *) str; // input char array
    defstream.avail_out = (uInt) len; // size of output
    defstream.next_out = (Bytef *) strCompressed; // output char array
    
    // the actual compression work.
    deflateInit(&defstream, Z_BEST_COMPRESSION);
    deflate(&defstream, Z_FINISH);
    deflateEnd(&defstream);
     
    return strCompressed;
}
