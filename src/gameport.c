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
#include <hardware/cia.h>
#include <hardware/custom.h>
#include <proto/exec.h>
#include <proto/potgo.h>

#include "action.h"
#include "gameport.h"
#include "input.h"
#include "utility.h"
#include "state.h"

extern struct Custom custom;
extern struct CIA ciaa;

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
	{ EVENT_UP,					EVENT_NONE,					PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_up 				},
	{ EVENT_DOWN,				EVENT_NONE,					PRESS_TYPE_HOLD_REPEAT,		pt1210_action_pitch_down 			},
	{ EVENT_RIGHT,				EVENT_NONE,					PRESS_TYPE_REPEAT,			pt1210_action_nudge_forward 		},
	{ EVENT_LEFT,				EVENT_NONE,					PRESS_TYPE_REPEAT,			pt1210_action_nudge_backward 		},
	{ EVENT_BUTTON_GREEN,		EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_toggle_slip			},
	{ EVENT_BUTTON_1,			EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_toggle_line_loop		},
	{ EVENT_BUTTON_2,			EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_loop_cycle			},
	{ EVENT_BUTTON_YELLOW,		EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_pattern_loop			},
	{ EVENT_BUTTON_PLAYPAUSE,	EVENT_NONE,					PRESS_TYPE_ONESHOT,			pt1210_action_play_pause			}
};

/* Default bindings for 'file selector' mode */
static input_binding_t bindings_fs[] =
{
	{ EVENT_UP,					EVENT_NONE,					PRESS_TYPE_HOLD_REPEAT,		pt1210_action_fs_move_up 			},
	{ EVENT_DOWN,				EVENT_NONE,					PRESS_TYPE_HOLD_REPEAT,		pt1210_action_fs_move_down 			},
	{ EVENT_BUTTON_1,			EVENT_NONE,					PRESS_TYPE_ONESHOT, 		pt1210_action_fs_select 			}
};

static gameport_type_t gameport_0_type = TYPE_NONE;
/* TODO: Support for controllers in port 0 */
/* static uint16_t last_gameport0_state = 0; */
/* static uint16_t gameport_0_state = 0; */

static gameport_type_t gameport_1_type = TYPE_NONE;
static uint16_t last_gameport1_state = 0;
static uint16_t gameport_1_state = 0;

static bool processing_enabled = true;

static input_binding_t* cur_binding_list = bindings_fs;
static size_t cur_binding_list_length = ARRAY_LENGTH(bindings_fs);

/* The POTGO bits allocated from the system */
static uint32_t pot_bits = 0;
struct Node* PotgoBase = NULL;

static inline bool event_active(uint16_t gameport_state, gameport_event_t event)
{
	return (gameport_state >> event) & 1;
}

static inline uint16_t read_joystick(gameport_port_t port)
{
	uint8_t cia_pin6_bit;
	uint16_t potgo_pin9_bit;
	uint16_t joydat;

	/* Select the registers and bits we're interested in based on the port we want to read */
	if (port == PORT_0)
	{
		cia_pin6_bit = CIAB_GAMEPORT0;
		potgo_pin9_bit = POTGOB_DATLY;
		joydat = custom.joy0dat;
	}
	else
	{
		cia_pin6_bit = CIAB_GAMEPORT1;
		potgo_pin9_bit = POTGOB_DATRY;
		joydat = custom.joy1dat;
	}

	return	((joydat >> 8 ^ joydat >> 9) & 1) << EVENT_UP |
			((joydat >> 0 ^ joydat >> 1) & 1) << EVENT_DOWN |
			(joydat >> 9 & 1) << EVENT_LEFT |
			(joydat >> 1 & 1) << EVENT_RIGHT |
			(~(ciaa.ciapra >> cia_pin6_bit) & 1) << EVENT_BUTTON_1 |
			(~(custom.potinp >> potgo_pin9_bit) & 1) << EVENT_BUTTON_2;
}

