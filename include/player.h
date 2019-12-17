/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * player.h
 * ASM Protracker replayer function/variable declarations.
 */

#ifndef PLAYER_H
#define PLAYER_H

#include "utility.h"

/* ASM player variables */
/* TODO: Rename so the names are more in line with our new C code */
extern bool mt_TuneEnd;
extern bool mt_Enabled;

extern uint8_t mt_PatternLock;
extern uint8_t mt_PatLockStart;
extern uint8_t mt_PatLockEnd;

extern uint8_t* mt_SongDataPtr;
extern uint8_t mt_speed;
extern uint8_t mt_counter;
extern uint8_t mt_SongLen;
extern uint8_t mt_SongPos;
extern uint16_t mt_PatternPos;
extern uint8_t mt_SLSongPos;
extern uint16_t mt_SLPatternPos;
extern uint8_t mt_PatternCue;
extern uint8_t mt_PattDelTime;
extern uint8_t mt_PattDelTime2;

/* ASM player functions */
void mt_init(REG(a0, void* pattern_data),REG(a2, void* sample_data),REG(d7, uint32_t sample_length));
void mt_music();
void mt_retune();
void mt_end();

#endif /* PLAYER_H */
