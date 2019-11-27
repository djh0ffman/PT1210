*********************************************
** File Selecta
*********************************************

; Imports from C code
	XREF _pt1210_action_switch_screen
	XREF _pt1210_file_count
	XREF _pattern_slip_pending
	XDEF _current
	XREF _list_pos

; Exports to C code
	XDEF _FS_Copper
	XDEF _FS_CopperClr
	XDEF _FS_DrawType
	XDEF _FS_LoadTune
	XDEF _dir

		; d0 = 0 = BPM / 1 = KB

_FS_DrawType
			lea		_bpm,a0
			tst.b	d0
			beq.b	.gobpm
			lea		_kb,a0
.gobpm		lea		_select,a1
			lea		(40*5)-4(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1

			rts

_FS_Copper	cmp.w	#$0,_pt1210_file_count
			bgt.b	.go
			bsr	_FS_CopperClr
			rts

.go			movem.l	d0-a6,-(sp)
			moveq	#0,d0
			move.l	_list_pos,d0
			move.w	#FS_ListMax-1,d7
			lea	_selectaline,a0
.loop		clr.w	6(a0)
			tst.w	d0
			bne.b	.skip
			nop
			move.w	#$00f,6(a0)

.skip		subq.w	#1,d0
			lea	_selectasize(a0),a0
			dbra	d7,.loop
			movem.l	(sp)+,d0-a6
			rts



_FS_CopperClr	movem.l	d0-a6,-(sp)
			moveq	#0,d0
			move.w	#FS_ListMax-1,d7
			lea	_selectaline,a0
.loop		clr.w	6(a0)
			lea	_selectasize(a0),a0
			dbra	d7,.loop
			movem.l	(sp)+,d0-a6
			rts

_FS_LoadTune	movem.l	d0-a6,-(sp)

			clr.b	_mt_Enabled	; stop the current track

			jsr	_mt_end

			clr.b	_vblank_enabled

			jsr	_ScopeStop

			;move.w	#TIMERSET!$C000,$9A(a6)	; set Interrupts+ BIT 14/15

			bsr	unallocchip

			move.l	_current,d0
			mulu	#mi_Sizeof,d0
			lea		_pt1210_file_list,a0
			add.l	d0,a0
			move.l	mi_FileSize(a0),memsize
			move.w	mi_Frames(a0),_pt1210_cia_frames_per_beat
			lea		mi_FileName(a0),a0
			move.l	a0,a6
			tst.l	memsize
			beq		.error
			bsr		allocchip
			tst.l	memptr
			beq.b	.memerror

			move.l	memsize,-(sp)
			move.l	#0,-(sp)
			move.l	memptr,-(sp)
			move.l	a6,-(sp)

			jsr		_pt1210_file_read

			add.l 	#16,sp

			tst.l	d0
			beq.b	.quit

			move.l	memptr,a0
			jsr		mt_init

			bsr		FS_Reset


			jsr		_pt1210_action_switch_screen

			move.b	#1,_mt_Enabled

.quit		;move.w	#TIMERCLR!$C000,$9A(a6)	; set Interrupts+ BIT 14/15
			move.b	#1,_vblank_enabled
			movem.l	(sp)+,d0-a6
			rts

.memerror	bsr	FS_DrawOutRam
			bra.b	.quit

.error		bsr	unallocchip
			jsr	FS_DrawError
			bra	.quit



FS_Reset	move.b	#125,_pt1210_cia_base_bpm
			;clr.w	_pt1210_cia_frames_per_beat
			clr.w	_pt1210_cia_offset_bpm
			clr.b	_pt1210_cia_fine_offset
			move.w	#%0000000000001111,_channel_toggle

			move.b #4,_loop_size
			move.b #0,_loop_active
			move.b #0,_loop_start
			move.b #0,_loop_end

			move.b #0,_pattern_slip_pending
			move.b	#1,_slip_on
			move.b	#1,_repitch_enabled
			clr.b	_mt_TuneEnd
			move.b	#0,_mt_PatternLock
			move.b	#0,_mt_PatLockStart
			move.b	#0,_mt_PatLockEnd
			move.b	#0,_mt_PatternCue
			clr.b	_Time_Frames
			clr.b	_Time_Seconds
			clr.b	_Time_Minutes

			clr.b	_mt_SLSongPos
			clr.w	_mt_SLPatternPos

			move.b	#-1,PT_PrevPat
			bsr	PT_DrawPat2
			bsr	UI_DrawTitle
			jsr	UI_TrackDraw

			move.b	#-1,UI_PatternCue
			move.b	#-1,UI_BPMFINE

			jsr	UI_CuePos

			rts

FS_ListMax	=	21
			even

FS_DrawError
			bsr	_FS_CopperClr
			lea	FS_Error,a0
			lea	_dir+80,a1
			lea	10*7*40(a1),a1
			moveq	#5-1,d7		; number of lines
			bsr	_ST_Type
			rts

FS_DrawOutRam
			bsr	_FS_CopperClr
			lea	FS_OutRam,a0
			lea	_dir+80,a1
			lea	10*7*40(a1),a1
			moveq	#5-1,d7		; number of lines
			bsr	_ST_Type
			rts

		; d0 = load error code
_FS_DrawLoadError
		movem.l	d1-a6,-(sp)
		lea	FS_LoadErrCode+32,a0
		lea	PT_HexList,a1
		moveq	#8-1,d7		; all d0

.code		moveq	#0,d1
		move.b	d0,d1
		and.b	#$f,d1
		move.b	(a1,d1.w),d1
		move.b	d1,-(a0)
		lsr.l	#4,d0
		dbra	d7,.code

		bsr	_FS_CopperClr
		lea	FS_LoadError,a0
		lea	_dir+80,a1
		lea	10*7*40(a1),a1
		moveq	#5-1,d7		; number of lines
		bsr	_ST_Type
		movem.l	(sp)+,d1-a6
		rts

					;0000000000111111111122222222223333333333
					;0123456789012345678901234567890123456789
FS_OutRam	dc.b	"--------------------------------------- "
			dc.b	"                                        "
			dc.b	"           NOT ENOUGH MEMORY            "
			dc.b	"                                        "
			dc.b	"--------------------------------------- "

					;0000000000111111111122222222223333333333
					;0123456789012345678901234567890123456789
FS_LoadError
			dc.b	"--------------------------------------- "
FS_LoadErrCode
			dc.b	"       LOADING ERROR : $00000000        "
_FS_LoadErrBuff
			dc.b	"                                        "
			dc.b	"                                        "
			dc.b	"--------------------------------------- "

FS_Error	dc.b	"--------------------------------------- "
			dc.b	"                                        "
			dc.b	"          UNSPECIFIED ERROR!            "
			dc.b	"                                        "
			dc.b	"--------------------------------------- "
