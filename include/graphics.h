/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * graphics.h
 * Intuition screen and graphics-related functions.
 */

#ifndef GRAPHICS_H
#define GRAPHICS_H

#include <stdbool.h>

bool pt1210_gfx_open_screen();
void pt1210_gfx_close_screen();
bool pt1210_gfx_install_vblank_server();
void pt1210_gfx_remove_vblank_server();
void pt1210_gfx_enable_vblank_server(bool enabled);

#endif /* GRAPHICS_H */
