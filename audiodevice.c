/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * audiodevice.c
 * Audio device allocation/release.
 */

#include <stdio.h>

#include <clib/alib_protos.h>
#include <devices/audio.h>
#include <proto/exec.h>

#include "audiodevice.h"

static struct IOAudio* audio_io = NULL;		/* storage for audio IORequest pointer */
static struct MsgPort* audio_port = NULL;	/* storage for audio port pointer */
static bool device_open = false;			/* flag to denote device open */

bool pt1210_audio_open_device()
{
	audio_port = CreatePort(0, 0);
	if (!audio_port)
	{
		fprintf(stderr, "Failed to open message port for %s\n", AUDIONAME);
		return false;
	}

	audio_io = (struct IOAudio*) AllocMem(sizeof(struct IOAudio), MEMF_PUBLIC | MEMF_CLEAR);

	if (!audio_io)
	{
		fprintf(stderr, "Failed to allocate memory for IO request\n");
		return false;
	}

	/* Get all four channels */
	UBYTE channel_mask = 0x0F;
	audio_io->ioa_Request.io_Message.mn_Node.ln_Pri = ADALLOC_MAXPREC;
	audio_io->ioa_Request.io_Message.mn_ReplyPort = audio_port;
	audio_io->ioa_AllocKey = 0;
	audio_io->ioa_Data = &channel_mask;
	audio_io->ioa_Length = sizeof(channel_mask);

	device_open = !OpenDevice(AUDIONAME, 0L, (struct IORequest*) audio_io, 0L);

	if (!device_open)
	{
		fprintf(stderr, "Failed to open %s, error code: %d\n", AUDIONAME, audio_io->ioa_Request.io_Error);
		return false;
	}

	return true;
}

void pt1210_audio_close_device()
{
	if (device_open)
		CloseDevice((struct IORequest*) audio_io);

	if (audio_io)
		FreeMem(audio_io, sizeof(struct IOAudio));

	if (audio_port)
		DeletePort(audio_port);
}