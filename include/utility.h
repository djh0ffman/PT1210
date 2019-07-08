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

/* Compiler-specific macro for specifying register-based function parameters */
#if defined(__GNUC__)
#define REG(REGISTER, PARAMETER) register PARAMETER __asm(#REGISTER)
#elif defined(__VBCC__)
#define REG(REGISTER, PARAMETER) __reg(#REGISTER) PARAMETER
#endif

/* Macro for determining the length of an array at compile time */
#define ARRAY_LENGTH(ARRAY) (sizeof(ARRAY) / sizeof(*ARRAY))

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

typedef enum
{
	VIDEO_TYPE_PAL,
	VIDEO_TYPE_NTSC,
	VIDEO_TYPE_UNKNOWN
} video_type_t;

video_type_t video_type();

#endif /* UTILITY_H */