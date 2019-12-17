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

#define FS_FONT_HEIGHT	7
#define FS_WIDTH_CHARS	40
#define FS_HEIGHT_CHARS	21
#define FS_TITLE_CHARS	30

/* W x H characters plus 3 rows of padding for the bottom */
#define FS_BITPLANE_SIZE_BYTES (FS_FONT_HEIGHT * FS_WIDTH_CHARS * FS_HEIGHT_CHARS + 3 * FS_WIDTH_CHARS)

/* 2 rows of padding for the top when drawing text */
#define FS_TEXT_OFFSET (2 * FS_WIDTH_CHARS)

/* Draw error messages starting from the 10th row */
#define FS_ERROR_MSG_OFFSET (FS_TEXT_OFFSET + 10 * FS_FONT_HEIGHT * FS_WIDTH_CHARS)

void pt1210_fs_draw_avail_ram();
void pt1210_fs_draw_dir();
void pt1210_fs_draw_error(const char* error_message);
void pt1210_fs_draw_title();
void pt1210_fs_move(int32_t offset);
void pt1210_fs_select();
void pt1210_fs_parent();
void pt1210_fs_set_sort(file_sort_key_t sort_key);
void pt1210_fs_rescan(bool refresh);
size_t pt1210_fs_current_index();
bool pt1210_fs_find_next(char key, size_t* index);
void pt1210_fs_on_disk_change();

#endif /* FILE_SELECTOR_H */
