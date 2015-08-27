#ifndef EDITOR_UTILS_H
#define EDITOR_UTILS_H

#define ENDIAN_LITTLE (((union { unsigned x; unsigned char c; }){1}).c)

void LEtoNinPlace(int *);
const char * const NormalizeResourceName(const char * const);

#endif
