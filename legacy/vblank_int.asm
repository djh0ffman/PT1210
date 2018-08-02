; ************* VBLANK Int

VBInt	tst.b	VBDisable
		bne.b	.quit

		move.w	#0,NUDGE
		bsr	DOTIME		; timer

		bsr	keyboard
		bsr	setbpm
		bsr	backup

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

