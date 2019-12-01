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
find_package(Python3 REQUIRED)
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

# Graphics conversion
set(GFX_DIR ${CMAKE_SOURCE_DIR}/gfx)
set(SCRIPTS_DIR ${CMAKE_SOURCE_DIR}/scripts)
set(IFF2RAW ${CMAKE_SOURCE_DIR}/scripts/iff2raw.py)
set(GFX_HUD_LIST ${SCRIPTS_DIR}/hud-cut-list.yaml)
set(GFX_TASK_LIST ${SCRIPTS_DIR}/task-list.yaml)

# The following lists are required for accurate dependency tracking;
# this ensures the conversion scripts are re-run if any of the output
# files are missing, or if any of the inputs files are changed
set(GFX_HUD_OUTPUTS
	hud_chip.asm
	hud_fast.asm
	HUD_line_loop_01_off.raw
	HUD_line_loop_01_on.raw
	HUD_line_loop_02_off.raw
	HUD_line_loop_02_on.raw
	HUD_line_loop_04_off.raw
	HUD_line_loop_04_on.raw
	HUD_line_loop_08_off.raw
	HUD_line_loop_08_on.raw
	HUD_line_loop_16_off.raw
	HUD_line_loop_16_on.raw
	HUD_line_loop_32_off.raw
	HUD_line_loop_32_on.raw
	HUD_line_loop_active_off.raw
	HUD_line_loop_active_on.raw
	HUD_line_loop_mode_off.raw
	HUD_line_loop_mode_on.raw
	HUD_pat_loop_in_off.raw
	HUD_pat_loop_in_on.raw
	HUD_pat_loop_out_off.raw
	HUD_pat_loop_out_on.raw
	HUD_repitch_off.raw
	HUD_repitch_on.raw
)

set(GFX_TASK_INPUTS
	font-big.iff
	font-digi-large.iff
	font-digi-small.iff
	font-small.iff
	hud.iff
	select-window.iff
	track-header.iff
)

set(GFX_TASK_OUTPUTS
	font-big.raw
	font-digi-large.raw
	font-digi-small.raw
	font-small.raw
	hud.asm
	hud.raw
	select-window.asm
	select-window.raw
	track-header.asm
	track-header-off.raw
	track-header-on.raw
)

# Prefix the above with their full paths
list(TRANSFORM GFX_HUD_INPUTS PREPEND ${GFX_DIR}/)
list(TRANSFORM GFX_TASK_INPUTS PREPEND ${GFX_DIR}/)
list(TRANSFORM GFX_HUD_OUTPUTS PREPEND gfx/)
list(TRANSFORM GFX_TASK_OUTPUTS PREPEND gfx/)

# Custom commands that calls our Python script
add_custom_command(OUTPUT ${GFX_HUD_OUTPUTS}
	COMMAND ${Python3_EXECUTABLE} ${IFF2RAW} hudcut ${GFX_HUD_LIST} ${GFX_DIR}/hud.iff gfx
	MAIN_DEPENDENCY ${GFX_HUD_LIST}
	DEPENDS ${GFX_HUD_LIST}
	COMMENT "Cutting HUD graphics"
)

add_custom_command(OUTPUT ${GFX_TASK_OUTPUTS}
	COMMAND ${Python3_EXECUTABLE} ${IFF2RAW} task ${GFX_TASK_LIST} ${GFX_DIR} gfx
	MAIN_DEPENDENCY ${GFX_TASK_LIST}
	DEPENDS ${GFX_TASK_INPUTS}
	COMMENT "Performing graphics conversion tasks"
)

# Add outputs of the graphics processing to a dependency list
list(APPEND GFX_DEPENDS ${GFX_HUD_OUTPUTS} ${GFX_TASK_OUTPUTS})

# Files that the legacy target depends on
set(LEGACY_DEPENDS
	# ASM headers
	include/state.i

	# ASM files 'included' by pt1210.asm
	legacy/data_chip.asm
	legacy/data_fast.asm
	legacy/file_selector.asm
	legacy/pattern_render.asm
	legacy/player.asm
	legacy/scope.asm
	legacy/splash_screen.asm
	legacy/ui.asm
	legacy/vblank_int.asm
)

# Prefix the above with their full path
list(TRANSFORM LEGACY_DEPENDS PREPEND ${CMAKE_SOURCE_DIR}/)

# Ensure legacy target is rebuilt if any of the above files change
# N.B. quoted variable ensures it's kept as a semicolon-separated list
set_source_files_properties(legacy/pt1210.asm PROPERTIES OBJECT_DEPENDS "${GFX_DEPENDS};${LEGACY_DEPENDS}")

target_compile_options(legacy PRIVATE -m68000 -Fhunk -x -quiet)
target_include_directories(legacy
	PRIVATE ${AMIGA_GCC}/m68k-amigaos/ndk-include
	PRIVATE include
)

# Executable target
add_executable(pt1210
	# Sources
	src/action.c
	src/audiodevice.c
	src/cia.c
	src/consoledevice.c
	src/fileselector.c
	src/filesystem.c
	src/gameport.c
	src/graphics.c
	src/input.c
	src/inputdevice.c
	src/keyboard.c
	src/main.c
	src/pt1210.c
	src/timerdevice.c

	# Headers
	include/action.h
	include/audiodevice.h
	include/cia.h
	include/consoledevice.h
	include/fileselector.h
	include/filesystem.h
	include/font.h
	include/gameport.h
	include/graphics.h
	include/input.h
	include/inputdevice.h
	include/keyboard.h
	include/pt1210.h
	include/timerdevice.h
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
