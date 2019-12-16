/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * timerdevice.c
 * Clock
 */

#include <stdio.h>

#include <clib/debug_protos.h>
#include <clib/exec_protos.h>
#include <clib/timer_protos.h>

#include "timerdevice.h"

struct Device* TimerBase;
static struct IORequest time_request;
static bool device_open = false;			/* flag to denote device open */

static struct timeval time_start;
static struct timeval time_pause;
static struct timeval time_now;
static bool paused = true;

uint8_t pt1210_time_seconds;
uint8_t pt1210_time_minutes;

bool pt1210_timer_open_device()
{
    device_open = !OpenDevice("timer.device", 0, &time_request, 0);

    if (!device_open)
	{
		fprintf(stderr, "Failed to open timer device");
		return false;
	}

    TimerBase = time_request.io_Device;

    return true;
}

void pt1210_timer_close_device()
{
	if (device_open)
		CloseDevice(&time_request);
}

void pt1210_timer_reset()
{
	time_pause = time_now;
}

void pt1210_timer_pause()
{
    GetSysTime(&time_pause);
    paused = true;
}

void pt1210_timer_play()
{
    GetSysTime(&time_now);
    SubTime(&time_now, &time_pause);
    AddTime(&time_start, &time_now);
    paused = false;
}

void pt1210_timer_update()
{
    GetSysTime(&time_now);
	if (paused)
        time_now = time_pause;

    SubTime(&time_now, &time_start);

    pt1210_time_seconds = (time_now.tv_secs % 60);
    pt1210_time_minutes = (time_now.tv_secs / 60);
}
