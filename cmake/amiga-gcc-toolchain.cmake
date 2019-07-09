# Amiga-GCC Toolchain file for CMake
# d0pefish / PT-1210

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1.2)
set(CMAKE_SYSTEM_PROCESSOR m68k)

set(TRIPLE m68k-amigaos)

# Try to find the toolchain
set(AMIGA_GCC_PATHS
	c:/amiga-gcc/bin
	/opt/amiga/bin
	$ENV{AMIGA_GCC}/bin
)

find_program(CMAKE_ASM_COMPILER vasmm68k_mot PATHS ${AMIGA_GCC_PATHS})
find_program(CMAKE_C_COMPILER ${TRIPLE}-gcc PATHS ${AMIGA_GCC_PATHS})
find_program(CMAKE_CXX_COMPILER ${TRIPLE}-g++ PATHS ${AMIGA_GCC_PATHS})

# Teach CMake how to run VASM
set(CMAKE_ASM_COMPILER_ID VASM)
set(CMAKE_ASM_COMPILE_OBJECT "<CMAKE_ASM_COMPILER> <FLAGS> <INCLUDES> -o <OBJECT> <SOURCE>")

set(CMAKE_C_COMPILER_TARGET ${TRIPLE})
set(CMAKE_CXX_COMPILER_TARGET ${TRIPLE})
