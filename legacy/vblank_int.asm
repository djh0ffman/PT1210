; ************* VBLANK Int


		; Exports for C code (places them in global scope)
		XDEF _pt1210_gfx_vblank_server_proc

		; Imports from C code
		XREF _pt1210_gameport_process_buttons
		XREF _pt1210_gfx_screen_check_active
		XREF _pt1210_keyboard_process_keys
		XREF _pt1210_timer_update
		XREF _vblank_enabled

_pt1210_gfx_vblank_server_proc
		movem.l	d2-d7/a2-a4,-(sp)

		; Is our screen frontmost?
		jsr _pt1210_gfx_screen_check_active
		tst.b d0
		beq.w .quit

		move.l	#$dff000,a6

		; Ensure blitter isn't busy before we mess with the copper
		WAITBLIT

		; Re-load copper lists otherwise we get the OS intuition screen copper list
		move.l	#_hud_cop,cop1lc(a6)

		tst.l	_pt1210_state+gs_screen
		bne.b	.dj
		move.l	#_select_cop,cop2lc(a6)
		bra .nodj
.dj
		move.l	#_cCopper,cop2lc(a6)
.nodj

.noblitter

		tst.b	_vblank_enabled
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
		movem.l	(sp)+,d2-d7/a2-a4
		moveq #0,d0						; OS-friendly VBlank servers must set the Z flag
		rts
