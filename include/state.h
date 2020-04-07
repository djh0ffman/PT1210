/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * state.h
 * Program state information.
 */

#ifndef STATE_H
#define STATE_H

#include <stdint.h>

/* Forward declaration */
struct Task;

typedef enum
{
	SCREEN_FILE_SELECTOR,
	SCREEN_DJ
} screen_state_t;

typedef enum
{
	PATTERN_LOOP_STATE_DISABLED,
	PATTERN_LOOP_STATE_START_SET,
	PATTERN_LOOP_STATE_END_SET
} pattern_loop_state_t;

/* The following structures must be packed, and match the ASM definitions in state.i */
#pragma pack(1)
typedef struct
{
	uint16_t channel_toggle;
	bool loop_active;
	uint8_t loop_start;
	uint8_t loop_end;
	uint8_t loop_size;
	bool slip_on;
	bool repitch_enabled;
	bool repitch_lock_enabled;
	bool pattern_slip_pending;
} player_state_t;

typedef struct
{
	/* UI state */
	screen_state_t screen;

	/* Player state */
	player_state_t player;
} global_state_t;
#pragma pack()

extern volatile global_state_t pt1210_state;

#endif /* STATE_H */
