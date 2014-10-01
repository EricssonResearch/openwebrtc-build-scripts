#include <string.h>
#include <sys/stat.h>

int my_stat(const char *pathname, struct stat *buf)
{
    if (strlen(pathname) >= 27
      && (strncmp(pathname, "/System/Library/Frameworks/", 27) == 0)) {
        buf->st_mode = S_IFREG | S_IRUSR;
        return 0;
    }

    return stat(pathname, buf);
}
