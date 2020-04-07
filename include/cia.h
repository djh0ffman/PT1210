/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * cia.h
 * CIA timer allocation/release and functionality.
 */

#ifndef CIA_H
#define CIA_H

#include <stdbool.h>
#include <stdint.h>

#define CIA_MIN_BPM			32
#define CIA_MAX_BPM			300
#define CIA_SEED_PAL		1773447
#define CIA_SEED_NTSC		1789773

bool pt1210_cia_allocate_timer();
void pt1210_cia_free_timer();
void pt1210_cia_start_timer();
void pt1210_cia_stop_timer();
void pt1210_cia_set_frames_per_beat(uint8_t frames);
void pt1210_cia_set_bpm(uint8_t bpm);
void pt1210_cia_set_nudge(int8_t nudge);
void pt1210_cia_increment_offset_coarse();
void pt1210_cia_decrement_offset_coarse();
void pt1210_cia_increment_offset_fine();
void pt1210_cia_decrement_offset_fine();
void pt1210_cia_reset_offset();
void pt1210_cia_update_bpm();
void pt1210_cia_reset_bpm();

#endif /* CIA_H */