static uint16_t read_gamepad_buttons(gameport_port_t port, bool read_extra_buttons)
{
	/* Start of critical section */
	Disable();

	/* Store the contents of the registers we're about to poke */
	uint8_t ciaddra_old = ciaa.ciaddra;
	uint8_t ciapra_old = ciaa.ciapra;
	uint16_t potgo_old = custom.potgo;

	/* Select the register bits we're interested in based on the port we want to read */
	uint8_t cia_pin6_bitmask = port == PORT_0 ? CIAF_GAMEPORT0 : CIAF_GAMEPORT1;
	uint16_t potgo_pin9_bit = port == PORT_0 ? POTGOB_DATLY : POTGOB_DATRY;

	/* Set pin 6 (fire button) to be an output for clocking CD32 pad shift register, and clear it */
	ciaa.ciaddra |= cia_pin6_bitmask;
	ciaa.ciapra &= ~cia_pin6_bitmask;

	/* Set pin 5 high to enable CD32 pad shift register */
	if (port == PORT_0)
		WritePotgo(POTGOF_OUTLX, pot_bits);
	else
		WritePotgo(POTGOF_OUTRX, pot_bits);

	uint16_t button_state = 0;

	/* The CD32 pad has two extra nonexistant buttons in the shift register that can be used for identification */
	uint8_t num_reads = read_extra_buttons ? 9 : 7;
	for (uint8_t i = 0; i < num_reads; ++i)
	{
		/* Delay: reading from CIA means we're not CPU-dependant */
#ifdef __GNUC__
		__asm("\tlea 0xBFE001,a1");
#else
		__asm("\tlea $BFE001,a1");
#endif
		__asm("\ttst.b (a1)");
		__asm("\ttst.b (a1)");
		__asm("\ttst.b (a1)");
		__asm("\ttst.b (a1)");
		__asm("\ttst.b (a1)");
		__asm("\ttst.b (a1)");
		__asm("\ttst.b (a1)");
		__asm("\ttst.b (a1)");

		/* Read pin 9 and clock in the next bit */
		button_state |= (~(custom.potinp >> potgo_pin9_bit) & 1) << (EVENT_BUTTON_BLUE + i);
		ciaa.ciapra |= cia_pin6_bitmask;
		ciaa.ciapra &= ~cia_pin6_bitmask;
	}

	/* Restore POTGO and CIA registers */
	WritePotgo(potgo_old, pot_bits);
	ciaa.ciapra = ciapra_old;
	ciaa.ciaddra = ciaddra_old;

	/* End of critical section*/
	Enable();

	return button_state;
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

bool pt1210_gameport_allocate()
{
	if (!(PotgoBase = (struct Node*) OpenResource("potgo.resource")))
		return false;

	/* Try to allocate POTGO bits from the system */
	pot_bits = AllocPotBits(PORT_0_POT_BITS | PORT_1_POT_BITS);

	if (pot_bits & PORT_0_POT_BITS)
	{
		gameport_0_type = pt1210_gameport_detect(PORT_0);
#ifdef DEBUG
		kprintf("Gameport 0 type: %s\n", gameport_0_type == TYPE_NONE ? "none" : (gameport_0_type == TYPE_JOYSTICK ? "joystick" : "CD32 gamepad"));
#endif
	}

	if (pot_bits & PORT_1_POT_BITS)
	{
		gameport_1_type = pt1210_gameport_detect(PORT_1);
#ifdef DEBUG
		kprintf("Gameport 1 type: %s\n", gameport_1_type == TYPE_NONE ? "none" : (gameport_1_type == TYPE_JOYSTICK ? "joystick" : "CD32 gamepad"));
#endif
	}

	return pot_bits != 0;
}

void pt1210_gameport_free()
{
	if (pot_bits)
		FreePotBits(pot_bits);
}

gameport_type_t pt1210_gameport_detect(gameport_port_t port)
{
	/* Perform a button read including the extra nonexistant buttons */
	uint16_t state = read_gamepad_buttons(port, true);

	/* If the nonexistant buttons 8 and 9 are not in the same state, we have a CD32 pad */
	if (event_active(state, EVENT_BUTTON_8) != event_active(state, EVENT_BUTTON_9))
		return TYPE_CD32_GAMEPAD;

	return TYPE_JOYSTICK;
}

/* Called from VBlank interrupt server */
void pt1210_gameport_process_buttons()
{
	if (!processing_enabled || (gameport_0_type == TYPE_NONE && gameport_1_type == TYPE_NONE))
		return;

	if (gameport_1_type != TYPE_NONE)
	{
		gameport_1_state = read_joystick(PORT_1);

		if (gameport_1_type == TYPE_CD32_GAMEPAD)
		{
			gameport_1_state |= read_gamepad_buttons(PORT_1, false);

			/* Map CD32 red/blue to joystick buttons 1 and 2 */
			gameport_1_state |= ((gameport_1_state >> EVENT_BUTTON_RED) & 1) << EVENT_BUTTON_1 | ((gameport_1_state >> EVENT_BUTTON_BLUE) & 1) << EVENT_BUTTON_2;
		}

		/* Has the state changed? */
		if (gameport_1_state != last_gameport1_state)
		{
	#ifdef DEBUG
			kprintf("Gameport 1 state: 0x%04lx\n", gameport_1_state);
	#endif

			/* Update binding states */
			uint16_t gameport_1_handled = gameport_1_state;
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