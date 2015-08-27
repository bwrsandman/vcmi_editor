#include "ctype.h"
#include "stdlib.h"
#include "c_editor_utils.h"

void LEtoNinPlace(int * val)
{
    if (!ENDIAN_LITTLE)
        *val = ((*val >> 24) & 0xff)
             | ((*val >> 8) & 0xff00)
             | ((*val << 8) & 0xff0000)
             | ((*val << 24) & 0xff000000);
}

const char * const NormalizeResourceName(const char * const str)
{
    unsigned int strsize = 0;
    while(str[strsize] != '\0' && str[strsize] != '.')
        ++strsize;
    char * res = (char *) malloc(strsize);
    for (unsigned int i = 0; i < strsize; ++i)
    {
#ifdef _WIN32
        if (str[i] == '/')
            res[i] = '\\';
#else
        if (str[i] == '\\')
            res[i] = '/';
#endif
        else
            res[i] = toupper(str[i]);
    }
    res[strsize] = '\0';
    return res;
}
