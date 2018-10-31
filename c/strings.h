#if !defined(STRINGS_H)
#define STRINGS_H

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <zlib.h>
#include "list.h"

int stringRemoveSpaces(char *str1);
int stringSkipToNonSpace(char *string, int pointer);
float stringParse8_3f(char *str);
int stringInit(char **string, char *initialString);
int stringCat(char **string1, char *string2);
char *stringCopy(char *str);
int stringChomp(char *str);
char *stringStrtokSingle(char *string, char const *delims);
void *stringToInt(char *str);
void *stringToUnsignedInt(char *str);
void *stringToShort(char *str);
void *stringToDouble(char *str);
void *stringToString(char *str);
LIST *stringSplit(char *str, char const *delims, void *(*convert)(char *)); // 'convert' is a pointer to a function that returns a pointer to void
int stringDelete(void *thing);
char *stringCompress(const char *str);

#endif
