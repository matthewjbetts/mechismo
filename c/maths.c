#include "maths.h"

float distanceSquared(float a[3], float b[3]) {
    int   i;
    float d;
    float d2;

    d2 = 0.0;
    for(i = 0; i < 3; i++) {
        d = a[i] - b[i];
        //d2 += pow(d, 2);
        d2 += (d * d);
    }

    return d2;
}

float distance(float a[3], float b[3]) {
    return sqrt((float) distanceSquared(a, b));
}

float lineOverlap(const float startA, const float endA, const float startB, const float endB) {
    // returns positive number for overlap and therefore negative for separation

    float overlap;

    if(startA <= startB) {
	if(endA >= startB) {
	    if(endA >= endB) {
                /*
                 * A ------------
                 * B    ----
                 *
		 * A contains B
                 */

		overlap = endB - startB;
	    }
	    else {
                /*
                 * A --------
                 * B    --------
                 *
                 * the end of A overlaps with the beginning of B
                 */

		overlap = endA - startB;
	    }
	}
	else {
            /*
             * A ----
             * B       ----
             *
             * A is before B
             */
	    overlap = endA - startB; // NB. overlap is negative
	}
    }
    else {
	if(startA <= endB) {
	    if(endA <= endB) {
                /*
                 * A     ----
                 * B ------------
                 *
                 * A is contained by B
                 */
                overlap = endA - startA;
	    }
	    else {
                /*
                 * A     --------
                 * B --------
                 *
                 * the beginning of A overlaps with the end of B
                 */
		overlap = endB - startA;
	    }
	}
	else {
            /*
             * A       ----
             * B ----
             *
             * A is after B
             */
	    overlap = 0.0;
	    overlap = endB - startA; // NB. overlap is negative
	}
    }

    return overlap;
}

int cubeOverlap(const float minA[3], const float maxA[3], const float minB[3], const float maxB[3], const float tolerance) {
    /*
     * minA and maxA define two diagonally opposing corners of cube A.
     * returns 0 if the two cubes overlap by >= tolerance in all dimensions, or 1 otherwise.
     * since overlap is positive, tolerance should be eg. -5.0 to identify cubes separated by up to 5.0
     */

    if(lineOverlap(minA[0], maxA[0], minB[0], maxB[0]) >= tolerance) { // overlap in x
        if(lineOverlap(minA[1], maxA[1], minB[1], maxB[1]) >= tolerance) { // overlap in y
            if(lineOverlap(minA[2], maxA[2], minB[2], maxB[2]) >= tolerance) { // overlap in z
                return 0;
            }
        }
    }

    return 1;
}

