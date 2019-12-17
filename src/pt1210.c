/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * pt1210.c
 * Main program task.
 */

#include "cia.h"
#include "fileselector.h"
#include "graphics.h"
#include "player.h"
#include "pt1210.h"
#include "state.h"

#include <clib/debug_protos.h>
#include <proto/exec.h>

/* Program state */
volatile global_state_t pt1210_state =
{
	/* UI state */
	.screen = SCREEN_FILE_SELECTOR,

	/* Player state */
	.player =
	{
		.channel_toggle = 0xF,
		.loop_active = false,
		.loop_start = 0,
		.loop_end = 0,
		.loop_size = 4,
		.slip_on = true,
		.repitch_enabled = true,
		.pattern_slip_pending = false
	}
};

static bool quit = false;
static uint8_t signal_bit = 0;
static struct Task* task = NULL;
static deferred_function_t deferred_func = NULL;

/* ASM functions */
void pt1210_asm_initialize();
void UI_Reset();

void pt1210_defer_function(deferred_function_t func)
{
	deferred_func = func;
	Signal(task, 1 << signal_bit);
}

void pt1210_reset()
{
	/* Reset CIA */
	pt1210_cia_base_bpm = 125;
	pt1210_cia_offset_bpm = 0;
	pt1210_cia_fine_offset = 0;

	/* Re-enable all audio channels */
	pt1210_state.player.channel_toggle = 0xF;

	/* Reset loop state */
	pt1210_state.player.loop_active = false;
	pt1210_state.player.loop_start = 0;
	pt1210_state.player.loop_end = 0;
	pt1210_state.player.loop_size = 4;

	/* Reset player state */
	pt1210_state.player.slip_on = true;
	pt1210_state.player.repitch_enabled = true;
	pt1210_state.player.pattern_slip_pending = false;

	mt_TuneEnd = false;
	mt_PatternLock = 0;
	mt_PatLockStart = 0;
	mt_PatLockEnd = 0;
	mt_PatternCue = 0;

	mt_SLSongPos = 0;
	mt_SLPatternPos = 0;

	/* Reset UI */
	UI_Reset();
}

void pt1210_quit()
{
	quit = true;
	Signal(task, 1 << signal_bit);
}

bool pt1210_initialize()
{
	/* Allocate signal bit */
	BYTE signal_number = AllocSignal(-1);
	if (signal_number == -1)
		return false;

	/* Find our task */
	signal_bit = signal_number;
	task = FindTask(NULL);

	/* Print available memory */
	pt1210_fs_draw_avail_ram();

	/* Do some remaining ASM setup */
	pt1210_asm_initialize();

	/* Generate initial file selector listing */
	pt1210_fs_rescan(false);

	/* Start timer interrupt */
	pt1210_cia_start_timer();

	/* Start VBlank */
	pt1210_gfx_enable_vblank_server(true);

	return true;
}

void pt1210_main()
{
	/* Main loop */
	while (!quit)
	{
#ifdef DEBUG
		kprintf("Main task sleeping\n");
#endif
		Wait(1 << signal_bit);
#ifdef DEBUG
		kprintf("Main task awake\n");
#endif

		/* Perform deferred task signalled from interrupt */
		if (deferred_func)
		{
			deferred_func();
			deferred_func = NULL;
		}
	}
}

void pt1210_shutdown()
{
	/* Kill sound DMA */
	mt_end();

	/* Stop VBlank */
	pt1210_gfx_enable_vblank_server(false);

	/* Stop timer interrupt */
	pt1210_cia_stop_timer();

	/* Release module memory, if we're using any */
	pt1210_file_free_tune_memory();

	/* Free signal bit */
	FreeSignal(signal_bit);
}
