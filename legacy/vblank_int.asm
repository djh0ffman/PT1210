; ************* VBLANK Int

		; Imports from C code
		XREF _pt1210_keyboard_process_keys

VBInt	tst.b	VBDisable
		bne.b	.quit

		move.w	#0,_NUDGE
		bsr	DOTIME		; timer

		movem.l a0-d6,-(sp)
		jsr	_pt1210_keyboard_process_keys
		movem.l (sp)+,a0-d6

		moveq	#0,d0
		move.b	_CIABPM,d0
		jsr	CIA_SetBPM

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

VBDisable	dc.b	0
		even