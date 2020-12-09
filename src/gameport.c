/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * gameport.c
 * CD32 gamepad handling and button bindings.
 */

#include <clib/debug_protos.h>
#include <proto/exec.h>
#include <proto/graphics.h>
/* FIXME: Kludge to get lowlevel includes working with -mcrt=nix13 */
typedef ULONG Tag;
#include <proto/lowlevel.h>

#include "action.h"
#include "gameport.h"
#include "input.h"
#include "utility.h"
#include "state.h"

struct Library* LowLevelBase = NULL;

/* Default bindings for 'DJ' mode */
static input_binding_t bindings_dj[] =
{
	{ EVENT_UP,					EVENT_BUTTON_FAST_FORWARD,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_move_forward_pattern	},
	{ EVENT_DOWN,				EVENT_BUTTON_FAST_FORWARD,	PRESS_TYPE_HOLD_REPEAT,		pt1210_action_move_backward_pattern	},
	{ EVENT_RIGHT,				EVENT_BUTTON_FAST_FORWARD,	PRESS_TYPE_REPEAT,			pt1210_action_nudge_forward_hard 	},
	{ EVENT_LEFT,				EVENT_BUTTON_FAST_FORWARD,	PRESS_TYPE_REPEAT,			pt1210_action_nudge_backward_hard 	},
	{ EVENT_BUTTON_PLAYPAUSE,	EVENT_BUTTON_FAST_FORWARD,	PRESS_TYPE_ONESHOT,			pt1210_action_pattern_cue_set		},
	{ EVENT_BUTTON_PLAYPAUSE,	EVENT_BUTTON_REWIND,		PRESS_TYPE_ONESHOT,			pt1210_action_restart				},
	{ EVENT_BUTTON_YELLOW,		EVENT_BUTTON_REWIND,		PRESS_TYPE_ONESHOT,			pt1210_action_toggle_repitch		},
	{ EVENT_BUTTON_BLUE,		EVENT_BUTTON_REWIND,		PRESS_TYPE_ONESHOT,			pt1210_action_loop_decrease			},
	{ EVENT_UP,					EVENT_BUTTON_REWIND,		PRESS_TYPE_ONESHOT,			pt1210_action_switch_screen			},
	{ EVENT_UP,					EVENT_NONE,					PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_up 				},
	{ EVENT_DOWN,				EVENT_NONE,					PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_down 			},
	{ EVENT_RIGHT,				EVENT_NONE,					PRESS_TYPE_REPEAT,			pt1210_action_nudge_forward 		},
	{ EVENT_LEFT,				EVENT_NONE,					PRESS_TYPE_REPEAT,			pt1210_action_nudge_backward 		},
	{ EVENT_BUTTON_GREEN,		EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_toggle_slip			},
	{ EVENT_BUTTON_1,			EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_toggle_line_loop		},
	{ EVENT_BUTTON_2,			EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_loop_increase			},
	{ EVENT_BUTTON_YELLOW,		EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_pattern_loop			},
	{ EVENT_BUTTON_PLAYPAUSE,	EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_play_pause			}
};

/* Default bindings for 'file selector' mode */
static input_binding_t bindings_fs[] =
{
	{ EVENT_UP,					EVENT_BUTTON_REWIND,		PRESS_TYPE_ONESHOT,			pt1210_action_switch_screen			},
	{ EVENT_UP,					EVENT_NONE,					PRESS_TYPE_HOLD_REPEAT,		pt1210_action_fs_move_up 			},
	{ EVENT_DOWN,				EVENT_NONE,					PRESS_TYPE_HOLD_REPEAT,		pt1210_action_fs_move_down 			},
	{ EVENT_BUTTON_1,			EVENT_NONE,					PRESS_TYPE_ONESHOT, 		pt1210_action_fs_select 			}
};

static gameport_type_t gameport_0_type = TYPE_NONE;
/* TODO: Support for controllers in port 0 */
/* static uint32_t last_gameport0_state = 0; */
/* static uint32_t gameport_0_state = 0; */

