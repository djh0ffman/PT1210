*********************************************
** File Selecta
*********************************************

; Imports from C code
	XREF _pt1210_file_count
	XREF _pattern_slip_pending
	XREF _list_pos

; Exports to C code
	XDEF _FS_Copper
	XDEF _FS_CopperClr
	XDEF _FS_DrawType
	XDEF _FS_LoadTune
	XDEF _FS_Reset
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

_FS_Reset	movem.l	d0-a6,-(sp)
			move.b	#125,_pt1210_cia_base_bpm
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

			movem.l	(sp)+,d0-a6
			rts

FS_ListMax	=	21
			even
