/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * action.c
 * Actions which can be triggered by input events.
 */

#include <ctype.h>
#include <stdint.h>

#include "action.h"
#include "filesystem.h"
#include "gameport.h"
#include "keyboard.h"
#include "utility.h"

/* TODO: Move these somewhere where overall program state is managed */
bool quit = false;
pt1210_screen_t current_screen = SCREEN_FILE_SELECTOR;

uint16_t channel_toggle = 0xF;

bool loop_active = false;
uint8_t loop_start = 0;
uint8_t loop_end = 0;
uint8_t loop_size = 4;
bool slip_on = true;

bool repitch_enabled = true;
bool pattern_slip_pending = false;

/* TODO: Move these to file selector C module */
bool pt1210_fs_load_pending = false;
bool pt1210_fs_rescan_pending = false;
bool pt1210_fs_show_kb = false;

/* ASM player variables */
/* TODO: Rename so the names are more in line with our new C code */
extern bool mt_TuneEnd;
extern bool mt_Enabled;

extern uint8_t mt_PatternLock;
extern uint8_t mt_PatLockStart;
extern uint8_t mt_PatLockEnd;

extern uint8_t* mt_SongDataPtr;
extern uint8_t mt_speed;
extern uint8_t mt_counter;
extern uint8_t mt_SongLen;
extern uint8_t mt_SongPos;
extern uint16_t mt_PatternPos;
extern uint8_t mt_SLSongPos;
extern uint16_t mt_SLPatternPos;
extern uint8_t mt_PatternCue;
extern uint8_t mt_PattDelTime;
extern uint8_t mt_PattDelTime2;

/* ASM timer variables */
extern uint8_t Time_Frames;
extern uint8_t Time_Seconds;
extern uint8_t Time_Minutes;

/* ASM CIA interrupt variables */
extern uint8_t CIABPM;
extern int16_t OFFBPM;
extern uint8_t BPMFINE;
extern uint16_t NUDGE;

/* ASM file selector variables */
extern uint16_t FS_Current;

/* ASM functions */
void FS_DrawDir(REG(d5, bool show_kb));
void FS_DrawType(REG(d0, bool show_kb));
void FS_Move(REG(d2, int16_t count));
void mt_end();

void pt1210_action_switch_screen()
{
	current_screen = current_screen == SCREEN_FILE_SELECTOR ? SCREEN_DJ : SCREEN_FILE_SELECTOR;
	pt1210_keyboard_switch_binding_list(current_screen);
	pt1210_gameport_switch_binding_list(current_screen);
}

void pt1210_action_pitch_up()
{
	if (CIABPM + OFFBPM < 300)
		++OFFBPM;
}

void pt1210_action_pitch_down()
{
	if (CIABPM + OFFBPM > 20)
		--OFFBPM;
}

void pt1210_action_pitch_up_fine()
{
	if (BPMFINE + 1 < 16)
		++BPMFINE;
	else if (CIABPM + OFFBPM < 300)
	{
		++OFFBPM;
		BPMFINE = 0;
	}
}

void pt1210_action_pitch_down_fine()
{
	if (BPMFINE - 1 >= 0)
		--BPMFINE;
	else if (CIABPM + OFFBPM > 20)
	{
		--OFFBPM;
		BPMFINE = 15;
	}
}

void pt1210_action_nudge_forward()
{
	NUDGE = 1;
}

void pt1210_action_nudge_backward()
{
	NUDGE = -1;
}

void pt1210_action_nudge_forward_hard()
{
	NUDGE = 6;
}

void pt1210_action_nudge_backward_hard()
{
	NUDGE = -6;
}

void pt1210_action_play_pause()
{
	/* Kill audio if pausing */
	if (mt_Enabled)
		pt1210_action_kill_sound_dma();

	mt_Enabled = !mt_Enabled;
}

void pt1210_action_restart()
{
	mt_SongPos = mt_PatternCue;
	mt_counter = mt_speed;
	mt_TuneEnd = false;
	mt_PatternPos = 0;
	mt_PattDelTime = 0;
	mt_PattDelTime2 = 0;
	Time_Frames = 0;
	Time_Minutes = 0;
	Time_Seconds = 0;
}

void pt1210_action_slip_restart()
{
	pattern_slip_pending = !pattern_slip_pending;
}

void pt1210_action_pattern_cue_set()
{
	mt_PatternCue = mt_SongPos;
}

void pt1210_action_pattern_cue_move_forward()
{
	uint8_t song_length = mt_SongDataPtr[PT_SONG_LENGTH_OFFSET];
	if (mt_PatternCue + 1 < song_length)
		++mt_PatternCue;
}

void pt1210_action_pattern_cue_move_backward()
{
	if (mt_PatternCue > 0)
		--mt_PatternCue;
}

void pt1210_action_pattern_loop()
{
	switch (mt_PatternLock)
	{
		/* Set start of pattern loop */
		case PATTERN_LOOP_STATE_DISABLED:
			mt_PatLockStart = mt_SongPos;
			mt_PatternLock = PATTERN_LOOP_STATE_START_SET;
			break;

		/* Set end of pattern loop */
		case PATTERN_LOOP_STATE_START_SET:
			mt_PatLockEnd = mt_SongPos;
			mt_PatternLock = PATTERN_LOOP_STATE_END_SET;
			break;

		/* Clear pattern loop */
		case PATTERN_LOOP_STATE_END_SET:
			mt_PatLockStart = 0;
			mt_PatLockEnd = 0;
			mt_PatternLock = PATTERN_LOOP_STATE_DISABLED;
			break;
	}
}

