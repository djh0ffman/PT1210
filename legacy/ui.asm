
; ******************************************
; ********* NEW UI CODE
; ******************************************


UI_Width	= 40
UI_Planes	= 5
UI_TotWidth	= UI_Width*UI_Planes

UI_DigiLine	= UI_TotWidth*38

UI_TogStart	= UI_TotWidth*16

UI_RepitchLoc	= UI_TogStart+38


UI_CuePos	moveq	#0,d0
		moveq	#0,d1
		move.b	_mt_PatternCue,d0
		move.b	UI_PatternCue,d1
		cmp.b	d0,d1
		beq.b	.quit
		move.b	d0,UI_PatternCue
		lsl.w	#1,d0
		lea	UI_TrackPosPix,a0
		lea	(a0,d0.w),a0
		move.w	(a0)+,d1
		move.w	(a0)+,d2
		lea	_track_cue,a2
		move.l	a2,a1
		moveq	#10-1,d7
.clrloop	clr.l	(a2)+
		dbra	d7,.clrloop
		moveq	#-1,d5
		bsr.b	UI_PixDraw
.quit		rts

		; d0 = song length patterns
UI_TrackDraw	moveq	#0,d0
		move.b	_mt_SongLen,d0
;		MOVE.L	_mt_SongDataPtr,A0
;		cmp.l	d0,a0
;		beq.b	.quit
;		move.b	950(A0),D0
		moveq	#0,d1
		move.w	d0,d7
		lea	UI_TrackPosPix(pc),a0
.pixloop	move.w	d1,d2
		mulu	#320,d2
		divu.w	d0,d2
		move.w	d2,(a0)+
		addq.w	#1,d1
		cmp.w	d0,d1
		blo.b	.pixloop

		move.w	#320,(a0)+
		lea	UI_TrackPosPix(pc),a0
		lea	_song_grid,a1

		moveq	#10-1,d7
		move.l	a1,a2
.clrloop	clr.l	(a2)+
		dbra	d7,.clrloop

		subq.w	#1,d0
		moveq	#1,d6
.drawloop	move.w	(a0)+,d1
		move.w	d1,d2
		not.b	d2
		lsr.w	#3,d1
		bset	d2,(a1,d1.w)
		dbra	d0,.drawloop
.quit		rts


		; a1 = screen
		; d1 = start pix
		; d2 = end pix
		; d5 = clear? 0 = clear
UI_PixDraw	cmp.w	d2,d3
		beq.b	.quit
		move.w	d2,d3
		sub	d1,d3
		tst.b	d3
		beq.b	.quit
		subq.w	#1,d3

.pixloop	move.w	d1,d4	; current pixel

		lsr.w	#3,d4
		move.w	d1,d5
		not.b	d5
		tst.b	d6
		beq.b	.clr
		bset	d5,(a1,d4.w)
		bra.b	.next
.clr		bclr	d5,(a1,d4.w)
.next		addq.w	#1,d1
		dbra	d3,.pixloop

.quit		rts



UI_TrackPos	lea	_track_pos,a1
		moveq	#0,d0
		MOVE.L	_mt_SongDataPtr,A0
		cmp.l	d0,a0
		beq.b	.quit
		move.b	950(A0),D0	; max patterns

		moveq	#0,d1
		move.b	_mt_SongPos,d1	; current pattern

		moveq	#0,d2
		move.w	_mt_PatternPos,d2

		lsr.w	#7,d2

		lsl.w	#3,d0
		lsl.w	#3,d1
		or.w	d2,d1

		mulu	#320,d1
		divu	d0,d1

		cmp.w	#280,d1
		blo.b	.flash
		clr.b	UI_WarnEnable
		bra.b	.gogo
.flash		move.b	#1,UI_WarnEnable

.gogo		moveq	#40-1,d7
		moveq	#-1,d6
		move.w	d1,d2
		lsr.w	#3,d1
		lea	(a1,d1.w),a2


.fillloop	tst.b	d1
		beq.b	.clearpix
		move.b	d6,(a1)+
		subq.b	#1,d1
		subq.b	#1,d7
		bra.b	.fillloop
.clearpix	clr.b	(a1)+
		dbra	d7,.clearpix

		not.b	d2
		and.b	#$7,d2
.pixloop	bset	d2,(a2)
		addq.b	#1,d2
		cmp.b	#8,d2
		bne.b	.pixloop

.quit		rts


