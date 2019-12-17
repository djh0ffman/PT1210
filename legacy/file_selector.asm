*********************************************
** File Selecta
*********************************************

; Imports from C code
	XREF _pt1210_file_count
	XREF _pt1210_fs_bitplane

; Exports to C code
	XDEF _FS_Reset
	XDEF _selectaline

_FS_Reset	movem.l	d0-a6,-(sp)
			move.b	#125,_pt1210_cia_base_bpm
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

			even
