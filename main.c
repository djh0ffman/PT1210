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
 * Startup / Restore Code - Stingray
 * C conversion - d0pefish
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <exec/libraries.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <clib/alib_protos.h>
#include <devices/audio.h>

ULONG audio_device;
struct IOAudio *audio_io;		/* storage for audio IORequest pointer */
struct MsgPort *audio_port;     /* storage for audio port pointer */

void START();
bool open_audiodevice();
void close_audiodevice();

int main(int argc, char** argv)
{
	/* Attempt to open DOS library, v33 (Kickstart 1.2) or above */
	DOSBase = (struct DosLibrary*) OpenLibrary("dos.library", 33L);
	if (!DOSBase)
		return EXIT_FAILURE;

	/* attempt to allocate audio device */
	if (!open_audiodevice())
		return EXIT_FAILURE;

	/* Jump into ASM */
	START();

	/* Clean up */
	CloseLibrary((struct Library*) DOSBase);
	close_audiodevice();

	return EXIT_SUCCESS;
}

bool open_audiodevice()
{
	bool ret = true;
	
	audio_port = CreatePort(0,0);
	if (audio_port == 0)
	{
		printf("%s could not create port\n",AUDIONAME);
		return false;
	}

	audio_io = (struct IOAudio *)
		AllocMem(sizeof(struct IOAudio), MEMF_PUBLIC | MEMF_CLEAR);
	
	if (audio_io)
	{
		UBYTE chans[] = {15};  /* get all four channels */
		audio_io->ioa_Request.io_Message.mn_ReplyPort = audio_port;
		audio_io->ioa_AllocKey = 0;
		audio_io->ioa_Request.io_Message.mn_Node.ln_Pri = 120;
		audio_io->ioa_Data = chans;
		audio_io->ioa_Length = sizeof(chans);
	}

	if (audio_device = OpenDevice(AUDIONAME,0L,(struct IORequest *)audio_io,0L) )
	{
		printf("%s did not open\n",AUDIONAME);
		return false;
	}

	return true;
}

void close_audiodevice()
{
	if (audio_device == 0)
		CloseDevice( (struct IORequest *) audio_io );
	if (audio_port != 0)
		DeletePort(audio_port);
	if (audio_io != 0)
		FreeMem( audio_io,sizeof(struct IOAudio) );
}
