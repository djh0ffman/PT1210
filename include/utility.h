/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * utility.h
 * Miscellaneous utility macros and functions.
 */

#ifndef UTILITY_H
#define UTILITY_H

#include "filesystem.h"

/* Compiler-specific macro for specifying register-based function parameters */
#if defined(__GNUC__)
#define REG(REGISTER, PARAMETER) register PARAMETER __asm(#REGISTER)
#elif defined(__VBCC__)
#define REG(REGISTER, PARAMETER) __reg(#REGISTER) PARAMETER
#endif

/* Macro for determining the length of an array at compile time */
#define ARRAY_LENGTH(ARRAY) (sizeof(ARRAY) / sizeof(*ARRAY))

/* Macro for dividing one positive value by another, rounding up if there is a remainder */
#define CEIL_DIV(X, Y) (((X) + (Y) - 1) / (Y))

/* Macro to stringify a parameter */
#define _STR(X) #X
#define STR(X) _STR(X)

/* Function for clamping a value between a minimum and a maximum */
static inline int32_t clamp(int32_t value, int32_t min, int32_t max)
{
	return (value < min) ? min : (value > max) ? max : value;
}

/* Min/max */
static inline int32_t min(int32_t x, int32_t y)
{
	return x < y ? x : y;
}

static inline int32_t max(int32_t x, int32_t y)
{
	return x > y ? x : y;
}

/* Check whether a file's name either begins or ends with .MOD */
static inline bool has_mod_prefix(const char* file_name)
{
	uint32_t mod_prefix = (file_name[0] << 24 |
						   file_name[1] << 16 |
						   file_name[2] << 8 |
						   file_name[3]) & FS_MOD_PREFIX_UPPER;

	return mod_prefix == FS_MOD_PREFIX;
}

static inline bool has_mod_suffix(const char* file_name, size_t len)
{
	uint32_t mod_suffix = (file_name[len - 4] << 24 |
						   file_name[len - 3] << 16 |
						   file_name[len - 2] << 8 |
						   file_name[len - 1]) & FS_MOD_SUFFIX_UPPER;

	return mod_suffix == FS_MOD_SUFFIX;
}

typedef enum
{
	VIDEO_TYPE_PAL,
	VIDEO_TYPE_NTSC,
	VIDEO_TYPE_UNKNOWN
} video_type_t;

video_type_t video_type();

#endif /* UTILITY_H */
