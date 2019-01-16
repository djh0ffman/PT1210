/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * cdtv.h
 * CDTV-specific functions.
 */

#include <stdbool.h>

#ifndef CDTV_H
#define CDTV_H

bool pt1210_cdtv_open_device();
void pt1210_cdtv_close_device();
void pt1210_cdtv_enable_front_panel(bool enabled);
void pt1210_cdtv_enable_cd_driver(bool enabled);

#endif /* CDTV_H */