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
#include "cia.h"
#include "fileselector.h"
#include "filesystem.h"
#include "gameport.h"
#include "keyboard.h"
#include "player.h"
#include "pt1210.h"
#include "timerdevice.h"
#include "utility.h"

/* Wrapper for pt1210_fs_rescan() that causes it to rebuild the cache */
static void rescan_wrapper() { pt1210_fs_rescan(true); };

void pt1210_action_switch_screen()
{
	pt1210_state.screen =
		pt1210_state.screen == SCREEN_FILE_SELECTOR ? SCREEN_DJ : SCREEN_FILE_SELECTOR;
	pt1210_keyboard_switch_binding_list(pt1210_state.screen);
	pt1210_gameport_switch_binding_list(pt1210_state.screen);
}

void pt1210_action_pitch_up()
{
	pt1210_cia_increment_bpm_coarse();
}

void pt1210_action_pitch_down()
{
	pt1210_cia_decrement_bpm_coarse();
}

void pt1210_action_pitch_up_fine()
{
	pt1210_cia_increment_bpm_fine();
}

void pt1210_action_pitch_down_fine()
{
	pt1210_cia_decrement_bpm_fine();
}

void pt1210_action_nudge_forward()
{
	pt1210_cia_set_nudge(1);
}

void pt1210_action_nudge_backward()
{
	pt1210_cia_set_nudge(-1);
}

void pt1210_action_nudge_forward_hard()
{
	pt1210_cia_set_nudge(6);
}

void pt1210_action_nudge_backward_hard()
{
	pt1210_cia_set_nudge(-6);
}

void pt1210_action_play_pause()
{
	/* Kill audio if pausing */
	if (mt_Enabled)
	{
		pt1210_action_kill_sound_dma();
		pt1210_timer_pause();
	}
	else
	{
		pt1210_timer_play();
	}

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
	pt1210_timer_reset();
}

void pt1210_action_slip_restart()
{
	volatile player_state_t* player = &pt1210_state.player;
	player->pattern_slip_pending = !player->pattern_slip_pending;
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
	volatile player_state_t* player = &pt1210_state.player;

	if (player->loop_size == 32)
		return;

	player->loop_size <<= 1;
	player->loop_end = player->loop_start + player->loop_size;
}

void pt1210_action_loop_decrease()
{
	volatile player_state_t* player = &pt1210_state.player;

	if (player->loop_size == 1)
		return;

	player->loop_size >>= 1;
	player->loop_end = player->loop_start + player->loop_size;
}

void pt1210_action_loop_cycle()
{
	volatile player_state_t* player = &pt1210_state.player;

	if (player->loop_size == 32)
		player->loop_size = 1;
	else
		player->loop_size <<= 1;

	player->loop_end = player->loop_start + player->loop_size;
}

void pt1210_action_toggle_line_loop()
{
	volatile player_state_t* player = &pt1210_state.player;

	if (player->loop_active && player->slip_on)
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

		player->loop_start = (mt_PatternPos >> 4) & 0xFC;
		player->loop_end = player->loop_start + player->loop_size;
	}

	/* Flip flag */
	player->loop_active = !player->loop_active;
}

void pt1210_action_toggle_slip()
{
	volatile player_state_t* player = &pt1210_state.player;

	if (player->slip_on)
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
	player->slip_on = !player->slip_on;
}

void pt1210_action_toggle_channel_1()
{
	pt1210_state.player.channel_toggle ^= 1;
}

void pt1210_action_toggle_channel_2()
{
	pt1210_state.player.channel_toggle ^= 1 << 1;
}

void pt1210_action_toggle_channel_3()
{
	pt1210_state.player.channel_toggle ^= 1 << 2;
}

void pt1210_action_toggle_channel_4()
{
	pt1210_state.player.channel_toggle ^= 1 << 3;
}

void pt1210_action_toggle_repitch()
{
	volatile player_state_t* player = &pt1210_state.player;
	player->repitch_enabled = !player->repitch_enabled;
}

void pt1210_action_kill_sound_dma()
{
	mt_end();
}

void pt1210_action_move_forward_line_loop()
{
	volatile player_state_t* player = &pt1210_state.player;

	uint8_t song_length = mt_SongDataPtr[PT_SONG_LENGTH_OFFSET];
	uint32_t new_pos = mt_PatternPos + (player->loop_size << 4);

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
	volatile player_state_t* player = &pt1210_state.player;
	uint32_t new_pos = mt_PatternPos - (player->loop_size << 4);

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
		pt1210_quit();
}

void pt1210_action_fs_page_up()
{
	pt1210_fs_move(-FS_HEIGHT_CHARS);
}

void pt1210_action_fs_page_down()
{
	pt1210_fs_move(FS_HEIGHT_CHARS);
}

void pt1210_action_fs_move_up()
{
	pt1210_fs_move(-1);
}

void pt1210_action_fs_move_down()
{
	pt1210_fs_move(1);
}

void pt1210_action_fs_parent()
{
	/* Trigger parent in main loop */
	pt1210_defer_function(pt1210_fs_parent);
}

void pt1210_action_fs_select()
{
	/* Trigger selection in the main loop */
	pt1210_defer_function(pt1210_fs_select);
}

void pt1210_action_fs_sort_name()
{
	pt1210_fs_set_sort(SORT_NAME);
}

void pt1210_action_fs_sort_bpm()
{
	pt1210_fs_set_sort(SORT_BPM);
}

void pt1210_action_fs_rescan()
{
	/* Trigger rescan in the main loop */
	pt1210_defer_function(rescan_wrapper);
}
