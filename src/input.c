/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * input.c
 * Input binding/handler types and processing.
 */

#include <stdbool.h>

#include "input.h"

void pt1210_input_process_bindings(input_binding_t* binding_list, size_t length)
{
	for (size_t i = 0; i < length; ++i)
	{
		input_binding_t* binding = &binding_list[i];
		uint8_t* frames_held = &binding->state.frames_held;

		if (binding->state.pressed)
		{
			switch (binding->type)
			{
				/* Call handler once */
				case PRESS_TYPE_ONESHOT:
					binding->state.pressed = false;
					binding->handler();
					break;

				/* Call handler every frame */
				case PRESS_TYPE_REPEAT:
					binding->handler();
					break;

				/* Call handler once after key held */
				case PRESS_TYPE_HOLD_ONESHOT:
					if (*frames_held <= 30)
					{
						++*frames_held;
						break;
					}
					else if (*frames_held > 31)
						break;

					++*frames_held;
					binding->handler();
					break;

				/* Call handler on initial press, then repeat if held */
				case PRESS_TYPE_HOLD_REPEAT:
					if (*frames_held == 0)
					{
						++*frames_held;
						binding->handler();
						break;
					}

					if (*frames_held <= 32)
					{
						++*frames_held;
						break;
					}

					*frames_held = 30;
					binding->handler();
					break;

				default:
					break;
			}
		}
		else
		{
			/* Reset frame counter */
			*frames_held = 0;
		}
	}
}