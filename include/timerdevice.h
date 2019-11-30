/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * timerdevice.h
 * Clock
 */

#ifndef TIMER_DEVICE_H
#define TIMER_DEVICE_H

#include <stdbool.h>

bool pt1210_timer_open_device();
void pt1210_timer_close_device();
void pt1210_timer_reset();
void pt1210_timer_pause();
void pt1210_timer_play();
void pt1210_timer_update();

#endif /* TIMER_DEVICE_H */