UI_WarnFlash	lea	_track_flash,a0
		lea	UI_WarnCol,a1
		tst.b	UI_WarnEnable
		beq.b	.doflash
		move.w	(a1),2(a0)
		move.w	2(a1),6(a0)
		clr.b	UI_WarnCount
		rts

.doflash	move.b	UI_WarnCount,d0
		cmp.b	#10,d0
		blo.b	.goflash
		cmp.b	#20,d0
		blo.b	.gogreen
		moveq	#0,d0

.gogreen	lea	4(a1),a1

.goflash	move.w	(a1),2(a0)
		move.w	2(a1),6(a0)
		addq.b	#1,d0
		move.b	d0,UI_WarnCount
		rts

UI_WarnCount	dc.b	0
UI_WarnEnable	dc.b	0

UI_WarnCol	dc.w	$1fc,$1fc
		dc.w	$f00,$f00


UI_CueFlash	lea	_cue_flash,a0
		lea	UI_CueCol,a1
		tst.b	_pattern_slip_pending
		bne.b	.doflash
		clr.b	UI_CueCount
		move.w	(a1),2(a0)
		move.w	2(a1),6(a0)
		move.w	4(a1),10(a0)
		move.w	6(a1),14(a0)
		clr.b	UI_CueCount
		rts

.doflash	move.b	UI_CueCount,d0
		cmp.b	#10,d0
		blo.b	.gogreen
		cmp.b	#20,d0
		blo.b	.goflash
		moveq	#0,d0

.gogreen	lea	8(a1),a1

.goflash	move.w	(a1),2(a0)
		move.w	2(a1),6(a0)
		move.w	4(a1),10(a0)
		move.w	6(a1),14(a0)
		addq.b	#1,d0
		move.b	d0,UI_CueCount
		rts

UI_CueCount	dc.b	0
UI_CueEnable	dc.b	0

UI_CueCol	dc.w	$811,$811,$f11,$f11
		dc.w	$181,$181,$1f1,$1f1




UI_TrackPosPix	dcb.w	129,0




UI_TextBits	movem.l	d0-a6,-(sp)
		lea	_hud,a6		; screen pointer

UI_BPMFine	lea	_pt1210_cia_fine_offset,a3
		lea	UI_BPMFINE,a4
		moveq	#0,d0
		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)


		move.w	_pt1210_cia_actual_bpm,d0
		lsl.w	#4,d0

		move.w	_pt1210_cia_frames_per_beat,d1
		beq.b	.noframe
		mulu	#24,d0
		divu	d1,d0

.noframe	and.w	#$ff,d0
		mulu.w	#100,d0
		divu.w	#256,d0
		and.l	#$ff,d0
		move.w	#(UI_TotWidth*46)+38,d5	; screen pos
		moveq	#2-1,d6			; num chars
		bsr	UI_Decimal
		bsr	UI_DigiType

.skip

UI_BPMDiff	
		lea	UI_BPMCent,a0
		move.b	#"+",(a0)
		lea	_pt1210_cia_actual_bpm,a3
		lea	UI_ActualBPM,a4
		moveq	#0,d0
		move.w	(a3),d0
		cmp.w	(a4),d0
		beq.b	.skip
		move.w	d0,(a4)

 		moveq	#0,d1
		move.b	_pt1210_cia_base_bpm,d1
		lsl.w	#4,d1

		tst.w	d0
		beq.b	.skip
		tst.w	d1
		beq.b	.skip

		sub.w	d1,d0
		muls.w	#100,d0
		divs.w	d1,d0

		cmp.w	#0,d0
		bge.b	.pos
		not.w	d0
		move.b	#"-",(a0)
.pos	and.l	#$ff,d0

		move.w	#(UI_TotWidth*32)+37,d5	; screen pos
		moveq	#3-1,d6			; num chars
		bsr	UI_Decimal
		bsr	UI_ValType

		lea	UI_BPMCent,a0
		move.w	#(UI_TotWidth*32)+34,d5	; screen pos
		moveq	#0,d4
		bsr	UI_TypeSmall

.skip


UI_TrackBPM	lea	_pt1210_cia_base_bpm,a3
		lea	UI_BPM,a4
		moveq	#0,d0
		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)
		move.w	#(UI_TotWidth*32)+33,d5	; screen pos
		moveq	#3-1,d6			; num chars
		bsr	UI_Decimal
		bsr	UI_ValType
.skip

UI_SpeedText	lea	_mt_speed,a3
		lea	UI_Speed,a4
		moveq	#0,d0
		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)
		move.w	#(UI_TotWidth*48)+1,d5	; screen pos
		moveq	#2-1,d6			; num chars
		bsr	UI_Decimal
		bsr	UI_ValType
