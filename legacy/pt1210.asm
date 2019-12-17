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

	include	hardware/custom.i
	include state.i

SW_Splash = 0		; Include splash screen

	section pt1210,code

; Exports for C code (places them in global scope)
	XDEF _pt1210_asm_initialize
	XDEF _pt1210_gfx_vblank_server_proc

; Imports from C code
	XREF _pt1210_cia_set_bpm
	XREF _pt1210_cia_base_bpm
	XREF _pt1210_cia_nudge_bpm
	XREF _pt1210_cia_actual_bpm
	XREF _pt1210_cia_display_bpm
	XREF _pt1210_cia_track_display_bpm
	XREF _pt1210_fs_bitplane

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
			move.b	(\1)+,\3(\2)
			move.b	(\1)+,\3*2(\2)
			move.b	(\1)+,\3*3(\2)
			move.b	(\1)+,\3*4(\2)
			ENDM

 			; marco for plotting a character
			; 1 = font source (address register)
			; 2 = plane dest (address register)
			; 3 = plane move (constant)
			; 4 = character (data register / byte?)
PT_CharPlot_TwoPlanes	MACRO
			lsl.w	#3,\4
			lea		(\1,\4.w),\1
			move.b	(\1),(\2)
			move.b	(\1)+,UI_Width(\2)
			move.b	(\1),\3(\2)
			move.b	(\1)+,UI_Width+\3(\2)
			move.b	(\1),\3*2(\2)
			move.b	(\1)+,UI_Width+\3*2(\2)
			move.b	(\1),\3*3(\2)
			move.b	(\1)+,UI_Width+\3*3(\2)
			move.b	(\1),\3*4(\2)
			move.b	(\1)+,UI_Width+\3*4(\2)
			ENDM

************************************
** The mega mod player by h0ffman **
************************************

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

_pt1210_asm_initialize
		movem.l	d0-a6,-(sp)
		ifne	SW_Splash
		jsr	splashgo
		bsr	splashkill
		endc

		moveq	#0,d5
		bsr	PT_Prep

		bsr	ScopeInit

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

		move.l	#_pt1210_fs_bitplane,d0
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

 		movem.l	(sp)+,d0-a6
		rts

		include vblank_int.asm
		include ui.asm
		include pattern_render.asm
		include scope.asm
		include player.asm
		include data_fast.asm
		include data_chip.asm
		include splash_screen.asm
