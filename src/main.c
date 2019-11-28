/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * Concept - h0ffman & Akira
 * Code	- h0ffman
 * Graphics - Akira
 * Bug testing - Akira
 * C conversion - d0pefish
 */

#include <stdio.h>
#include <stdlib.h>

#include <proto/exec.h>
#include <clib/debug_protos.h>

#include "audiodevice.h"
#include "cia.h"
#include "consoledevice.h"
#include "fileselector.h"
#include "filesystem.h"
#include "gameport.h"
#include "graphics.h"
#include "inputdevice.h"
#include "state.h"

void pt1210_asm_initialize();
void pt1210_asm_shutdown();

/* Program state */
volatile global_state_t pt1210_state =
{
	/* Main loop information */
	.quit = 0,
	.signal_bit = 0,
	.task = NULL,
	.deferred_func = NULL,

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

int main(int argc, char** argv)
{
	/* Init filesystem */
	pt1210_file_initialize();

	/* Attempt to open console device */
	if (!pt1210_console_open_device())
		return EXIT_FAILURE;

	/* Attempt to open input device and install handler */
	if (!pt1210_input_open_device())
		return EXIT_FAILURE;

	if (!pt1210_input_install_handler())
		return EXIT_FAILURE;

	/* Attempt to open gameport */
	pt1210_gameport_allocate();

	/* Attempt to allocate audio device */
	if (!pt1210_audio_open_device())
		return EXIT_FAILURE;

	/* Attempt to allocate CIA timer */
	if (!pt1210_cia_allocate_timer())
		return EXIT_FAILURE;

	/* Attempt to open a custom Intuition screen */
	if (!pt1210_gfx_open_screen())
		return EXIT_FAILURE;

	/* Attempt to install the VBlank interrupt server */
	if (!pt1210_gfx_install_vblank_server())
		return EXIT_FAILURE;

	/* Generate initial file selector listing */
	pt1210_fs_rescan();

	/* Start timer interrupt */
	pt1210_cia_start_timer();

	/* Do some remaining ASM setup */
	pt1210_asm_initialize();

	/* Allocate signal bit */
	BYTE signal_number = AllocSignal(-1);
	if (signal_number == -1)
		return EXIT_FAILURE;

	pt1210_state.signal_bit = signal_number;
	pt1210_state.task = FindTask(NULL);

	/* Main loop */
	while (!pt1210_state.quit)
	{
#ifdef DEBUG
		kprintf("Main task sleeping\n");
#endif
		Wait(1 << pt1210_state.signal_bit);
#ifdef DEBUG
		kprintf("Main task awake\n");
#endif

		/* Perform deferred task signalled from interrupt */
		if (pt1210_state.deferred_func)
		{
			pt1210_state.deferred_func();
			pt1210_state.deferred_func = NULL;
		}
	}

	/* Free signal bit */
	FreeSignal(pt1210_state.signal_bit);

	pt1210_asm_shutdown();
	pt1210_cia_stop_timer();
	pt1210_file_free_tune_memory();

	/* Clean up */
	pt1210_gfx_remove_vblank_server();
	pt1210_gfx_close_screen();
	pt1210_cia_free_timer();
	pt1210_audio_close_device();
	pt1210_gameport_free();
	pt1210_input_remove_handler();
	pt1210_input_close_device();
	pt1210_console_close_device();
	pt1210_file_shutdown();

	return EXIT_SUCCESS;
}