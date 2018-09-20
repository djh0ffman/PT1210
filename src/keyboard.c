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
	{ KEYCODE_EQUALS,	MODIFIER_SHIFT,	PRESS_TYPE_ONESHOT,			pt1210_action_move_forward_line_loop	},
	{ KEYCODE_MINUS,	MODIFIER_SHIFT,	PRESS_TYPE_ONESHOT,			pt1210_action_move_backward_line_loop	},
	{ KEYCODE_EQUALS,	MODIFIER_CTRL,	PRESS_TYPE_ONESHOT,			pt1210_action_pattern_cue_move_forward	},
	{ KEYCODE_MINUS,	MODIFIER_CTRL,	PRESS_TYPE_ONESHOT,			pt1210_action_pattern_cue_move_backward	},
	{ KEYCODE_UP,		MODIFIER_SHIFT,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_up_fine 			},
	{ KEYCODE_DOWN,		MODIFIER_SHIFT,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_down_fine 			},
	{ KEYCODE_RIGHT,	MODIFIER_SHIFT,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_forward_hard 		},
	{ KEYCODE_LEFT,		MODIFIER_SHIFT,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_backward_hard 		},

	/* Bindings without modifier keys */
	{ KEYCODE_ESCAPE,	MODIFIER_NONE,	PRESS_TYPE_HOLD_ONESHOT,	pt1210_action_quit						},
	{ KEYCODE_HELP,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_switch_screen				},
	{ KEYCODE_UP,		MODIFIER_NONE,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_up 					},
	{ KEYCODE_DOWN,		MODIFIER_NONE,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_down 				},
	{ KEYCODE_RIGHT,	MODIFIER_NONE,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_forward 			},
	{ KEYCODE_LEFT,		MODIFIER_NONE,	PRESS_TYPE_REPEAT, 			pt1210_action_nudge_backward 			},
	{ KEYCODE_SPACE,	MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_play_pause				},
	{ KEYCODE_F1,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_restart					},
	{ KEYCODE_F2,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_slip_restart				},
	{ KEYCODE_F3,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_pattern_cue_set			},
	{ KEYCODE_F4,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_slip				},
	{ KEYCODE_F5,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_line_loop			},
	{ KEYCODE_F6,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_loop_decrease				},
	{ KEYCODE_F7,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_loop_increase				},
	{ KEYCODE_F10,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_pattern_loop				},
	{ KEYCODE_1,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_channel_1			},
	{ KEYCODE_2,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_channel_2			},
	{ KEYCODE_3,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_channel_3			},
	{ KEYCODE_4,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_channel_4			},
	{ KEYCODE_TAB,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_toggle_repitch			},
	{ KEYCODE_GRAVE,	MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_kill_sound_dma			},
	{ KEYCODE_EQUALS,	MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_move_forward_pattern		},
	{ KEYCODE_MINUS,	MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_move_backward_pattern		}
};

/* Default bindings for 'file selector' mode */
static input_binding_t bindings_fs[] =
{
	{ KEYCODE_ESCAPE,	MODIFIER_NONE,	PRESS_TYPE_HOLD_ONESHOT,	pt1210_action_quit						},
	{ KEYCODE_HELP,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_switch_screen				},
	{ KEYCODE_UP,		MODIFIER_NONE,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_fs_move_up 				},
	{ KEYCODE_DOWN,		MODIFIER_NONE,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_fs_move_down 				},
	{ KEYCODE_RETURN,	MODIFIER_NONE,	PRESS_TYPE_ONESHOT, 		pt1210_action_fs_load_tune 				},
	{ KEYCODE_F1,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_fs_rescan					},
	{ KEYCODE_F8,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_fs_toggle_show_kb			},
	{ KEYCODE_F9,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT, 		pt1210_action_fs_sort_name 				},
	{ KEYCODE_F10,		MODIFIER_NONE,	PRESS_TYPE_ONESHOT,			pt1210_action_fs_sort_bpm				}
};

/* Key states for modifier keys */
static uint8_t modifier_states[MODIFIER_MAX] = { 0 };

static bool processing_enabled = true;

static input_binding_t* cur_binding_list = bindings_fs;
static size_t cur_binding_list_length = ARRAY_LENGTH(bindings_fs);

static input_char_handler_t cur_char_handler = pt1210_action_fs_char_handler;
static char cur_char = '\0';

void pt1210_keyboard_enable_processing(bool enabled)
{
	processing_enabled = enabled;
}

/* TODO: This can probably go away if we expose current screen state somewhere */
void pt1210_keyboard_switch_binding_list(pt1210_screen_t screen)
{
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

	/* Was it a modifier key? */
	switch (keycode)
	{
		case KEYCODE_CTRL:
			modifier_states[MODIFIER_CTRL] = pressed;
			return;

		case KEYCODE_LEFT_ALT:
		case KEYCODE_RIGHT_ALT:
			modifier_states[MODIFIER_ALT] += pressed ? 1 : -1;
			return;

		case KEYCODE_LEFT_AMIGA:
		case KEYCODE_RIGHT_AMIGA:
			modifier_states[MODIFIER_AMIGA] += pressed ? 1 : -1;
			return;

		case KEYCODE_LEFT_SHIFT:
		case KEYCODE_RIGHT_SHIFT:
			modifier_states[MODIFIER_SHIFT] += pressed ? 1 : -1;
			return;
	}

	/* Check bindings */
	for (size_t i = 0; i < cur_binding_list_length; ++i)
	{
		input_binding_t* binding = &cur_binding_list[i];

		/* Mark binding as pressed if there's no associated modifier or the modifier is pressed */
		if (binding->keycode == keycode && (binding->modifier == MODIFIER_NONE || modifier_states[binding->modifier]))
		{
			/* Ensure oneshot actions get triggered if the key was released very fast */
			if (binding->type == PRESS_TYPE_ONESHOT)
			{
				if (pressed)
					binding->state.pressed = true;
			}
			else
			binding->state.pressed = pressed;

			return;
		}
	}
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

	/* Process raw key bindings */
	pt1210_input_process_bindings(cur_binding_list, cur_binding_list_length);
}