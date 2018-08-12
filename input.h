/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * input.h
 * Input binding/handler types and processing.
 */

#ifndef INPUT_H
#define INPUT_H

#include <stdint.h>
#include <stdlib.h>

/* Types of key/button press */
typedef enum
{
	PRESS_TYPE_ONESHOT,
	PRESS_TYPE_REPEAT,
	PRESS_TYPE_HOLD_ONESHOT,
	PRESS_TYPE_HOLD_REPEAT,
} input_press_type_t;

/* Function pointer types for handling key/button presses */
typedef void (*input_press_handler_t)();
typedef void (*input_char_handler_t)(char character);

/* Input press/hold state */
typedef struct
{
	bool pressed;
	uint8_t frames_held;
} input_state_t;

/* Input binding structure */
typedef struct
{
	uint8_t keycode;
	uint8_t modifier;
	input_press_type_t type;
	input_press_handler_t handler;
	input_state_t state;
} input_binding_t;

void pt1210_input_process_bindings(input_binding_t* binding_list, size_t length);

#endif /* INPUT_H */