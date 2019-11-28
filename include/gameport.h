/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * gameport.h
 * Joystick/CD32 gamepad handling and button bindings.
 */

#include <stdbool.h>

#include "state.h"

#ifndef GAMEPORT_H
#define GAMEPORT_H

/* POTGO/POTGOR (aka. POTINP) bit definitions */
#define POTGOB_START (0)		/* Start pot counters */
/* Bits 1-7 unused, reserved for chip ID */
#define POTGOB_DATLX (8)		/* State of gameport 0 pin 5 */
#define POTGOB_OUTLX (9)		/* Enable output for gameport 0 pin 5 */
#define POTGOB_DATLY (10)		/* State of gameport 0 pin 9 */
#define POTGOB_OUTLY (11)		/* Enable output for gameport 0 pin 9 */
#define POTGOB_DATRX (12)		/* State of gameport 1 pin 5 */
#define POTGOB_OUTRX (13)		/* Enable output for gameport 1 pin 5 */
#define POTGOB_DATRY (14)		/* State of gameport 1 pin 9 */
#define POTGOB_OUTRY (15)		/* Enable output for gameport 1 pin 9 */

#define POTGOF_START (1 << POTGOB_START)
#define POTGOF_DATLX (1 << POTGOB_DATLX)
#define POTGOF_OUTLX (1 << POTGOB_OUTLX)
#define POTGOF_DATLY (1 << POTGOB_DATLY)
#define POTGOF_OUTLY (1 << POTGOB_OUTLY)
#define POTGOF_DATRX (1 << POTGOB_DATRX)
#define POTGOF_OUTRX (1 << POTGOB_OUTRX)
#define POTGOF_DATRY (1 << POTGOB_DATRY)
#define POTGOF_OUTRY (1 << POTGOB_OUTRY)

/* POTGO bits to allocate for reading CD32 gamepad */
#define PORT_0_POT_BITS (POTGOF_DATLX | POTGOF_OUTLX)
#define PORT_1_POT_BITS (POTGOF_DATRX | POTGOF_OUTRX)

typedef enum
{
	PORT_0,
	PORT_1
} gameport_port_t;

typedef enum
{
	TYPE_NONE,
	TYPE_JOYSTICK,
	TYPE_CD32_GAMEPAD
} gameport_type_t;

/* Gameport directions and buttons */
typedef enum
{
	/* Standard Amiga joystick events */
	EVENT_UP,
	EVENT_DOWN,
	EVENT_LEFT,
	EVENT_RIGHT,
	EVENT_BUTTON_1,
	EVENT_BUTTON_2,

	/* CD32 gamepad buttons; don't change the order of the following enums */
	EVENT_BUTTON_BLUE,
	EVENT_BUTTON_RED,
	EVENT_BUTTON_YELLOW,
	EVENT_BUTTON_GREEN,
	EVENT_BUTTON_FAST_FORWARD,
	EVENT_BUTTON_REWIND,
	EVENT_BUTTON_PLAYPAUSE,
	EVENT_BUTTON_8,
	EVENT_BUTTON_9,

	EVENT_NONE
} gameport_event_t;

void pt1210_gameport_enable_processing(bool enabled);
void pt1210_gameport_switch_binding_list(screen_state_t screen);
bool pt1210_gameport_allocate();
void pt1210_gameport_free();
gameport_type_t pt1210_gameport_detect(gameport_port_t port);
void pt1210_gameport_process_buttons();

#endif /* GAMEPORT_H */