.skip


UI_SlipText1	lea	_mt_SLSongPos,a3
		lea	UI_SLSongPos,a4
		moveq	#0,d0
		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)
		move.w	#(UI_TotWidth*32)+19,d5	; screen pos
		moveq	#3-1,d6			; num chars
		bsr	UI_Decimal
		bsr	UI_ValType
.skip

UI_SlipText2	lea	_mt_SLPatternPos,a3
		lea	UI_SLPatternPos,a4
		moveq	#0,d0
		move.w	(a3),d0
		cmp.w	(a4),d0
		beq.b	.skip
		move.w	d0,(a4)
		lsr.w	#4,d0
		move.w	#(UI_TotWidth*32)+25,d5	; screen pos
		moveq	#2-1,d6			; num chars
		bsr	UI_Decimal
		bsr	UI_ValType
.skip

		movem.l	(sp)+,d0-a6
		rts


		; d6 = num chars
		; d1 = value
		; a0 = screen to write too
UI_DigiType	lea	(a6,d5.w),a0
		lea	PT_HexList,a4
		lea	_font_digi2,a5
.valueloop	move.l	a0,a3
		moveq	#0,d2
		move.b	d1,d2
		and.b	#$f,d2
		lea	(a5,d2.w),a2		; font point
.charloop	move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	10(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),40(a3)
		lea	-1(a0),a0
		ror.w	#4,d1
		dbra	d6,.valueloop
		rts



		; d6 = num chars
		; d1 = value
		; a0 = screen to write too
UI_ValType	lea	(a6,d5.w),a0
			lea	PT_HexList,a4
			lea	_font_small,a5
.valueloop	move.l	a0,a3
			moveq	#0,d2
			move.b	d1,d2
			and.b	#$f,d2
			move.b	(a4,d2.w),d2
			move.l	a5,a2
			PT_CharPlot_TwoPlanes 	a2,a3,UI_TotWidth,d2
			subq.l	#1,a0
			ror.w	#4,d1
			dbra	d6,.valueloop
			rts

UI_SpritePos
		movem.l	d0-a6,-(sp)
		lea	UI_TrackPosPix(pc),a1
		moveq	#0,d0

		moveq	#0,d6
		move.b	_mt_PatternLock,d6

		moveq	#0,d1
		lea	_spritelefttop,a0
		lea	_spriteleftbot,a2
		move.b	_mt_PatLockStart,d1
		cmp.b	#0,d6
		bgt.b	.skipfirst
		move.b	#0,1(a0)
		move.b	#0,1(a2)
		bra.b	.next
.skipfirst	lsl.w	#1,d1
		move.w	(a1,d1.w),d1
		add.w	#$80,d1
		move.w	d1,d2
		and.b	#1,d2
		lsr.w	#1,d1
		move.b	d1,1(a0)
		move.b	d2,3(a0)
		move.b	d1,1(a2)
		move.b	d2,3(a2)

.next		moveq	#0,d1
		lea	_spriterighttop,a0
		lea	_spriterightbot,a2
		move.b	_mt_PatLockEnd,d1
		cmp.b	#1,d6
		bgt.b	.skipend
		move.b	#0,1(a0)
		move.b	#0,1(a2)
		bra	.nextend
.skipend	addq.b	#1,d1
		lsl.w	#1,d1
		move.w	(a1,d1.w),d1
		cmp.w	#320,d1
		bne.b	.notend
		subq.w	#1,d1
.notend		add.w	#$80-15,d1
		move.w	d1,d2
		and.b	#1,d2
		lsr.w	#1,d1
		move.b	d1,1(a0)
		move.b	d2,3(a0)
		move.b	d1,1(a2)
		move.b	d2,3(a2)

.nextend	movem.l	(sp)+,d0-a6
		rts

UI_PosBoundry	lsl.w	#1,d1
		move.w	(a1,d1.w),d1
		add.w	#$80,d1
		move.w	d1,d2
		and.b	#1,d2
		lsr.w	#1,d1
		move.b	d1,1(a0)
		move.b	d2,3(a0)
		rts
			;00000000011111111112
			;12345678901234567890
howmuch		dc.b	"CHIP RAM:           "

UI_DrawChip	movem.l	d0-a6,-(sp)
		bsr	freechip
		divu	#1024,d0
		and.l	#$ffff,d0
		moveq	#8-1,d6
		bsr	UI_Decimal

		moveq	#8-1,d7
		moveq	#0,d6
