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

#include <stdlib.h>

#include <exec/memory.h>
#include <graphics/gfxbase.h>
#include <hardware/custom.h>
#include <hardware/intbits.h>
#include <intuition/intuition.h>
#include <intuition/intuitionbase.h>

#include <clib/debug_protos.h>
#include <proto/exec.h>
#include <proto/graphics.h>
#include <proto/intuition.h>

#include "graphics.h"
#include "pt1210.h"

/* Assembler VBlank routine */
void pt1210_gfx_vblank_server_proc();

extern struct Custom custom;

static struct Screen* wb_screen = NULL;
static struct Screen* pt1210_screen = NULL;
static struct Interrupt* vblank_server = NULL;
/*static*/ bool vblank_enabled = false;

static struct View* old_view = NULL;
static bool screen_active = false;

static inline void restore_copper()
{
	/* Restore original Copper list */
	custom.cop1lc = (ULONG) GfxBase->copinit;
}

static void remove_view()
{
	old_view = GfxBase->ActiView;
	LoadView(NULL);
	WaitTOF();
	WaitTOF();
}

static void restore_view()
{
	WaitTOF();
	WaitTOF();
	LoadView(old_view);
}

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

	/* Store current frontmost screen */
	wb_screen = IntuitionBase->FirstScreen;

	/* Open our new screen */
	pt1210_screen = OpenScreen(&new_screen);

	/* Tear down system View */
	remove_view();

	screen_active = true;
	return true;
}

void pt1210_gfx_close_screen()
{
	if (screen_active)
	{
		restore_copper();
		restore_view();
		screen_active = false;
	}

	CloseScreen(pt1210_screen);
}

bool pt1210_gfx_screen_check_active()
{
	bool active = IntuitionBase->FirstScreen == pt1210_screen;

	if (!active)
	{
		if (IntuitionBase->FirstScreen != wb_screen)
			wb_screen = IntuitionBase->FirstScreen;

		if (screen_active)
		{
			restore_copper();

			/* Trigger screen to back in the main loop */
			pt1210_defer_function(pt1210_gfx_screen_to_back);
		}
	}

	screen_active = active;
	return screen_active;
}

void pt1210_gfx_screen_to_back()
{
	restore_copper();
	restore_view();

	ScreenToBack(pt1210_screen);
	screen_active = false;
}

bool pt1210_gfx_screen_in_front()
{
	return IntuitionBase->FirstScreen == pt1210_screen;
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
