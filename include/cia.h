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

/* Global variables */
extern uint8_t pt1210_cia_base_bpm;
extern int16_t pt1210_cia_offset_bpm;
extern uint8_t pt1210_cia_fine_offset;
extern int16_t pt1210_cia_nudge_bpm;
extern uint16_t pt1210_cia_display_bpm;
extern uint16_t pt1210_cia_track_display_bpm;
extern uint16_t pt1210_cia_frames_per_beat;

bool pt1210_cia_allocate_timer();
void pt1210_cia_free_timer();
void pt1210_cia_start_timer();
void pt1210_cia_stop_timer();
void pt1210_cia_set_bpm(uint8_t bpm);

#endif /* CIA_H */
