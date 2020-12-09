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

#ifndef GAMEPORT_H
#define GAMEPORT_H

#include <stdbool.h>

#include <libraries/lowlevel.h>

#include "state.h"

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
	/* Standard Amiga joystick events; don't change the order of the following enums */
	EVENT_RIGHT = JPB_JOY_RIGHT,
	EVENT_LEFT = JPB_JOY_LEFT,
	EVENT_DOWN = JPB_JOY_DOWN,
	EVENT_UP = JPB_JOY_UP,
	EVENT_BUTTON_1 = JPB_BUTTON_RED,
	EVENT_BUTTON_2 = JPB_BUTTON_BLUE,

	/* CD32 gamepad buttons*/
	EVENT_BUTTON_PLAYPAUSE = JPB_BUTTON_PLAY,
	EVENT_BUTTON_REWIND = JPB_BUTTON_REVERSE,
	EVENT_BUTTON_FAST_FORWARD = JPB_BUTTON_FORWARD,
	EVENT_BUTTON_GREEN = JPB_BUTTON_GREEN,
	EVENT_BUTTON_YELLOW = JPB_BUTTON_YELLOW,
	EVENT_BUTTON_RED = JPB_BUTTON_RED,
	EVENT_BUTTON_BLUE = JPB_BUTTON_BLUE,

	EVENT_NONE
} gameport_event_t;

void pt1210_gameport_enable_processing(bool enabled);
void pt1210_gameport_switch_binding_list(screen_state_t screen);
bool pt1210_gameport_open();
void pt1210_gameport_close();
gameport_type_t pt1210_gameport_detect(gameport_port_t port);
void pt1210_gameport_process_buttons();

#endif /* GAMEPORT_H */
