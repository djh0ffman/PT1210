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
#include "filesystem.h"
#include "gameport.h"
#include "graphics.h"
#include "inputdevice.h"
#include "pt1210.h"
#include "timerdevice.h"

int main(int argc, char** argv)
{
	int return_code = EXIT_FAILURE;

	/* Init filesystem */
	pt1210_file_initialize();

	/* Attempt to open console device */
	if (!pt1210_console_open_device())
		goto cleanup_file;

	/* Attempt to open input device and install handler */
	if (!pt1210_input_open_device())
		goto cleanup_console_device;

	if (!pt1210_input_install_handler())
		goto cleanup_input_device;

	/* Attempt to open gameport */
	pt1210_gameport_allocate();

	/* Attempt to allocate audio device */
	if (!pt1210_audio_open_device())
		goto cleanup_gameport;

	/* Attempt to allocate CIA timer */
	if (!pt1210_cia_allocate_timer())
		goto cleanup_audio_device;

	/* Attempt to open a custom Intuition screen */
	if (!pt1210_gfx_open_screen())
		goto cleanup_cia_timer;

	/* Attempt to install the VBlank interrupt server */
	if (!pt1210_gfx_install_vblank_server())
		goto cleanup_screen;

	/* Attempt to open the timer device */
	if (!pt1210_timer_open_device())
		goto cleanup_vblank_server;

	/* Attempt to initialize PT-1210 itself */
	if (!pt1210_initialize())
		goto cleanup_timer_device;

	/* All subsystems successfully initialized, set success return code */
	return_code = EXIT_SUCCESS;

	/* Enter the main loop */
	pt1210_main();

	/* Clean up PT-1210 */
	pt1210_shutdown();

	/* Clean up subsystems */
cleanup_timer_device:
	pt1210_timer_close_device();
cleanup_vblank_server:
	pt1210_gfx_remove_vblank_server();
cleanup_screen:
	pt1210_gfx_close_screen();
cleanup_cia_timer:
	pt1210_cia_free_timer();
cleanup_audio_device:
	pt1210_audio_close_device();
cleanup_gameport:
	pt1210_gameport_free();
/*cleanup_input_handler:*/
	pt1210_input_remove_handler();
cleanup_input_device:
	pt1210_input_close_device();
cleanup_console_device:
	pt1210_console_close_device();
cleanup_file:
	pt1210_file_shutdown();

	return return_code;
}