*********************************************
** File Selecta
*********************************************

; Imports from C code
	XREF _pt1210_file_count
	XREF _list_pos

; Exports to C code
	XDEF _FS_Copper
	XDEF _FS_CopperClr
	XDEF _FS_Reset
	XDEF _dir

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
			move.w	#%0000000000001111,_pt1210_state+gs_player+ps_channel_toggle

			move.b #0,_pt1210_state+gs_player+ps_loop_active
			move.b #0,_pt1210_state+gs_player+ps_loop_start
			move.b #0,_pt1210_state+gs_player+ps_loop_end
			move.b #4,_pt1210_state+gs_player+ps_loop_size

			move.b #0,_pt1210_state+gs_player+ps_pattern_slip_pending
			move.b	#1,_pt1210_state+gs_player+ps_slip_on
			move.b	#1,_pt1210_state+gs_player+ps_repitch_enabled
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
			jsr	UI_TrackDraw

			move.b	#-1,UI_PatternCue
			move.b	#-1,UI_BPMFINE

			jsr	UI_CuePos

			movem.l	(sp)+,d0-a6
			rts

FS_ListMax	=	21
			even
