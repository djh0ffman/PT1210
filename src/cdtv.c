/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * cdtv.c
 * CDTV-specific functions.
 */

#include <stdio.h>

#include <clib/alib_protos.h>
#include <exec/io.h>
#include <proto/exec.h>

#include "cdtv.h"

/* cdtv.device commands, from the CDTV headers on the Amiga Developer CD */
#define	CDTV_STOP		6
#define	CDTV_START		7
#define	CDTV_FRONTPANEL	39

static struct IOStdReq* cdtv_io = NULL;		/* storage for CDTV IORequest pointer */
static struct MsgPort* cdtv_port = NULL;	/* storage for CDTV port pointer */
static bool device_open = false;			/* flag to denote device open */

bool pt1210_cdtv_open_device()
{
	cdtv_port = CreatePort(0, 0);
	if (!cdtv_port)
	{
		fprintf(stderr, "Failed to open message port for cdtv.device\n");
		return false;
	}

	cdtv_io = CreateStdIO(cdtv_port);
	if (!cdtv_io)
	{
		fprintf(stderr, "Failed to allocate IO request for cdtv.device\n");
		return false;
	}

	device_open = !OpenDevice("cdtv.device", 0L, (struct IORequest*) cdtv_io, 0L);
	if (!device_open)
	{
		fprintf(stderr, "Failed to open cdtv.device, error code: %d\n", cdtv_io->io_Error);
		return false;
	}

	return true;
}

void pt1210_cdtv_enable_front_panel(bool enabled)
{
	if (!device_open)
		return;

	cdtv_io->io_Command = CDTV_FRONTPANEL;
	cdtv_io->io_Length = enabled;

	DoIO((struct IORequest*) cdtv_io);
}

void pt1210_cdtv_enable_cd_driver(bool enabled)
{
	if (!device_open)
		return;

	cdtv_io->io_Command = enabled ? CDTV_START : CDTV_STOP;
	cdtv_io->io_Length = 0;

	DoIO((struct IORequest*) cdtv_io);
}

void pt1210_cdtv_close_device()
{
	if (device_open)
	{
		CloseDevice((struct IORequest*) cdtv_io);
		device_open = false;
	}

	if (cdtv_io)
	{
		DeleteStdIO(cdtv_io);
		cdtv_io = NULL;
	}

	if (cdtv_port)
	{
		DeletePort(cdtv_port);
		cdtv_port = NULL;
	}
}