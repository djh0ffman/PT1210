/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * version.c
 * Embedded version information.
 */

#define _STR(X) #X
#define STR(X) _STR(X)

#define GIT_VERSION_STR STR(GIT_VERSION)
#define GIT_REVISION_STR STR(GIT_REVISION)
#define GIT_DATE_STR STR(GIT_DATE)
#define GIT_DESCRIPTION_STR STR(GIT_DESCRIPTION)

#if defined(GIT_VERSION) && defined(GIT_REVISION) && defined(GIT_DATE) && defined(GIT_DESCRIPTION)
const char* pt1210_version = "\0$VER: PT-1210 " GIT_VERSION_STR "." GIT_REVISION_STR \
							 " (" GIT_DATE_STR ") " GIT_DESCRIPTION_STR;
#endif
