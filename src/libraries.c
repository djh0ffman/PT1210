/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * libraries.c
 * System library open/close functions for startup and shutdown.
 */

#include <proto/dos.h>
#include <proto/exec.h>

#include "libraries.h"

/* Global variables referenced by amiga.lib stub */
struct GfxBase* GfxBase = NULL;
struct IntuitionBase* IntuitionBase = NULL;

bool pt1210_libs_open()
{
	/* Attempt to open system libraries, v33 (Kickstart 1.2) or above */
	if (!(DOSBase = (struct DosLibrary*) OpenLibrary("dos.library", 33L)))
		return false;

	if (!(GfxBase = (struct GfxBase*) OpenLibrary("graphics.library", 33L)))
		return false;

	if (!(IntuitionBase = (struct IntuitionBase*) OpenLibrary("intuition.library", 33L)))
		return false;

	return true;
}

void pt1210_libs_close()
{
	if (IntuitionBase)
		CloseLibrary((struct Library*) IntuitionBase);

	if (GfxBase)
		CloseLibrary((struct Library*) GfxBase);

	if (DOSBase)
		CloseLibrary((struct Library*) DOSBase);
}