.kbloop		move.l	d1,d2
		and.l	#$f0000000,d2
		tst.l	d2
		bne.b	.gotit
		lsl.l	#4,d1
		dbra	d7,.kbloop
.gotit		lea	howmuch+10(pc),a0

.chloop		moveq	#0,d2
		rol.l	#4,d1
		move.b	d1,d2
		and.b	#$f,d2
		add.b	#$30,d2
		move.b	d2,(a0)+
		dbra	d7,.chloop

		addq.l	#1,a0
		move.b	#"K",(a0)+
		move.b	#"b",(a0)+

		lea	howmuch(pc),a0
		lea	_hud+42,a1
		moveq	#20-1,d4
		bsr	UI_Type

		lea	howmuch(pc),a0
		lea	_hud+2,a1
		lea	22(a1),a4
		moveq	#20-1,d4
		bsr	UI_TypeOR
		movem.l	(sp)+,d0-a6
		rts


UI_DrawTitle	movem.l	d0-a6,-(sp)
		move.l	_mt_SongDataPtr,a0
		lea	_hud+42,a1
		moveq	#20-1,d4
		bsr	UI_Type

		move.l	_mt_SongDataPtr,a0
		lea	_hud+2,a1
		lea	22(a1),a4
		moveq	#20-1,d4
		bsr	UI_TypeOR
		movem.l	(sp)+,d0-a6
		rts


UI_BPMCent	dc.b	"+%"
		even


		; A0 = TEXT
		; A1 = SCREEN
		; A5 = FONT
		; D7 = Num Lines
		; D4 = Number of Chars
UI_TypeSmall	
			lea		(a6,d5.w),a1
			lea		_font_small,a5

.nextchar	moveq	#0,d0
			move.b	(a0)+,d0
			move.l	a1,a3
			PT_CharPlot a2,a3,UI_TotWidth,d0
			move.l	a5,a3
			addq.l	#1,a1
			dbra	d4,.nextchar

			rts



		; A0 = TEXT
		; A1 = SCREEN
		; A5 = FONT
		; D7 = Num Lines
		; D4 = Number of Chars
UI_Type		lea	_font_big,a5
.nextchar	moveq	#0,d0

		move.b	(a0)+,d0
		cmp.b	#$60,d0
		ble.b	.upper
		sub.b	#$20,d0
.upper		tst.b	d0
		bne.b	.notnull
		moveq	#$20,d0
.notnull	sub.b	#$20,d0
		lea	(a5),a2
		add.l	d0,a2

		lea	(a1),a3

.charloop	move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3

		lea	1(a1),a1
		dbra	d4,.nextchar
		rts

UI_TypeOR	lea	_font_big,a5

.nextchar	moveq	#0,d0

		move.b	(a0)+,d0
		cmp.b	#$60,d0
		ble.b	.upper
		sub.b	#$20,d0
.upper		tst.b	d0
		bne.b	.notnull
		moveq	#$20,d0
.notnull	sub.b	#$20,d0
		lea	(a5),a2
		add.l	d0,a2

		lea	(a1),a3

		move.l	a4,-(sp)
.charloop	move.b	(a2),d0
		or.b	(a4),d0
		move.b	d0,(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a4),a4
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),d0
		or.b	(a4),d0
		move.b	d0,(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a4),a4
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),d0
		or.b	(a4),d0
		move.b	d0,(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a4),a4
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),d0
		or.b	(a4),d0
		move.b	d0,(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a4),a4
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),d0
		or.b	(a4),d0
		move.b	d0,(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a4),a4
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),d0
		or.b	(a4),d0
		move.b	d0,(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a4),a4
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),d0
		or.b	(a4),d0
		move.b	d0,(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a4),a4
		lea	(UI_TotWidth)(a3),a3
		move.l	(sp)+,a4

		lea	1(a1),a1
		dbra	d4,.nextchar
		rts

UI_Draw		movem.l	d0-a6,-(sp)

UI_ALL		lea	$dff000,a6

		lea	_hud+UI_TogStart,a0		; a0 = dest source

		lea	_hud_on,a1	; hudon
		lea	_hud_off,a2	; hudoff

		; REPITCH
UI_RPDraw	moveq	#0,d0
		move.w	#38,d5		; pos onscreen
		move.w	#20,d6			; pos in lights
		lea	_repitch_enabled,a3
		lea	UI_Repitch,a4
		bsr	UI_CompBlit

		; LineLoop on off
