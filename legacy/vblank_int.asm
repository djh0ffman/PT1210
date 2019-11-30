; ************* VBLANK Int

		; Imports from C code
		XREF _pt1210_keyboard_process_keys
		XREF _pt1210_gameport_process_buttons
		XREF _pt1210_timer_update
		XREF _vblank_enabled

VBInt	tst.b	_vblank_enabled
		beq.b	.quit

		move.w	#0,_pt1210_cia_nudge_bpm

		jsr _pt1210_timer_update
		jsr	_pt1210_keyboard_process_keys
		jsr _pt1210_gameport_process_buttons

		moveq	#0,d0
		move.b	_pt1210_cia_base_bpm,d0
		move.l d0,-(sp)
		jsr	_pt1210_cia_set_bpm
		addq #4,sp

		bsr	UI_TrackPos
		bsr	UI_WarnFlash
		bsr	UI_CueFlash
		bsr	UI_CuePos
		bsr	Scope

		bsr	UI_SpritePos
		bsr	UI_Draw
		bsr	UI_TextBits

		bsr	PT_DrawPat2
		bsr	PT_PatPos2

.quit
		rts
