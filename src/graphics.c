/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * graphics.c
 * Intuition screen and graphics-related functions.
 */

#include <exec/memory.h>
#include <graphics/gfxbase.h>
#include <hardware/custom.h>
#include <hardware/intbits.h>
#include <intuition/intuition.h>

#include <proto/exec.h>
#include <proto/graphics.h>
#include <proto/intuition.h>

#include "graphics.h"

/* Assembler VBlank routine */
void pt1210_gfx_vblank_server_proc();

extern struct Custom custom;

static struct Screen* screen = NULL;
static struct Interrupt* vblank_server = NULL;
/*static*/ bool vblank_enabled = true;

bool pt1210_gfx_open_screen()
{
	/* Open a new Intuition screen */
	struct NewScreen new_screen =
	{
		.LeftEdge = 0,
		.TopEdge = 0,
		.Width = 320,
		.Height = 12,
		.Depth = 1,
		.DetailPen = 0,
		.BlockPen = 1,
		.ViewModes = 0,
		.Type = CUSTOMSCREEN,
		.Font = NULL,
		.DefaultTitle = "PT1210",
		.Gadgets = NULL,
		.CustomBitMap = NULL
	};

	screen = OpenScreen(&new_screen);
	LoadView(NULL);
	WaitTOF();
	WaitTOF();

	return true;
}

void pt1210_gfx_close_screen()
{
	LoadView(GfxBase->ActiView);
	WaitTOF();
	WaitTOF();

	/* Restore original Copper list */
	custom.cop1lc = (ULONG) GfxBase->copinit;
	RethinkDisplay();

	CloseScreen(screen);
}

bool pt1210_gfx_install_vblank_server()
{
	vblank_server = AllocMem(sizeof(struct Interrupt), MEMF_PUBLIC|MEMF_CLEAR);
	if (!vblank_server)
		return false;

	/* Set up the VBLANK interrupt structure */
	vblank_server->is_Node.ln_Type = NT_INTERRUPT;
	vblank_server->is_Node.ln_Pri = 0;
	vblank_server->is_Node.ln_Name = "PT1210 VBlank";
	vblank_server->is_Data = NULL;
	vblank_server->is_Code = pt1210_gfx_vblank_server_proc;

	/* Install interrupt server */
	AddIntServer(INTB_VERTB, vblank_server);

	return true;
}

void pt1210_gfx_remove_vblank_server()
{
	RemIntServer(INTB_VERTB, vblank_server);
	FreeMem(vblank_server, sizeof(struct Interrupt));
}

void pt1210_gfx_enable_vblank_server(bool enabled)
{
	vblank_enabled = enabled;
}