UI_LPDraw	moveq	#0,d0
		move.w	#4,d5			; pos onscreen
		move.w	#0,d6			; pos in lights
		lea	_loop_active,a3
		lea	UI_LoopActive,a4
		bsr	UI_CompBlit

		; slip
UI_SlipDraw	moveq	#0,d0
		move.w	#22,d5			; pos onscreen
		move.w	#14,d6			; pos in lights
		lea	_slip_on,a3
		tst.b	(a3)
		beq.b	.skip

		tst.b	_loop_active
		bne.b	.skip

		move.b	_mt_SongPos,_mt_SLSongPos
		move.w	_mt_PatternPos,_mt_SLPatternPos

.skip		lea	UI_SlipOn,a4
		bsr	UI_CompBlit


		; slip
UI_PatLockDraw	moveq	#0,d0
		move.w	#28,d5			; pos onscreen
		move.w	#16,d6			; pos in lights
		lea	_mt_PatternLock,a3
		lea	UI_PatternLock,a4

		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)

		cmp.b	#0,d0
		beq.b	.alloff
		cmp.b	#1,d0
		beq.b	.firston

		move.l	a1,a3		; else both on
		bsr	UI_BlitTog
		addq.w	#2,d5
		addq.w	#2,d6
		move.l	a1,a3
		bsr	UI_BlitTog
		bra	.skip

.alloff		move.l	a2,a3
		bsr	UI_BlitTog
		move.l	a2,a3
		addq.w	#2,d5
		addq.w	#2,d6
		bsr	UI_BlitTog
		bra	.skip

.firston	move.l	a1,a3
		bsr	UI_BlitTog
		move.l	a2,a3
		addq.w	#2,d5
		addq.w	#2,d6
		bsr	UI_BlitTog
.skip

UI_LoopSizeDraw	moveq	#0,d0
		move.w	#6,d5			; pos onscreen
		move.w	#2,d6			; pos in lights
		lea	_loop_size,a3
		lea	UI_LoopSize,a4

		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)

		move.l	a2,a3
		bsr	UI_LoopClr

		move.l	a1,a3		; now light on
		moveq	#5,d7
.loop		lsr.b	#1,d0
		tst.b	d0
		beq.b	.gotit
		addq.b	#2,d6
		addq.b	#2,d5
		dbra	d7,.loop

.gotit		bsr	UI_BlitTog
.skip

		; ***********************************
		; channel toggels


UI_ChanDraw	lea	_track,a0
		lea	_trackon,a1
		lea	_trackoff,a2

		lea	_channel_toggle,a3
		lea	UI_ChanTogs,a4
		move.w	(a3),d0
		cmp.w	(a4),d0
		beq.b	.skip
		move.w	d0,(a4)

		move	#3,d7		; loop 4 chans
		move.w	#0,d5			; pos onscreen
.chanloop	btst	#0,d0
		beq.b	.chanoff
		move.l	a1,a3
		bra.b	.go
.chanoff	move.l	a2,a3
.go		move.w	d5,d6
		bsr	UI_ChanBlit
		add.b	#10,d5
		lsr.w	#1,d0
		dbra	d7,.chanloop
.skip

		; ***********************************
		; DIGI!  EEERMM..

		lea	_hud+UI_DigiLine+40,a0
		lea	_font_digi,a1


UI_BPMDrawDigi	lea	_pt1210_cia_adjusted_bpm,a3
		lea	UI_CurBPM,a4
		move.w	(a3),d0
		cmp.w	(a4),d0
		beq.b	.skip
		move.w	d0,(a4)

		move.w	_pt1210_cia_frames_per_beat,d1
		beq.b	.skipframe

		move.w	_pt1210_cia_actual_bpm,d0
		muls	#24,d0
		divs	d1,d0
		swap	d0
		clr.w	d0
		swap	d0
		lsr.w	#4,d0


.skipframe	bsr	UI_Decimal
		move.w	d1,d0

		moveq	#3-1,d7
		moveq	#34,d5		; digi pos
		bsr	UI_DigiBlit
.skip


UI_SecDraw	lea	_Time_Seconds,a3
		lea	UI_Seconds,a4
		moveq	#0,d0
		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)

		bsr	UI_Decimal
		move.w	d1,d0

		moveq	#2-1,d7
		moveq	#10,d5		; digi pos
		bsr	UI_DigiBlit
.skip