static gameport_type_t gameport_1_type = TYPE_NONE;
static uint32_t last_gameport1_state = 0;
static uint32_t gameport_1_state = 0;

static bool processing_enabled = true;

static input_binding_t* cur_binding_list = bindings_fs;
static size_t cur_binding_list_length = ARRAY_LENGTH(bindings_fs);

static inline bool event_active(uint32_t gameport_state, gameport_event_t event)
{
	return (gameport_state >> event) & 1;
}

void pt1210_gameport_enable_processing(bool enabled)
{
	processing_enabled = enabled;
}

void pt1210_gameport_switch_binding_list(screen_state_t screen)
{
	switch (screen)
	{
		case SCREEN_DJ:
			cur_binding_list = bindings_dj;
			cur_binding_list_length = ARRAY_LENGTH(bindings_dj);
			break;

		case SCREEN_FILE_SELECTOR:
			cur_binding_list = bindings_fs;
			cur_binding_list_length = ARRAY_LENGTH(bindings_fs);
			break;
	}
}

bool pt1210_gameport_open()
{
	/* Continue without lowlevel.library (regular joystick only) */
	if (!(LowLevelBase = (struct Library *)OpenLibrary("lowlevel.library", 0L)))
		return false;

#ifdef DEBUG
	kprintf("Using lowlevel.library\n");
#endif

	gameport_0_type = pt1210_gameport_detect(PORT_0);
	gameport_1_type = pt1210_gameport_detect(PORT_1);

#ifdef DEBUG
	kprintf("Gameport 0 type: %s\n", gameport_0_type == TYPE_NONE ? "none" : (gameport_0_type == TYPE_JOYSTICK ? "joystick" : "CD32 gamepad"));
	kprintf("Gameport 1 type: %s\n", gameport_1_type == TYPE_NONE ? "none" : (gameport_1_type == TYPE_JOYSTICK ? "joystick" : "CD32 gamepad"));
#endif

	return true;
}

void pt1210_gameport_close()
{
	if (LowLevelBase)
		CloseLibrary(LowLevelBase);
}

gameport_type_t pt1210_gameport_detect(gameport_port_t port)
{
	ULONG result;

	/* Loop to detect controller types */
	for (uint8_t i = 0; i < 20; ++i)
	{
		result = ReadJoyPort((ULONG)port);
		WaitTOF();
	}

	if (result & JP_TYPE_GAMECTLR)
		return TYPE_CD32_GAMEPAD;

	if (result & JP_TYPE_JOYSTK)
		return TYPE_JOYSTICK;

	return TYPE_NONE;
}

/* Called from VBlank interrupt server */
void pt1210_gameport_process_buttons()
{
	if (!processing_enabled || (gameport_0_type == TYPE_NONE && gameport_1_type == TYPE_NONE))
		return;

	if (gameport_1_type != TYPE_NONE)
	{
		gameport_1_state = ReadJoyPort((ULONG)PORT_1);

		/* Has the state changed? */
		if (gameport_1_state != last_gameport1_state)
		{
	#ifdef DEBUG
			kprintf("Gameport 1 state: 0x%04lx\n", gameport_1_state);
	#endif

			/* Update binding states */
			uint32_t gameport_1_handled = gameport_1_state;
			for (size_t i = 0; i < cur_binding_list_length; ++i)
			{
				input_binding_t* binding = &cur_binding_list[i];
				bool this_state = event_active(gameport_1_handled, binding->keycode) && (binding->modifier == EVENT_NONE || event_active(gameport_1_state, binding->modifier));
				bool last_state = event_active(last_gameport1_state, binding->keycode) && (binding->modifier == EVENT_NONE || event_active(last_gameport1_state, binding->modifier));

				if (this_state != last_state)
				{
					/* Clear the bit for this event so we don't look at any other bindings this frame */
					gameport_1_handled &= ~(1 << binding->keycode);
					binding->state.pressed = this_state;
				}
			}

			last_gameport1_state = gameport_1_state;
		}
	}

	/* Process gameport bindings */
	pt1210_input_process_bindings(cur_binding_list, cur_binding_list_length);
}
