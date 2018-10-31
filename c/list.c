#include "list.h"

LIST *listCreate(char *name) {
    LIST *list;

    list = (LIST *) malloc(sizeof(LIST));
    if(list == NULL) {
        fprintf(stderr, "Error: listCreate: malloc failed.\n");
        return NULL;
    }
    list->id = 0;

    if(name == NULL) {
        list->name = NULL;
    }
    else {
        list->name = (char *) malloc((strlen(name) + 1) * sizeof(char));
        if(list->name == NULL) {
            fprintf(stderr, "Error: listCreate: malloc failed.\n");
            return NULL;
        }
        strcpy(list->name, name);
    }

    list->all = (void **) malloc(sizeof(void *));
    if(list->all == NULL) {
        fprintf(stderr, "Error: listCreate: malloc failed.\n");
        return NULL;
    }
    list->n = 0;

    return list;
}

int listAddElement(LIST *list, int argc, ...) {
    va_list args;
    int     i, j;
    void    **allNew;

    va_start(args, argc);

    i = list->n;
    list->n += argc;

    if((allNew = (void **) realloc(list->all, list->n * sizeof(void *))) == NULL) {
        fprintf(stderr, "Error: listAddElement: realloc failed\n");
        return 1;
    }
    list->all = allNew;

    for(j = 0; j < argc; j++, i++) {
        list->all[i] = (void *) va_arg(args, void *);
    }
    va_end(args);

    return 0;
}

void *listShift(LIST *list) {
    void         *thing;
    unsigned int n1, n2;
    void         **allNew;

    n1 = list->n;
    if(n1 == 0)
        return NULL;

    thing = list->all[0];
    n2 = n1 - 1;
    if(n2 > 0) {
        memmove(list->all, list->all + 1, n2 * sizeof(void *));
        list->n = n2;

        if((allNew = (void **) realloc(list->all, list->n * sizeof(void *))) == NULL) {
            fprintf(stderr, "Error: listShift: realloc failed\n");
            return NULL;
        }
        list->all = allNew;
    }
    else {
        list->all[0] = NULL;
        list->n = 0;
    }

    return thing;
}

int listDelete(LIST *list, int (*deleteThing)(void *)) {
    int i;

    if(list->name != NULL) free(list->name);
    if(deleteThing != NULL) {
        for(i = 0; i < list->n; i++) {
            (*deleteThing)(list->all[i]);
        }
    }
    free(list->all);
    free(list);

    return 0;
}

int listSort(LIST *list, int (*cmp)(const void *, const void *)) {
    qsort((const void **) list->all, list->n, sizeof(void *), cmp);

    return 0;
}

int listSortById(const void *a, const void *b) {
    const LIST *la = *(const LIST **) a;
    const LIST *lb = *(const LIST **) b;

    if(la->id < lb->id) {
        return -1;
    }
    else if(la->id > lb->id) {
        return 1;
    }

    return 0;
}

int listDeleteList(void *thing) {
    LIST *group;

    // frees memory used by a list element that is itself a list

    group = (LIST *) thing;
    listDelete(group, NULL);

    return 0;
}

