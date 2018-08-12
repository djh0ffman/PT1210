/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * keyboard.h
 * Keyboard handling and key bindings.
 */

#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <stdbool.h>
#include <stdint.h>

#include "action.h" /* TODO: For pt1210_screen_t - replace when relocated */
#include "input.h"

/* Amiga keyboard scancodes, as defined in the Amiga RKM: Libraries */
typedef enum
{
	KEYCODE_GRAVE					= 0x00,
	KEYCODE_1						= 0x01,
	KEYCODE_2						= 0x02,
	KEYCODE_3						= 0x03,
	KEYCODE_4						= 0x04,
	KEYCODE_5						= 0x05,
	KEYCODE_6						= 0x06,
	KEYCODE_7						= 0x07,
	KEYCODE_8						= 0x08,
	KEYCODE_9						= 0x09,
	KEYCODE_0						= 0x0A,
	KEYCODE_MINUS					= 0x0B,
	KEYCODE_EQUALS					= 0x0C,
	KEYCODE_BACKSLASH				= 0x0D,
	/* (undefined)					= 0x0E, */
	KEYCODE_NUMPAD_0				= 0x0F,
	KEYCODE_Q						= 0x10,
	KEYCODE_W						= 0x11,
	KEYCODE_E						= 0x12,
	KEYCODE_R						= 0x13,
	KEYCODE_T						= 0x14,
	KEYCODE_Y						= 0x15,
	KEYCODE_U						= 0x16,
	KEYCODE_I						= 0x17,
	KEYCODE_O						= 0x18,
	KEYCODE_P						= 0x19,
	KEYCODE_LEFT_SQUARE_BRACKET		= 0x1A,
	KEYCODE_RIGHT_SQUARE_BRACKET	= 0x1B,
	/* (undefined)					= 0x1C, */
	KEYCODE_NUMPAD_1				= 0x1D,
	KEYCODE_NUMPAD_2				= 0x1E,
	KEYCODE_NUMPAD_3				= 0x1F,
	KEYCODE_A						= 0x20,
	KEYCODE_S						= 0x21,
	KEYCODE_D						= 0x22,
	KEYCODE_F						= 0x23,
	KEYCODE_G						= 0x24,
	KEYCODE_H						= 0x25,
	KEYCODE_J						= 0x26,
	KEYCODE_K						= 0x27,
	KEYCODE_L						= 0x28,
	KEYCODE_SEMICOLON				= 0x29,
	KEYCODE_QUOTE					= 0x2A,
	KEYCODE_BLANK_1					= 0x2B,
	/* (undefined)					= 0x2C, */
	KEYCODE_NUMPAD_4				= 0x2D,
	KEYCODE_NUMPAD_5				= 0x2E,
	KEYCODE_NUMPAD_6				= 0x2F,
	KEYCODE_BLANK_2					= 0x30,
	KEYCODE_Z						= 0x31,
	KEYCODE_X						= 0x32,
	KEYCODE_C						= 0x33,
	KEYCODE_V						= 0x34,
	KEYCODE_B						= 0x35,
	KEYCODE_N						= 0x36,
	KEYCODE_M						= 0x37,
	KEYCODE_COMMA					= 0x38,
	KEYCODE_PERIOD					= 0x39,
	KEYCODE_SLASH					= 0x3A,
	/* (undefined)					= 0x3B, */
	KEYCODE_NUMPAD_PERIOD			= 0x3C,
	KEYCODE_NUMPAD_7				= 0x3D,
	KEYCODE_NUMPAD_8				= 0x3E,
	KEYCODE_NUMPAD_9				= 0x3F,
	KEYCODE_SPACE					= 0x40,
	KEYCODE_BACKSPACE				= 0x41,
	KEYCODE_TAB						= 0x42,
	KEYCODE_NUMPAD_ENTER			= 0x43,
	KEYCODE_RETURN					= 0x44,
	KEYCODE_ESCAPE					= 0x45,
	KEYCODE_DELETE					= 0x46,
	/* (undefined)					= 0x47, */
	/* (undefined)					= 0x48, */
	/* (undefined)					= 0x49, */
	KEYCODE_NUMPAD_MINUS			= 0x4A,
	/* (undefined)					= 0x4B, */
	KEYCODE_UP						= 0x4C,
	KEYCODE_DOWN					= 0x4D,
	KEYCODE_RIGHT					= 0x4E,
	KEYCODE_LEFT					= 0x4F,
	KEYCODE_F1						= 0x50,
	KEYCODE_F2						= 0x51,
	KEYCODE_F3						= 0x52,
	KEYCODE_F4						= 0x53,
	KEYCODE_F5						= 0x54,
	KEYCODE_F6						= 0x55,
	KEYCODE_F7						= 0x56,
	KEYCODE_F8						= 0x57,
	KEYCODE_F9						= 0x58,
	KEYCODE_F10						= 0x59,
	KEYCODE_NUMPAD_LEFT_PAREN		= 0x5A,
	KEYCODE_NUMPAD_RIGHT_PAREN		= 0x5B,
	KEYCODE_NUMPAD_DIVIDE			= 0x5C,
	KEYCODE_NUMPAD_MULTIPLY			= 0x5D,
	KEYCODE_NUMPAD_PLUS				= 0x5E,
	KEYCODE_HELP					= 0x5F,
	KEYCODE_LEFT_SHIFT				= 0x60,
	KEYCODE_RIGHT_SHIFT				= 0x61,
	KEYCODE_CAPS_LOCK				= 0x62,
	KEYCODE_CTRL					= 0x63,
	KEYCODE_LEFT_ALT				= 0x64,
	KEYCODE_RIGHT_ALT				= 0x65,
	KEYCODE_LEFT_AMIGA				= 0x66,
	KEYCODE_RIGHT_AMIGA				= 0x67,
	KEYCODE_LEFT_MOUSE				= 0x68,
	KEYCODE_RIGHT_MOUSE				= 0x69,
	KEYCODE_MIDDLE_MOUSE			= 0x6A,
	/* (undefined)					= 0x6B, */
	/* (undefined)					= 0x6C, */
	/* (undefined)					= 0x6D, */
	/* (undefined)					= 0x6E, */
	/* (undefined)					= 0x6F, */
	/* (undefined)					= 0x70, */
	/* (undefined)					= 0x71, */
	/* (undefined)					= 0x72, */
	/* (undefined)					= 0x73, */
	/* (undefined)					= 0x74, */
	/* (undefined)					= 0x75, */
	/* (undefined)					= 0x76, */
	/* (undefined)					= 0x77, */
	/* (undefined)					= 0x78, */
	/* (undefined)					= 0x79, */
	/* (undefined)					= 0x7A, */
	/* (undefined)					= 0x7B, */
	/* (undefined)					= 0x7C, */
	/* (undefined)					= 0x7D, */
	/* (undefined)					= 0x7E, */
	/* (undefined)					= 0x7F  */
} keyboard_keycode_t;

/* Modifier keys */
typedef enum
{
	MODIFIER_CTRL,
	MODIFIER_ALT,
	MODIFIER_AMIGA,
	MODIFIER_SHIFT,
	MODIFIER_NONE,
	MODIFIER_MAX = MODIFIER_NONE
} keyboard_modifier_t;

void pt1210_keyboard_enable_processing(bool enabled);
void pt1210_keyboard_switch_binding_list(pt1210_screen_t screen);
void pt1210_keyboard_update_raw_key(uint8_t raw_key);
void pt1210_keyboard_update_character_key(char character);
void pt1210_keyboard_process_keys();

#endif /* KEYBOARD_H */