***************************************************************************
*
* PT-1210
*
* ProTracker DJ Player
*
* Credits...
*
* Concept - h0ffman & Akira
* Code - h0ffman
* Graphics - Akira
* Bug testing - Akira
* Startup / Restore Code - Stingray
*
***************************************************************************

SW_Splash = 0		; Include splash screen

	section pt1210,code

; Exports for C code (places them in global scope)
	XDEF _MAIN
	XDEF _FS_LoadErrBuff
	XDEF _FS_DrawLoadError
	XDEF _pt1210_gfx_vblank_server_proc

; Imports from C code
	XREF _pt1210_file_gen_list
	XREF _pt1210_file_read
	XREF _pt1210_file_list
	XREF _pt1210_keyboard_enable_processing
	XREF _current_screen
	XREF _quit

	XREF _pt1210_cia_set_bpm
	XREF _pt1210_cia_base_bpm
	XREF _pt1210_cia_offset_bpm
	XREF _pt1210_cia_fine_offset
	XREF _pt1210_cia_nudge_bpm
	XREF _pt1210_cia_adjusted_bpm
	XREF _pt1210_cia_actual_bpm
	XREF _pt1210_cia_frames_per_beat

FONTWIDTH = 64

TIMERSET	= %1100000000001000
TIMERCLR	= %0100000000001000
;		   ab-------cdefg--
;	a: SET/CLR Bit
;	b: Master Bit
;	c: Blitter Int
;	d: Vert Blank Int
;	e: Copper Int
;	f: IO Ports/Timers
;	g: Software Int


***************************************************
*** MACRO DEFINITION				***
***************************************************

WAITBLIT	MACRO
			tst.b	$02(a6)
.\@			btst	#6,$02(a6)
			bne.b	.\@
			ENDM
 
 			; marco for plotting a character
			; 1 = font source (address register)
			; 2 = plane dest (address register)
			; 3 = plane move (constant)
			; 4 = character (data register / byte?)
PT_CharPlot	MACRO 
			lsl.w	#3,\4		
			lea		(\1,\4.w),\1
			move.b	(\1)+,(\2)
			lea		\3(\2),\2
			move.b	(\1)+,(\2)
			lea		\3(\2),\2
			move.b	(\1)+,(\2)
			lea		\3(\2),\2
			move.b	(\1)+,(\2)
			lea		\3(\2),\2
			move.b	(\1)+,(\2)
			ENDM

*******************************************
*** DATA AREA		FAST		***
*******************************************

VBIptr		dc.l	0

*******************************************
*** VERTICAL BLANK (VBI)		***
*******************************************

_pt1210_gfx_vblank_server_proc
	movem.l	d2-d7/a2-a4,-(sp)
	move.l	VBIptr(pc),d0
	beq.b	.noVBI

	move.l	#$dff000,a6					; Re-load copper lists as OS can trash them
	move.l	#_hud_cop,cop1lc(a6)

	tst.l	_current_screen
	bne.b	.dj
	move.l	#_select_cop,cop2lc(a6)
	bra .nodj
.dj
	move.l	#_cCopper,cop2lc(a6)
.nodj

	move.l	d0,a0
	jsr	(a0)
.noVBI
	movem.l	(sp)+,d2-d7/a2-a4
	move.l #$dff000,a0
	moveq #0,d0						; OS-friendly VBlank servers must set the Z flag
	rts								; RTS and not RTE here

************************************
** The mega mod player by h0ffman **
************************************

	include	hardware/custom.i


		ifne	SW_Splash
splashkill	movem.l	d0-a6,-(sp)
		lea	splashgo-8,a1
		move.l	(a1),d0
		clr.l	nope-4
		move.l	ExecBase,a6
		jsr	FreeMem(a6)
		movem.l	(sp)+,d0-a6
		rts

		endc
