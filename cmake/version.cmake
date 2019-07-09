# CMake script to generate embedded version information from git description.
# d0pefish / PT-1210

# Generate version information - requires a git tag to be present in the format "vX.Y"
execute_process(COMMAND ${GIT_EXECUTABLE} describe --tags --dirty OUTPUT_VARIABLE GIT_DESCRIPTION OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND ${GIT_EXECUTABLE} show -s --format=%ad --date=format:%y-%m-%d OUTPUT_VARIABLE GIT_DATE OUTPUT_STRIP_TRAILING_WHITESPACE)

# Split vX.Y into separate version and revision variables
string(REGEX REPLACE "^v([0-9]).([0-9]).*$" "\\1;\\2" GIT_FULL_VERSION ${GIT_DESCRIPTION})
list(GET GIT_FULL_VERSION 0 GIT_VERSION)
list(GET GIT_FULL_VERSION 1 GIT_REVISION)

# Convert YYYY-MM-DD to DD.MM.YY without leading zeros to suit Amiga version format
string(REGEX REPLACE "^([0-9][0-9])-0*([1-9][0-9]*)-0*([1-9][0-9]*)$" "\\3.\\2.\\1" GIT_FORMATTED_DATE ${GIT_DATE})

# Generate version.c with correct version info
configure_file(../src/version.c.in version.c)
