/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * inputdevice.c
 * Input device allocation/release and handling.
 */

#include <stdio.h>

#include <clib/alib_protos.h>
#include <clib/debug_protos.h>
#include <devices/input.h>
#include <devices/inputevent.h>
#include <dos/dos.h>
#include <exec/interrupts.h>
#include <proto/console.h>
#include <proto/exec.h>

#include "inputdevice.h"
#include "keyboard.h"
#include "utility.h"

static struct IOStdReq* input_io = NULL;	/* storage for input IORequest pointer */
static struct MsgPort* input_port = NULL;	/* storage for input port pointer */
static bool device_open = false;			/* flag to denote device open */
static struct Interrupt* input_handler = NULL;

static struct InputEvent* pt1210_input_handler(REG(a0, struct InputEvent* event_list), REG(a1, void* data))
{
	struct InputEvent* prev_event = NULL;
	struct InputEvent* cur_event = event_list;

	do
	{
		if (cur_event->ie_Class == IECLASS_RAWKEY)
		{
			bool pressed = !(cur_event->ie_Code & 0x80);

#ifdef DEBUG
			kprintf("Key scancode 0x%02lx %s\n", (cur_event->ie_Code & ~0x80),  pressed ? "pressed" : "released");
#endif
			if (pressed)
			{
				/* Check for letter key using console.device and default system keymap */
				char buffer;
				int32_t result = RawKeyConvert(cur_event, &buffer, sizeof(buffer), NULL);

				if (result > 0)
				{
#ifdef DEBUG
					kprintf("RawKeyConvert() returned %ld, 0x%02lx -> %lc\n", result, cur_event->ie_Code, buffer);
#endif
					pt1210_keyboard_update_character_key(buffer);
				}
			}

			pt1210_keyboard_update_raw_key(cur_event->ie_Code);

			/* Unlink this event so it doesn't get passed down the handler chain */
			if (prev_event)
				prev_event->ie_NextEvent = cur_event->ie_NextEvent;
			else
				event_list = cur_event->ie_NextEvent;
		}

		prev_event = cur_event;
		cur_event = cur_event->ie_NextEvent;
	} while (cur_event);

	return event_list;
}

bool pt1210_input_open_device()
{
	input_port = CreatePort(0, 0);
	if (!input_port)
	{
		fprintf(stderr, "Failed to open message port for input.device\n");
		return false;
	}

	input_io = (struct IOStdReq*) CreateExtIO(input_port, sizeof(struct IOStdReq));
	if (!input_io)
	{
		fprintf(stderr, "Failed to allocate IO request for input.device\n");
		return false;
	}

	device_open = !OpenDevice("input.device", 0L, (struct IORequest*) input_io, 0L);
	if (!device_open)
	{
		fprintf(stderr, "Failed to open input.device, error code: %d\n", input_io->io_Error);
		return false;
	}

	return true;
}

void pt1210_input_close_device()
{
	if (device_open)
	{
		CloseDevice((struct IORequest*) input_io);
		device_open = false;
	}

	if (input_io)
		DeleteExtIO((struct IORequest*) input_io);

	if (input_port)
		DeletePort(input_port);
}

bool pt1210_input_install_handler()
{
	if (!input_io)
		return false;

	input_handler = AllocMem(sizeof(struct Interrupt), MEMF_PUBLIC|MEMF_CLEAR);
	if (!input_handler)
		return false;

	/* Set up the interrupt structure */
	input_handler->is_Node.ln_Type = NT_INTERRUPT;
	input_handler->is_Node.ln_Pri = 60;
	input_handler->is_Node.ln_Name = "PT1210 Input Handler";
	input_handler->is_Data = NULL;
	input_handler->is_Code = (void*) pt1210_input_handler;

	/* Install handler */
	input_io->io_Data = input_handler;
	input_io->io_Command = IND_ADDHANDLER;
	DoIO((struct IORequest*) input_io);

	return true;
}

void pt1210_input_remove_handler()
{
	if (!input_io || !input_handler)
		return;

	input_io->io_Data = input_handler;
	input_io->io_Command = IND_REMHANDLER;
	DoIO((struct IORequest*) input_io);
}