_MAIN
		ifne	SW_Splash
		jsr	splashgo
		bsr	splashkill
		endc

		moveq	#0,d0
		bsr	_FS_DrawType

		movem.l	d0-a6,-(sp)

		moveq	#0,d5
		bsr	_FS_DrawDir
		bsr	FS_Copper
		bsr	PT_Prep

		bsr	UI_DrawChip

		bsr	ScopeInit
		move.l	#VBInt,VBIptr		; set VB Int pointer

		lea	$dff000,a6		; hw base

		move.l	#_hud,d0		; load plane to copper
		lea	_hud_planes,a0
		moveq	#5-1,d7
.hudloop	move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		add.l	#40,d0
		addq.l	#8,a0
		dbra	d7,.hudloop

		move.l	#_track,d0		; load plane to copper
		lea	_track_planes,a0
		moveq	#3-1,d7
.trackloop	move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		add.l	#40,d0
		addq.l	#8,a0
		dbra	d7,.trackloop

		move.l	#_song_grid,d0		; load plane to copper
		lea	_grid_planes1,a0
		lea	_grid_planes2,a1
		move.w	d0,6(a0)
		move.w	d0,6(a1)
		swap	d0
		move.w	d0,2(a0)
		move.w	d0,2(a1)

		moveq	#3-1,d7
		move.l	#_track_fill,d0		; load plane to copper
		lea	_track_plane,a0
.tloop		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		lea	8(a0),a0
		add.l	#40,d0
		dbra	d7,.tloop

		move.l	#_song_grid_clr,d0		; load plane to copper
		lea	_grid_planes1c,a0
		lea	_grid_planes2c,a1
		lea	_cScopeSpace,a2
		move.w	d0,6(a0)
		move.w	d0,6(a1)
		move.w	d0,6(a2)
		swap	d0
		move.w	d0,2(a0)
		move.w	d0,2(a1)
		move.w	d0,2(a2)


		lea	_hud_sprites,a0
		lea	_spritelist,a1
		moveq	#8-1,d7

.sprloop	move.l	(a1)+,d0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		addq.l	#8,a0
		dbra	d7,.sprloop

		move.l	#_select,d0		; load plane to copper
		lea	_select_planes,a0
		moveq	#2-1,d7
.selectloop	move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		add.l	#40,d0
		addq.l	#8,a0
		dbra	d7,.selectloop

		move.l	#_selectfilla,d0		; load plane to copper
		lea	_filla_planes,a0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)

		move.l	#_dir,d0
		addq.l	#8,a0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)

		move.l	#_selectfillb,d0
		addq.l	#8,a0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)


		move.l	#_song_grid_clr,d0		; load plane to copper
		lea	_cscreen,a0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)


.lp
		tst.b	_pt1210_fs_load_pending
		beq.b	.skipload

		; Disable keyboard processing
		move.l #0,-(sp)
		jsr _pt1210_keyboard_enable_processing
		add #4,sp

		bsr	FS_LoadTune

		; Re-enable keyboard processing
		move.l #1,-(sp)
		jsr _pt1210_keyboard_enable_processing
		add #4,sp
.skipload

		tst.b	_pt1210_fs_rescan_pending
		beq.b	.skipscan

		move.l #0,-(sp)
		jsr _pt1210_keyboard_enable_processing
		add #4,sp

		bsr	FS_Rescan

		move.l #1,-(sp)
		jsr _pt1210_keyboard_enable_processing
		add #4,sp
.skipscan



		tst.b	_quit
		beq.b	.lp

;		btst    #6,$bfe001
;	        bne.s   .lp

		jsr	_mt_end
		bsr	unallocchip

		;bsr	kbrem

	        movem.l	(sp)+,d0-a6
	    	rts

		include memory.asm
		include vblank_int.asm
		include time.asm
		include ui.asm
		include pattern_render.asm
		include file_selector.asm
		include scope.asm
		include player.asm
		include data_fast.asm
		include data_chip.asm
		include splash_screen.asm