void pt1210_action_loop_increase()
{
	if (loop_size == 32)
		return;

	loop_size <<= 1;
	loop_end = loop_start + loop_size;
}

void pt1210_action_loop_decrease()
{
	if (loop_size == 1)
		return;

	loop_size >>= 1;
	loop_end = loop_start + loop_size;
}

void pt1210_action_loop_cycle()
{
	if (loop_size == 32)
		loop_size = 1;
	else
		loop_size <<= 1;

	loop_end = loop_start + loop_size;
}

void pt1210_action_toggle_line_loop()
{
	if (loop_active && slip_on)
	{
		/* Stop looping */
		if (mt_SLSongPos > mt_SongLen)
		{
			/* We slipped beyond the end of the song, reset */
			mt_SongPos = 0;
			mt_PatternPos = 0;
			mt_TuneEnd = true;
		}
		else
		{
			/* Fast-forward to slipped position */
			mt_SongPos = mt_SLSongPos;
			mt_PatternPos = mt_SLPatternPos;
		}
	}
	else
	{
		/* Prepare to loop */
		mt_SLSongPos = mt_SongPos;
		mt_SLPatternPos = mt_PatternPos;

		loop_start = (mt_PatternPos >> 4) & 0xFC;
		loop_end = loop_start + loop_size;
	}

	/* Flip flag */
	loop_active = !loop_active;
}

void pt1210_action_toggle_slip()
{
	if (slip_on)
	{
		/* Reset slip */
		mt_SLSongPos = 0;
		mt_SLPatternPos = 0;
	}
	else
	{
		/* Prepare slip */
		mt_SLSongPos = mt_SongPos;
		mt_SLPatternPos = mt_PatternPos;
	}

	/* Flip flag */
	slip_on = !slip_on;
}

void pt1210_action_toggle_channel_1()
{
	channel_toggle ^= 1;
}

void pt1210_action_toggle_channel_2()
{
	channel_toggle ^= 1 << 1;
}

void pt1210_action_toggle_channel_3()
{
	channel_toggle ^= 1 << 2;
}

void pt1210_action_toggle_channel_4()
{
	channel_toggle ^= 1 << 3;
}

void pt1210_action_toggle_repitch()
{
	repitch_enabled = !repitch_enabled;
}

void pt1210_action_kill_sound_dma()
{
	mt_end();
}

void pt1210_action_move_forward_line_loop()
{
	uint8_t song_length = mt_SongDataPtr[PT_SONG_LENGTH_OFFSET];
	uint32_t new_pos = mt_PatternPos + (loop_size << 4);

	/* Overflow; wrap to next pattern */
	if (new_pos >= PT_PATTERN_DATA_LEN && mt_SongPos + 1 < song_length)
		++mt_SongPos;

	mt_PatternPos = new_pos % PT_PATTERN_DATA_LEN;
}

void pt1210_action_move_forward_pattern()
{
	uint8_t song_length = mt_SongDataPtr[PT_SONG_LENGTH_OFFSET];
	if (mt_SongPos + 1 < song_length)
		++mt_SongPos;
}

void pt1210_action_move_backward_line_loop()
{
	uint32_t new_pos = mt_PatternPos - (loop_size << 4);

	/* Overflow; wrap to previous pattern */
	if (new_pos >= PT_PATTERN_DATA_LEN && mt_SongPos > 0)
		--mt_SongPos;

	mt_PatternPos = new_pos % PT_PATTERN_DATA_LEN;
}

void pt1210_action_move_backward_pattern()
{
	if (mt_SongPos > 0)
		--mt_SongPos;
}

void pt1210_action_quit()
{
	/* Only allow quit when not playing */
	if (!mt_Enabled)
		quit = true;
}

void pt1210_action_fs_char_handler(char character)
{
	/* Ignore non-alpha characters */
	if (!isalpha(character))
		return;

	/* Uppercase our character */
	character = toupper(character);

	/* Find the first matching item in the file list and move to it */
	size_t index;

	if (pt1210_file_find_first(character, &index))
		FS_Move(index - FS_Current);
}

void pt1210_action_fs_move_up()
{
	FS_Move(-1);
}

void pt1210_action_fs_move_down()
{
	FS_Move(1);
}

void pt1210_action_fs_load_tune()
{
	/* Trigger tune loading in the main loop */
	pt1210_fs_load_pending = true;
}

void pt1210_action_fs_sort_name()
{
	static bool descending = false;

	descending = !descending;
	pt1210_file_sort_list(SORT_DISPLAY_NAME, descending);

	FS_DrawDir(pt1210_fs_show_kb);
}

void pt1210_action_fs_sort_bpm()
{
	static bool descending = false;

	descending = !descending;
	pt1210_file_sort_list(SORT_BPM, descending);

	FS_DrawDir(pt1210_fs_show_kb);
}

void pt1210_action_fs_toggle_show_kb()
{
	pt1210_fs_show_kb = !pt1210_fs_show_kb;
	FS_DrawType(pt1210_fs_show_kb);
	FS_DrawDir(pt1210_fs_show_kb);
}

void pt1210_action_fs_rescan()
{
	/* Trigger rescan in the main loop */
	pt1210_fs_rescan_pending = true;
}