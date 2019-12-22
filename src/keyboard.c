/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * keyboard.c
 * Keyboard handling and key bindings.
 */

#include <stdlib.h>

#include "action.h"
#include "keyboard.h"
#include "utility.h"

/* Default bindings for 'DJ' mode */
static input_binding_t bindings_dj[] =
{
	/* Bindings with modifier keys (these need to come first in the list) */
	{ KEYCODE_EQUALS,	KEYCODE_LEFT_SHIFT,	PRESS_TYPE_ONESHOT,			pt1210_action_move_forward_line_loop	},
	{ KEYCODE_MINUS,	KEYCODE_LEFT_SHIFT,	PRESS_TYPE_ONESHOT,			pt1210_action_move_backward_line_loop	},
	{ KEYCODE_EQUALS,	KEYCODE_CTRL,		PRESS_TYPE_ONESHOT,			pt1210_action_pattern_cue_move_forward	},
	{ KEYCODE_MINUS,	KEYCODE_CTRL,		PRESS_TYPE_ONESHOT,			pt1210_action_pattern_cue_move_backward	},
	{ KEYCODE_UP,		KEYCODE_LEFT_SHIFT,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_up_fine 			},
	{ KEYCODE_DOWN,		KEYCODE_LEFT_SHIFT,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_down_fine 			},
	{ KEYCODE_RIGHT,	KEYCODE_LEFT_SHIFT,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_forward_hard 		},
	{ KEYCODE_LEFT,		KEYCODE_LEFT_SHIFT,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_backward_hard 		},

	/* FIXME: duplicate bindings for L/R shift; maybe add a keycode to allow mapping both? */
	{ KEYCODE_EQUALS,	KEYCODE_RIGHT_SHIFT,	PRESS_TYPE_ONESHOT,			pt1210_action_move_forward_line_loop	},
	{ KEYCODE_MINUS,	KEYCODE_RIGHT_SHIFT,	PRESS_TYPE_ONESHOT,			pt1210_action_move_backward_line_loop	},
	{ KEYCODE_UP,		KEYCODE_RIGHT_SHIFT,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_up_fine 			},
	{ KEYCODE_DOWN,		KEYCODE_RIGHT_SHIFT,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_down_fine 			},
	{ KEYCODE_RIGHT,	KEYCODE_RIGHT_SHIFT,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_forward_hard 		},
	{ KEYCODE_LEFT,		KEYCODE_RIGHT_SHIFT,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_backward_hard 		},

	/* Bindings without modifier keys */
	{ KEYCODE_ESCAPE,	KEYCODE_NONE,	PRESS_TYPE_HOLD_ONESHOT,	pt1210_action_quit						},
	{ KEYCODE_HELP,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_switch_screen				},
	{ KEYCODE_UP,		KEYCODE_NONE,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_up 					},
	{ KEYCODE_DOWN,		KEYCODE_NONE,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_down 				},
	{ KEYCODE_RIGHT,	KEYCODE_NONE,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_forward 			},
	{ KEYCODE_LEFT,		KEYCODE_NONE,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_backward 			},
	{ KEYCODE_SPACE,	KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_play_pause				},
	{ KEYCODE_F1,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_restart					},
	{ KEYCODE_F2,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_slip_restart				},
	{ KEYCODE_F3,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_pattern_cue_set			},
	{ KEYCODE_F4,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_slip				},
	{ KEYCODE_F5,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_line_loop			},
	{ KEYCODE_F6,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_loop_decrease				},
	{ KEYCODE_F7,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_loop_increase				},
	{ KEYCODE_F10,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_pattern_loop				},
	{ KEYCODE_1,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_channel_1			},
	{ KEYCODE_2,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_channel_2			},
	{ KEYCODE_3,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_channel_3			},
	{ KEYCODE_4,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_channel_4			},
	{ KEYCODE_TAB,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_repitch			},
	{ KEYCODE_GRAVE,	KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_kill_sound_dma			},
	{ KEYCODE_EQUALS,	KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_move_forward_pattern		},
	{ KEYCODE_MINUS,	KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_move_backward_pattern		}
};

/* Default bindings for 'file selector' mode */
static input_binding_t bindings_fs[] =
{
	/* Bindings with modifier keys (these need to come first in the list) */
	{ KEYCODE_UP,		KEYCODE_LEFT_SHIFT,	PRESS_TYPE_ONESHOT, 	pt1210_action_fs_page_up 				},
	{ KEYCODE_DOWN,		KEYCODE_LEFT_SHIFT,	PRESS_TYPE_ONESHOT,		pt1210_action_fs_page_down				},

	/* Bindings without modifier keys */
	{ KEYCODE_ESCAPE,	KEYCODE_NONE,	PRESS_TYPE_HOLD_ONESHOT,	pt1210_action_quit						},
	{ KEYCODE_HELP,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_switch_screen				},
	{ KEYCODE_UP,		KEYCODE_NONE,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_fs_move_up 				},
	{ KEYCODE_DOWN,		KEYCODE_NONE,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_fs_move_down 				},
	{ KEYCODE_LEFT,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_fs_parent					},
	{ KEYCODE_RIGHT,	KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_fs_select					},
	{ KEYCODE_RETURN,	KEYCODE_NONE,	PRESS_TYPE_ONESHOT, 		pt1210_action_fs_select 				},
	{ KEYCODE_F5,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_fs_rescan					},
	{ KEYCODE_F9,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT, 		pt1210_action_fs_sort_name 				},
	{ KEYCODE_F10,		KEYCODE_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_fs_sort_bpm				}
};

