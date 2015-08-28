#include "ctype.h"
#include "stdlib.h"
#include "c_editor_utils.h"

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
