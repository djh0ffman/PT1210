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

/* Macro for clamping a value between a minimum and a maximum */
#define CLAMP(VALUE, MIN, MAX) ((VALUE < MIN) ? MIN : (VALUE > MAX) ? MAX : VALUE)

/* Macro for dividing one positive value by another, rounding up if there is a remainder */
#define CEIL_DIV(X, Y) (((X) + (Y) - 1) / (Y))

#endif /* UTILITY_H */