/* Key states */
static uint8_t last_key_states[KEYCODE_STATE_BYTES] = { 0 };
static uint8_t key_states[KEYCODE_STATE_BYTES] = { 0 };

static bool processing_enabled = true;

static input_binding_t* cur_binding_list = bindings_fs;
static size_t cur_binding_list_length = ARRAY_LENGTH(bindings_fs);

static input_char_handler_t cur_char_handler = pt1210_action_fs_char_handler;
static char cur_char = '\0';

static inline bool key_active(const uint8_t* states, keyboard_keycode_t keycode)
{
	/* Index into our keyboard state array */
	uint8_t index = keycode >> 3;
	uint8_t bit = keycode & 7;
	return states[index] >> bit & 1;
}

static inline void set_key_state(uint8_t* states, keyboard_keycode_t keycode, bool state)
{
	/* Index into our keyboard state array */
	uint8_t index = keycode >> 3;
	uint8_t bit = keycode & 7;

	/* Trick to conditionally set/clear without branching */
	states[index] ^= (-state ^ states[index]) & (1 << bit);
}

void pt1210_keyboard_enable_processing(bool enabled)
{
	processing_enabled = enabled;
}

void pt1210_keyboard_switch_binding_list(screen_state_t screen)
{
	/* Clear key and binding states */
	for (size_t i = 0; i < ARRAY_LENGTH(key_states); ++i)
		last_key_states[i] = key_states[i] = 0;

	for (size_t i = 0; i < cur_binding_list_length; ++i)
	{
		cur_binding_list[i].state.pressed = false;
		cur_binding_list[i].state.frames_held = 0; 
	}

	switch (screen)
	{
		case SCREEN_DJ:
			cur_binding_list = bindings_dj;
			cur_binding_list_length = ARRAY_LENGTH(bindings_dj);
			cur_char_handler = NULL;
			break;

		case SCREEN_FILE_SELECTOR:
			cur_binding_list = bindings_fs;
			cur_binding_list_length = ARRAY_LENGTH(bindings_fs);
			cur_char_handler = pt1210_action_fs_char_handler;
			break;
	}
}

void pt1210_keyboard_update_raw_key(uint8_t raw_key)
{
	/* If bit 8 is set, the key was released */
	bool pressed = !(raw_key & 0x80);
	uint8_t keycode = raw_key & ~0x80;

	set_key_state(key_states, keycode, pressed);
}

void pt1210_keyboard_update_character_key(char character)
{
	/* Hold onto this character and we'll process it next VBlank */
	cur_char = character;
}

/* Called from VBlank interrupt server */
void pt1210_keyboard_process_keys()
{
	if (!processing_enabled)
		return;

	/* Process character input */
	if (cur_char && cur_char_handler)
	{
		cur_char_handler(cur_char);
		cur_char = '\0';
	}

	/* Temporary copy of the key states to keep track of which keys have been handled */
	uint8_t key_states_handled[KEYCODE_STATE_BYTES];
	for (size_t i = 0; i < ARRAY_LENGTH(key_states); ++i)
		key_states_handled[i] = key_states[i];

	/* Update binding states */
	for (size_t i = 0; i < cur_binding_list_length; ++i)
	{
		input_binding_t* binding = &cur_binding_list[i];

		bool has_modifier = binding->modifier != KEYCODE_NONE;
		bool primary_key_active = key_active(key_states_handled, binding->keycode);

		bool this_state = primary_key_active && (!has_modifier || key_active(key_states_handled, binding->modifier));
		bool last_state = key_active(last_key_states, binding->keycode) && (!has_modifier || key_active(last_key_states, binding->modifier));

		if (this_state != last_state)
		{
			/* If a modifier has been released but the primary key is still down, allow it to be handled by another binding */
			if (has_modifier && !this_state && primary_key_active)
				set_key_state(last_key_states, binding->keycode, false);
			/* Otherwise just clear the bit for this key so we don't look at any other bindings this frame */
			else
				set_key_state(key_states_handled, binding->keycode, false);

			binding->state.pressed = this_state;
		}
	}

	/* Save old key states */
	for (size_t i = 0; i < ARRAY_LENGTH(key_states); ++i)
		last_key_states[i] = key_states[i];

	/* Process keyboard bindings */
	pt1210_input_process_bindings(cur_binding_list, cur_binding_list_length);
}
