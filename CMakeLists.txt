# CMake build system.
# d0pefish / PT-1210

cmake_minimum_required(VERSION 3.13)
project(pt1210 ASM C)

# Look for Amiga-GCC
if(NOT AMIGA_GCC)
	if(DEFINED ENV{AMIGA_GCC})
		set(AMIGA_GCC $ENV{AMIGA_GCC} CACHE STRING "Path to Amiga-GCC.")
	else()
		message(FATAL_ERROR "Couldn't find Amiga-GCC. Please set the AMIGA_GCC environment variable.")
	endif()
endif()

# Look for required external tools
find_package(Git)
find_package(Python)
find_program(CPPCHECK NAMES cppcheck)

# If Git was found, add a custom target to generate version information for every build
if(GIT_FOUND)
	add_custom_target(version ALL
		COMMAND ${CMAKE_COMMAND} -DGIT_EXECUTABLE=${GIT_EXECUTABLE} -P ${CMAKE_SOURCE_DIR}/cmake/version.cmake
		COMMENT "Generating version information using git"
		SOURCES src/version.c.in
	)

	# Prevent CMake from looking for this nonexistant file at configure time
	set_source_files_properties(${CMAKE_CURRENT_BINARY_DIR}/version.c PROPERTIES GENERATED TRUE)
endif()

# Configure Cppcheck if it was found
if(CPPCHECK)
	message(STATUS "Found Cppcheck: ${CPPCHECK}")
	set(CMAKE_C_CPPCHECK
		${CPPCHECK}
		$<$<CONFIG:Debug>:-DDEBUG>
		--enable=style,performance,portability,information,missingInclude
		--platform=unspecified
		--std=c99
		--quiet
		-D__GNUC__
		-D__m68k__
		-D__INTPTR_TYPE__=int
		-D__INT32_TYPE__=int
		-I${AMIGA_GCC}/m68k-amigaos/ndk13-include
		-I${AMIGA_GCC}/m68k-amigaos/ndk-include
		-I${AMIGA_GCC}/lib/gcc/m68k-amigaos/6.5.0b/include
		-I${AMIGA_GCC}/m68k-amigaos/sys-include
	)
endif()

# Override release C flags (defaults to -O3)
set(CMAKE_C_FLAGS_RELEASE "-Os -s")

# Legacy ASM target
add_library(legacy OBJECT legacy/pt1210.asm)

# Files that the legacy target depends on
set(LEGACY_DEPENDS
	# ASM files 'included' by pt1210.asm
	legacy/data_chip.asm
	legacy/data_fast.asm
	legacy/file_selector.asm
	legacy/memory.asm
	legacy/pattern_render.asm
	legacy/player.asm
	legacy/scope.asm
	legacy/splash_screen.asm
	legacy/time.asm
	legacy/ui.asm
	legacy/vblank_int.asm

	# Graphics assets INCBIN'ed by ASM code
	legacy/gfx/hud.raw
	legacy/gfx/hud_on2.raw
	legacy/gfx/hud_off.raw
	legacy/gfx/trackoff.bin
	legacy/gfx/trackon.bin
	legacy/gfx/font-digi2.raw
	legacy/gfx/selecta.raw
	legacy/gfx/font-big_fix.raw
	legacy/gfx/font-small_fix.raw
	legacy/gfx/font-digi3.raw
	legacy/gfx/kb.raw
	legacy/gfx/bpm.raw
	legacy/gfx/splash.raw
)

# Prefix the above with their full path
list(TRANSFORM LEGACY_DEPENDS PREPEND ${CMAKE_SOURCE_DIR}/)

# Ensure legacy target is rebuilt if any of the above files change
# N.B. quoted variable ensures it's kept as a semicolon-separated list
set_source_files_properties(legacy/pt1210.asm PROPERTIES OBJECT_DEPENDS "${LEGACY_DEPENDS}")

target_compile_options(legacy PRIVATE -m68000 -Fhunk -x -quiet)
target_include_directories(legacy
	PRIVATE ${AMIGA_GCC}/m68k-amigaos/ndk-include
)

# Executable target
add_executable(pt1210
	# Sources
	src/action.c
	src/audiodevice.c
	src/cia.c
	src/consoledevice.c
	src/filesystem.c
	src/gameport.c
	src/graphics.c
	src/input.c
	src/inputdevice.c
	src/keyboard.c
	src/libraries.c
	src/main.c

	# Headers
	include/action.h
	include/audiodevice.h
	include/cia.h
	include/consoledevice.h
	include/filesystem.h
	include/gameport.h
	include/graphics.h
	include/input.h
	include/inputdevice.h
	include/keyboard.h
	include/libraries.h
	include/utility.h
)

# If version information will be generated, add it to the sources list
if(GIT_FOUND)
	target_sources(pt1210 PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/version.c)
endif()

set_target_properties(pt1210 PROPERTIES
	C_STANDARD 99
	OUTPUT_NAME	$<IF:$<CONFIG:Debug>,pt1210-debug.exe,pt1210.exe>
	RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin
)

target_compile_definitions(pt1210 PRIVATE $<$<CONFIG:Debug>:DEBUG>)
target_compile_options(pt1210 PRIVATE -mcrt=nix13 -Wall -Werror -Wno-pointer-sign)
target_link_options(pt1210 PRIVATE -mcrt=nix13)
target_link_libraries(pt1210 legacy $<$<CONFIG:Debug>:debug>)
target_include_directories(pt1210 PRIVATE include)

# Ensure version info is generated before building pt1210
if(GIT_FOUND)
	add_dependencies(pt1210 version)
endif()