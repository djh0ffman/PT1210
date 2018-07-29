; ************* VBLANK Int
	    	
VBInt		movem.l	d0-a6,-(sp)
		;move.w	#$f00,$dff180
		tst.b	VBDisable
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
		;move.w	#$000,$dff180
.quit		movem.l	(sp)+,d0-a6
		rts


VBDisable	dc.b	0
		even

