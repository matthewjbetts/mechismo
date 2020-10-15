#if !defined(LIST_H)
#define LIST_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

typedef struct list {
    char         *name;
    void         **all;
    unsigned int id;
    unsigned int n;
} LIST;

LIST *listCreate(char *name);
int listAddElement(LIST *list, int argc, ...);
int listDelete(LIST * list, int (*deleteThing)(void *thing));
void *listShift(LIST *list);
int listSort(LIST *list, int (*cmp)(const void *, const void *));
int listSortById(const void *a, const void *b);
int listSortByAscN(const void *a, const void *b);
int listSortByDescN(const void *a, const void *b);
int listDeleteList(void *thing);

#endif
