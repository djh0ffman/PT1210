/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * consoledevice.h
 * Console device allocation/release.
 */

#ifndef CONSOLE_DEVICE_H
#define CONSOLE_DEVICE_H

#include <stdbool.h>

bool pt1210_console_open_device();
void pt1210_console_close_device();

#endif /* CONSOLE_DEVICE_H */