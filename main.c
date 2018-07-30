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

#include <exec/libraries.h>
#include <proto/exec.h>
#include <proto/dos.h>

void START();

int main(int argc, char** argv)
{
	/* Attempt to open DOS library, v33 (Kickstart 1.2) or above */
	DOSBase = (struct DosLibrary*) OpenLibrary("dos.library", 33L);
	if (!DOSBase)
		return EXIT_FAILURE;

	/* Jump into ASM */
	START();

	/* Clean up */
	CloseLibrary((struct Library*) DOSBase);

	return EXIT_SUCCESS;
}