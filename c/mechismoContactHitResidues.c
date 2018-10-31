#include "myFile.h"
#include "contactHit.h"

int main(int argc, char **argv) {
    MYFILE     *file;
    CONTACTHIT *ch;
    char       *idLine;
    char       *cA2B2Line;
    char       *hspA1A2Line;
    char       *hspB2B1Line;

    if((file = myFileOpen("-")) == NULL) exit(1);
    if(myFileRead(file) != 0) exit(1);
    if((idLine = (*file->nextLine)(file)) == NULL) exit(1);
    if((cA2B2Line = (*file->nextLine)(file)) == NULL) exit(1);
    if((hspA1A2Line = (*file->nextLine)(file)) == NULL) exit(1);
    if((hspB2B1Line = (*file->nextLine)(file)) == NULL) exit(1);
    if((ch = contactHitParseSimple(idLine, cA2B2Line, hspA1A2Line, hspB2B1Line)) == NULL) exit(1);
    contactHitResiduesCreate(ch);
    contactHitResiduesOutput(ch, stdout);
    contactHitDelete(ch);

    exit(0);
}
