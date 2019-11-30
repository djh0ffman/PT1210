/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * cia.c
 * CIA timer allocation/release and functionality.
 */

#include <stdio.h>

#include <clib/cia_protos.h>
#include <clib/debug_protos.h>
#include <hardware/cia.h>
#include <proto/exec.h>
#include <resources/cia.h>

#include "cia.h"
#include "utility.h"
#include "state.h"

extern struct CIA ciab;

static struct Library* ciab_resource = NULL;
static struct Interrupt timer_int = { 0 };

/* Flag to say whether we have successfully allocated a timer */
static bool timer_allocated = false;

/* Bitmasks and register pointers which vary depending on which timer we allocate */
static uint32_t timer_bit = 0;
static uint8_t timer_start_mask = 0;
static uint8_t timer_stop_mask = 0;
static volatile uint8_t* timer_control_reg = NULL;
static volatile uint8_t* timer_low_reg = NULL;
static volatile uint8_t* timer_high_reg = NULL;

/* The values to put into the high/low CIA timer registers */
static uint16_t timer_value = 0;
static uint16_t timer_prev_value = 0;	/* Previous value; allows CIA interrupt to detect change */

/* For BPM calculations */
uint8_t pt1210_cia_base_bpm;			/* The base BPM as set by the module */
int16_t pt1210_cia_offset_bpm;			/* Signed coarse offset applied using coarse pitch controls */
uint8_t pt1210_cia_fine_offset;			/* Fine offset applied using fine pitch controls */
int16_t pt1210_cia_nudge_bpm;			/* Nudge offset applied using nudge controls */
uint16_t pt1210_cia_adjusted_bpm;		/* The BPM with coarse adjustments applied */
uint16_t pt1210_cia_actual_bpm;			/* The final BPM value used to set timer high/low registers, with fine adjustments applied */
uint16_t pt1210_cia_display_bpm;		/* resulting display BPM after frames per beat adjustment */
uint16_t pt1210_cia_track_display_bpm;	/* resulting display BPM after frames per beat adjustment */

uint16_t pt1210_cia_frames_per_beat;	/* The frames-per-beat value as set from parsing a magic sample names */

/* ASM player variables */
extern bool mt_TuneEnd;
extern bool mt_Enabled;

/* ASM player functions */
void mt_music();
void mt_retune();
void mt_end();

/* Called by the CIA timer interrupt */
void pt1210_cia_interrupt_proc()
{
	/* Only write CIA registers if we need to, otherwise we reset the timer manually and introduce drift */
	if (timer_value != timer_prev_value)
	{
#ifdef DEBUG
		kprintf("Writing CIA registers (%ld -> %ld)\n", timer_prev_value, timer_value);
#endif
		timer_prev_value = timer_value;
		*timer_low_reg = timer_value & 0xFF;
		*timer_high_reg = (timer_value >> 8) & 0xFF;
	}

	if (!mt_Enabled)
		return;

	if (mt_TuneEnd)
	{
		mt_end();
		mt_Enabled = false;
		return;
	}

	mt_music();

	if (pt1210_state.player.repitch_enabled)
		mt_retune();
}

bool pt1210_cia_allocate_timer()
{
	/* Open the CIA B resource */
	ciab_resource = OpenResource(CIABNAME);
	if (!ciab_resource)
	{
		fprintf(stderr, "Failed to open " CIABNAME "\n");
		return false;
	}

	/* Setup interrupt structure */
	timer_int.is_Node.ln_Type = NT_INTERRUPT;
	timer_int.is_Node.ln_Pri = 0;
	timer_int.is_Node.ln_Name = "PT1210 CIA Interrupt";
	timer_int.is_Data = NULL;
	timer_int.is_Code = pt1210_cia_interrupt_proc;

	/* Try to allocate CIA B timer A */
	if (!AddICRVector(ciab_resource, CIAICRB_TA, &timer_int))
	{
#ifdef DEBUG
		kprintf("Allocated CIA B timer A\n");
#endif
		timer_allocated = true;
		timer_bit = CIAICRB_TA;
		timer_start_mask = CIACRAF_START;
		timer_stop_mask = ~(CIACRAF_START | CIACRAF_RUNMODE | CIACRAF_LOAD | CIACRAF_INMODE);
		timer_control_reg = &ciab.ciacra;
		timer_low_reg = &ciab.ciatalo;
		timer_high_reg = &ciab.ciatahi;
		return true;
	}

	/* Try to allocate CIA B timer B */
	if (!AddICRVector(ciab_resource, CIAICRB_TB, &timer_int))
	{
#ifdef DEBUG
		kprintf("Allocated CIA B timer B\n");
#endif
		timer_allocated = true;
		timer_bit = CIAICRB_TB;
		timer_start_mask = CIACRBF_START;
		timer_stop_mask = ~(CIACRBF_START | CIACRBF_RUNMODE | CIACRBF_LOAD | CIACRBF_INMODE0 | CIACRBF_INMODE1);
		timer_control_reg = &ciab.ciacrb;
		timer_low_reg = &ciab.ciatblo;
		timer_high_reg = &ciab.ciatbhi;
		return true;
	}

	fprintf(stderr, "Failed to allocate a CIA timer\n");
	return false;
}

void pt1210_cia_free_timer()
{
	if (!timer_allocated)
		return;

	RemICRVector(ciab_resource, timer_bit, &timer_int);
	timer_allocated = false;
}

void pt1210_cia_start_timer()
{
	if (!timer_allocated)
		return;

	/* Default to 125 BPM */
	pt1210_cia_set_bpm(125);
	timer_prev_value = timer_value;

	/* Critical section */
	Disable();
	*timer_control_reg &= timer_stop_mask;
	*timer_low_reg = timer_value & 0xFF;
	*timer_high_reg = (timer_value >> 8) & 0xFF;
	*timer_control_reg |= timer_start_mask;
	Enable();
}

void pt1210_cia_stop_timer()
{
	if (!timer_allocated)
		return;

	/* Critical section */
	Disable();
	*timer_control_reg &= timer_stop_mask;
	Enable();
}

void pt1210_cia_set_bpm(uint8_t bpm)
{
	pt1210_cia_base_bpm = bpm;
	pt1210_cia_adjusted_bpm = clamp(bpm + pt1210_cia_offset_bpm + pt1210_cia_nudge_bpm, CIA_MIN_BPM, CIA_MAX_BPM);
	pt1210_cia_actual_bpm = (pt1210_cia_adjusted_bpm << 4) | pt1210_cia_fine_offset;

	/* calculate display bpm values based on frames per beat value */
	if (pt1210_cia_frames_per_beat > 0)
	{
		pt1210_cia_display_bpm = pt1210_cia_actual_bpm * 24 / pt1210_cia_frames_per_beat;
		pt1210_cia_track_display_bpm = (pt1210_cia_base_bpm << 4) * 24 / pt1210_cia_frames_per_beat;
	}
	else
	{
		pt1210_cia_display_bpm = pt1210_cia_actual_bpm;
		pt1210_cia_track_display_bpm = (pt1210_cia_base_bpm << 4);
	}

	/* TODO: NTSC? */
	timer_value = (CIA_SEED_PAL << 4) / pt1210_cia_actual_bpm;
}