UI_MinDraw	lea	_Time_Minutes,a3
		lea	UI_Minutes,a4
		moveq	#0,d0
		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)

		bsr	UI_Decimal
		move.w	d1,d0

		moveq	#2-1,d7
		moveq	#4,d5		; digi pos
		bsr	UI_DigiBlit
.skip


UI_PatPosDraw	lea	_mt_PatternPos,a3
		lea	UI_PatternPos,a4
		moveq	#0,d0
		move.w	(a3),d0
		cmp.w	(a4),d0
		beq.b	.skip
		move.w	d0,(a4)

		lsr.w	#4,d0

		bsr	UI_Decimal
		move.w	d1,d0

		moveq	#2-1,d7
		moveq	#24,d5		; digi pos
		bsr	UI_DigiBlit
.skip

UI_SongPosDraw	lea	_mt_SongPos,a3
		lea	UI_SongPos,a4
		moveq	#0,d0
		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)

		bsr	UI_Decimal
		move.w	d1,d0

		moveq	#3-1,d7
		moveq	#18,d5		; digi pos
		bsr	UI_DigiBlit


.skip


		movem.l	(sp)+,d0-a6
		rts

		;a0 = hud
		;a1 = font
		;d0 = value
		;d7 = number of digits

UI_DigiBlit	moveq	#0,d6
.loop		move.b	d0,d6
		and.b	#$f,d6
		lsl.b	#1,d6		; double it!!
		lea	(a1,d6.w),a3	; new source
		lea	(a0,d5.w),a4

		WAITBLIT
		move.l	a3,bltapt(a6)
		move.l	a4,bltdpt(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#$09f0,bltcon0(a6)
		move.w	#$0000,bltcon1(a6)
		move.w	#32-2,bltamod(a6)
		move.w	#(40*5)-2,bltdmod(a6)
		move.w	#(24)<<6+1,bltsize(a6)

		lsr.w	#4,d0
		subq.w	#2,d5
		dbra	d7,.loop
		rts

UI_ChanBlit	WAITBLIT
		lea	(a3,d6.w),a3
		lea	(a0,d5.w),a4
		move.l	a3,bltapt(a6)
		move.l	a4,bltdpt(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#$09f0,bltcon0(a6)
		move.w	#$0000,bltcon1(a6)
		move.w	#40-10,bltamod(a6)
		move.w	#40-10,bltdmod(a6)
		move.w	#(9*3)<<6+5,bltsize(a6)
		rts

UI_CompBlit	move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)
		tst.b	d0
		bne.b	.off
		move.l	a2,a3
		bra	.go
.off		move.l	a1,a3
.go		bsr	UI_BlitTog
.skip		rts


UI_LoopClr	WAITBLIT
		lea	(a3,d6.w),a3
		lea	(a0,d5.w),a4
		move.l	a3,bltapt(a6)
		move.l	a4,bltdpt(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#$09f0,bltcon0(a6)
		move.w	#$0000,bltcon1(a6)
		move.w	#22-12,bltamod(a6)
		move.w	#40-12,bltdmod(a6)
		move.w	#(16*5)<<6+6,bltsize(a6)
		rts


UI_BlitTog	WAITBLIT
		lea	(a3,d6.w),a3
		lea	(a0,d5.w),a4
		move.l	a3,bltapt(a6)
		move.l	a4,bltdpt(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#$09f0,bltcon0(a6)
		move.w	#$0000,bltcon1(a6)
		move.w	#20,bltamod(a6)
		move.w	#40-2,bltdmod(a6)
		move.w	#(16*5)<<6+1,bltsize(a6)
		rts

UI_Decimal	moveq	#3,d7
		moveq	#0,d1
.loop		divu.w	#10,d0
		swap	d0
		or.b	d0,d1
		clr.w	d0
		swap	d0
		ror.w	#4,d1
		dbra	d7,.loop
		rts


; vars

UI_ActualBPM	dc.w	-1
UI_PatternPos	dc.w	-1
UI_CurBPM	dc.w	-1
UI_ChanTogs	dc.w	-1
UI_SLPatternPos	dc.w	-1
UI_Repitch	dc.b	-1
UI_LoopActive	dc.b	-1
UI_SlipOn	dc.b	-1
UI_PatternLock	dc.b	-1
UI_LoopSize	dc.b	-1
UI_Seconds	dc.b	-1
UI_Minutes	dc.b	-1
UI_SongPos	dc.b	-1
UI_BPM		dc.b	-1
UI_Speed	dc.b	-1
UI_SLSongPos	dc.b	-1
UI_PatternCue	dc.b	-1
UI_BPMFINE	dc.b	-1
		even
