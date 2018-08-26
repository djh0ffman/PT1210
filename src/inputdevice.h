/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * inputdevice.h
 * Input device allocation/release and handling.
 */

#ifndef INPUT_DEVICE_H
#define INPUT_DEVICE_H

#include <stdbool.h>

bool pt1210_input_open_device();
void pt1210_input_close_device();
bool pt1210_input_install_handler();
void pt1210_input_remove_handler();

#endif /* INPUT_DEVICE_H */