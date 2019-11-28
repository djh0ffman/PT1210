/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * fileselector.h
 * File selector UI.
 */

#ifndef FILE_SELECTOR_H
#define FILE_SELECTOR_H

#include <stdbool.h>
#include <stdint.h>

#include "filesystem.h"

#define FS_WIDTH_CHARS	40
#define FS_HEIGHT_CHARS	21

void pt1210_fs_draw_dir();
void pt1210_fs_move(int32_t offset);
void pt1210_fs_select();
void pt1210_fs_parent();
void pt1210_fs_toggle_show_kb();
void pt1210_fs_set_sort(file_sort_key_t sort_key);
void pt1210_fs_rescan();
size_t pt1210_fs_current_index();
bool pt1210_fs_find_next(char key, size_t* index);
void pt1210_fs_draw_error(const char* error_message);

#endif /* FILE_SELECTOR_H */
