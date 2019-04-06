/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * consoledevice.c
 * Console device allocation/release.
 */

#include <stdio.h>

#include <clib/alib_protos.h>
#include <devices/conunit.h>
#include <proto/exec.h>

#include "consoledevice.h"

/* Global variable referenced by amiga.lib stub */
struct Device* ConsoleDevice;

static struct IOStdReq* console_io = NULL;	/* storage for console IORequest pointer */
static struct MsgPort* console_port = NULL;	/* storage for console port pointer */

bool pt1210_console_open_device()
{
	console_port = CreatePort(0, 0);
	if (!console_port)
	{
		fprintf(stderr, "Failed to open message port for console.device\n");
		return false;
	}

	console_io = (struct IOStdReq*) CreateExtIO(console_port, sizeof(struct IOStdReq));
	if (!console_io)
	{
		fprintf(stderr, "Failed to allocate IO request for console.device\n");
		return false;
	}

	/* We don't want an actual console; just the library base, hence unit is CONU_LIBRARY */
	if (OpenDevice("console.device", CONU_LIBRARY, (struct IORequest*) console_io, 0L))
	{
		fprintf(stderr, "Failed to open console.device, error code: %d\n", console_io->io_Error);
		return false;
	}

	/* Get the library base from the IORequest */
	ConsoleDevice = console_io->io_Device;

	return true;
}

void pt1210_console_close_device()
{
	if (ConsoleDevice)
	{
		CloseDevice((struct IORequest*) console_io);
		ConsoleDevice = NULL;
	}

	if (console_io)
		DeleteExtIO((struct IORequest*) console_io);

	if (console_port)
		DeletePort(console_port);
}