#if !defined(MATHS_H)
#define MATHS_H

#include <math.h>

#define MAXVALUE(a, b) ({ __typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a > _b ? _a : _b; })
#define MINVALUE(a, b) ({ __typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a < _b ? _a : _b; })

float distanceSquared(float a[3], float b[3]);
float distance(float a[3], float b[3]);
float lineOverlap(const float start1, const float end1, const float start2, const float end2);
int cubeOverlap(const float minA[3], const float maxA[3], const float minB[3], const float maxB[3], const float tolerance);

#endif
