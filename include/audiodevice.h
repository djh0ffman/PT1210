/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * audiodevice.h
 * Audio device allocation/release.
 */

#ifndef AUDIO_DEVICE_H
#define AUDIO_DEVICE_H

#include <stdbool.h>

bool pt1210_audio_open_device();
void pt1210_audio_close_device();

#endif /* AUDIO_DEVICE_H */
