# Makefile for building contacts

CC = gcc
CCFLAGS = -O2 # for speed
#CCFLAGS = -Wall -g # for debugging

# NOTE: binaries to be installed are now prefixed with 'mechismo', to avoid
# confusion with otherwise similarly named binaries elsewhere in the path

INSTALLBINARIES = mechismoContactHitResidues mechismoContactHits mechismoGroupContacts mechismoContacts
TESTBINARIES = testAlignment testHash testMyFile
BINARIES = ${INSTALLBINARIES} ${TESTBINARIES}
OBJECTS = mechismoContactHitResidues.o mechismoContactHits.o mechismoGroupContacts.o mechismoContacts.o contact.o pdb.o testAlignment.o alignment.o testHash.o hash.o testMyFile.o myFile.o spatialPartition.o maths.o strings.o list.o

LIBDIRS =
INCLUDE = -I.
LIBS    = -lm -lz

.PHONY: all
all: $(OBJECTS) $(BINARIES)

# CONTACTS

mechismoContactHitResidues: Makefile mechismoContactHitResidues.o contactHit.o contact.o pdb.o spatialPartition.o maths.o myFile.o list.o strings.o hash.o alignment.o
	$(CC) $(CCFLAGS) $(INCLUDE) -o mechismoContactHitResidues mechismoContactHitResidues.o contactHit.o contact.o pdb.o spatialPartition.o maths.o myFile.o list.o strings.o hash.o alignment.o $(LIBDIRS) $(LIBS)

mechismoContactHits: Makefile mechismoContactHits.o contactHit.o contact.o pdb.o spatialPartition.o maths.o myFile.o list.o strings.o hash.o alignment.o
	$(CC) $(CCFLAGS) $(INCLUDE) -o mechismoContactHits mechismoContactHits.o contactHit.o contact.o pdb.o spatialPartition.o maths.o myFile.o list.o strings.o hash.o alignment.o $(LIBDIRS) $(LIBS)

mechismoContactHitResidues.o: Makefile mechismoContactHitResidues.c
	$(CC) $(CCFLAGS) $(INCLUDE) -c mechismoContactHitResidues.c

mechismoContactHits.o: Makefile mechismoContactHits.c
	$(CC) $(CCFLAGS) $(INCLUDE) -c mechismoContactHits.c

contactHit.o: Makefile contactHit.c contactHit.h strings.h hash.h list.h alignment.h contact.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c contactHit.c

mechismoGroupContacts: Makefile mechismoGroupContacts.o contact.o pdb.o spatialPartition.o maths.o myFile.o list.o strings.o hash.o alignment.o
	$(CC) $(CCFLAGS) $(INCLUDE) -o mechismoGroupContacts mechismoGroupContacts.o contact.o pdb.o spatialPartition.o maths.o myFile.o list.o strings.o hash.o alignment.o $(LIBDIRS) $(LIBS)

mechismoGroupContacts.o: Makefile mechismoGroupContacts.c
	$(CC) $(CCFLAGS) $(INCLUDE) -c mechismoGroupContacts.c

mechismoContacts: Makefile mechismoContacts.o contact.o pdb.o spatialPartition.o myFile.o list.o maths.o strings.o alignment.o hash.o
	$(CC) $(CCFLAGS) $(INCLUDE) -o mechismoContacts mechismoContacts.o contact.o pdb.o spatialPartition.o myFile.o list.o maths.o strings.o alignment.o hash.o $(LIBDIRS) $(LIBS)

mechismoContacts.o: Makefile mechismoContacts.c
	$(CC) $(CCFLAGS) $(INCLUDE) -c mechismoContacts.c

contact.o: Makefile contact.c contact.h pdb.o spatialPartition.o myFile.o sphere.h list.o maths.o alignment.o hash.o
	$(CC) $(CCFLAGS) $(INCLUDE) -c contact.c

pdb.o: Makefile pdb.c pdb.h myFile.o spatialPartition.o sphere.h list.o strings.o maths.o
	$(CC) $(CCFLAGS) $(INCLUDE) -c pdb.c

# ALIGNMENTS

testAlignment: Makefile testAlignment.o alignment.o myFile.o hash.o list.o strings.o
	$(CC) $(CCFLAGS) $(INCLUDE) -o testAlignment testAlignment.o alignment.o myFile.o hash.o list.o strings.o $(LIBDIRS) $(LIBS)

testAlignment.o: Makefile testAlignment.c alignment.h myFile.h strings.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c testAlignment.c

alignment.o: Makefile alignment.c alignment.h myFile.h hash.h strings.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c alignment.c


# UTILITIES

## HASHES

testHash: Makefile testHash.o hash.o list.o strings.o myFile.o
	$(CC) $(CCFLAGS) $(INCLUDE) -o testHash testHash.o hash.o list.o strings.o myFile.o $(LIBDIRS) $(LIBS)

testHash.o: Makefile testHash.c hash.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c testHash.c

hash.o: Makefile hash.c hash.h myFile.h strings.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c hash.c


## FILES

testMyFile: Makefile testMyFile.o myFile.o list.o strings.o
	$(CC) $(CCFLAGS) $(INCLUDE) -o testMyFile testMyFile.o myFile.o list.o strings.o $(LIBDIRS) $(LIBS)

testMyFile.o: Makefile testMyFile.c
	$(CC) $(CCFLAGS) $(INCLUDE) -c testMyFile.c

myFile.o: Makefile myFile.c myFile.h list.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c myFile.c

## OTHER UTILITIES

spatialPartition.o: Makefile spatialPartition.c spatialPartition.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c spatialPartition.c

maths.o: Makefile maths.c maths.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c maths.c

strings.o: Makefile strings.c strings.h list.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c strings.c

list.o: Makefile list.c list.h
	$(CC) $(CCFLAGS) $(INCLUDE) -c list.c

# PHONY TARGETS

.PHONY: test
test: all
	prove -r ./t/

.PHONY: install
install:
	cp $(INSTALLBINARIES) ${installbase}/bin/

.PHONY: clean
clean:
	rm -f $(BINARIES) *.o *~

