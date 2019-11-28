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

#include "audiodevice.h"
#include "cia.h"
#include "consoledevice.h"
#include "fileselector.h"
#include "filesystem.h"
#include "gameport.h"
#include "graphics.h"
#include "inputdevice.h"

void pt1210_asm_initialize();
void pt1210_asm_shutdown();

/* These globals can be updated via the VBlank interrupt; prevent them being optimised away with 'volatile' */
volatile bool quit = false;
volatile file_selector_state_t pt1210_fs_state = STATE_IDLE;

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

	/* Main loop */
	while (!quit)
	{
		switch (pt1210_fs_state)
		{
			case STATE_PENDING_SELECT:
				pt1210_fs_select();
				pt1210_fs_state = STATE_IDLE;
				break;

			case STATE_PENDING_PARENT:
				pt1210_fs_parent();
				pt1210_fs_state = STATE_IDLE;
				break;

			case STATE_PENDING_RESCAN:
				pt1210_fs_rescan();
				pt1210_fs_state = STATE_IDLE;
				break;

			default:
				break;
		}
	}

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