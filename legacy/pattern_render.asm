
***********************************
** Shitty pattern draw
***********************************

PT_FontWidth	= 64
PT_FontHeight	= 5
PT_VPos		= 100
PT_HPos		= 0	; byte!
PT_LineHeight	= 7
PT_Offset	= 10

PT_Prep		lea	PT_BaseLine,a0
		lea	_basepattern,a1
		
.nextline	moveq	#0,d7
		bsr	ST_Type

		lea	_basepattern,a0
		lea	_pattern1,a1
		lea	_pattern2,a2
		
		lea	$dff000,a6
		WAITBLIT
		move.l	#_basepattern,bltapt(a6)
		move.l	#_pattern1,bltdpt(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#$09f0,bltcon0(a6)
		move.w	#$0000,bltcon1(a6)
		move.w	#0,bltamod(a6)
		move.w	#0,bltdmod(a6)
		move.w	#7<<6+20,bltsize(a6)
		WAITBLIT
		move.l	#_pattern1,bltapt(a6)
		move.l	#_pattern1+(7*40),bltdpt(a6)
		move.w	#7*63<<6+20,bltsize(a6)
		WAITBLIT
		move.l	#_basepattern,bltapt(a6)
		move.l	#_pattern2,bltdpt(a6)
		move.w	#7<<6+20,bltsize(a6)
		WAITBLIT
		move.l	#_pattern2,bltapt(a6)
		move.l	#_pattern2+(7*40),bltdpt(a6)
		move.w	#7*63<<6+20,bltsize(a6)

		rts
		
PT_CharLoop	;moveq	#PT_FontHeight-1,d6
		move.l	a0,a2
		move.l	a1,a3
.charloop	move.b	(a2),(a3)
		lea	PT_FontWidth(a2),a2
		lea	16(a3),a3
		move.b	(a2),(a3)
		lea	PT_FontWidth(a2),a2
		lea	16(a3),a3
		move.b	(a2),(a3)
		lea	PT_FontWidth(a2),a2
		lea	16(a3),a3
		move.b	(a2),(a3)
		lea	PT_FontWidth(a2),a2
		lea	16(a3),a3
		move.b	(a2),(a3)
		lea	PT_FontWidth(a2),a2
		lea	16(a3),a3
		;dbra	d6,.charloop
		addq.l	#1,a0
		addq.l	#1,a1
		dbra	d7,PT_CharLoop		
		rts


PT_DrawPat2	

		tst.l	mt_SongDataPtr
		beq	.quit
		move.l	mt_SongDataPtr,a0
		lea	952(a0),a1		; pat pos
		lea	1084(a0),a0		; pat dat
		moveq	#0,d0
		moveq	#0,d1
		move.b	mt_SongPos,d0
		move.b	(a1,d0.w),d1		; current pattern
		cmp.b	PT_PrevPat(pc),d1
		beq	.quit
		move.b	d1,PT_PrevPat
		lsl.l	#8,d1
		lsl.l	#2,d1
		add.l	d1,a0

		lea	PT_PlanePtr(pc),a1
		move.l	4(a1),d0
		move.l	(a1),d1		
		move.l	d0,(a1)
		move.l	d1,4(a1)
		
		lea	$dff000,a6
		WAITBLIT
		move.l	#_basepattern,bltapt(a6)
		move.l	d1,bltdpt(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#$09f0,bltcon0(a6)
		move.w	#$0000,bltcon1(a6)
		move.w	#0,bltamod(a6)
		move.w	#0,bltdmod(a6)
		move.w	#0,bltamod(a6)
		move.w	#7<<6+20,bltsize(a6)
		WAITBLIT
		move.l	d1,bltapt(a6)
		move.w	#7*63<<6+20,bltsize(a6)
		
		move.l	d0,a6
		
		
		;lea	_basepattern,a6		; plane!!
		lea	_font_small,a5			; font source

		moveq	#64-1,d4
.lineloop

		moveq	#4-1,d7
		; channel
.chanloop	move.l	(a0)+,d0
		move.l	d0,d1
		swap	d1
		and.w	#$fff,d1		; d1 = note
		beq.b	.skipnote
		
		move.w	#36-1,d6	;note loop
		lea	PT_Notes,a1	; pt notes
.notefind	cmp.w	(a1)+,d1
		beq.b	.gotnote
		lea	4(a1),a1
		dbra	d6,.notefind		
		bra	.skipnote
		
.gotnote					; note text in A1
		lea	1(a6),a4
;		move.l	a6,a4			; a4 plane space

		moveq	#3-1,d5			; 3 chars per note
.nextlet	moveq	#0,d1
		move.b	(a1)+,d1
		sub.w	#$20,d1			
		lea	(a5,d1.w),a3		; a3 now at font..
		move.l	a4,a2
		;moveq	#PT_FontHeight-1,d6
.charloop	move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		;dbra	d6,.charloop
		lea	1(a4),a4		
		dbra	d5,.nextlet

.skipnote	; do effects
		swap	d0
		and.w	#$f000,d0
		beq.b	.skiprot
		rol.w	#4,d0

.skiprot	swap	d0
		tst.l	d0
		beq.b	.skipfx
		
		moveq	#5-1,d6		; 5 letters
		lea	PT_HexList,a1
		lea	8(a6),a4	; plane data
		
.fxloop		moveq	#0,d2		; char..
		moveq	#0,d1		
		move.b	d0,d1
		and.b	#$f,d1		; current value
		beq.b	.skipzero
		
		move.b	(a1,d1.w),d2	; char value
		sub.w	#$20,d2
		lea	(a5,d2.w),a3
		;moveq	#PT_FontHeight-1,d3
		move.l	a4,a2
.hexcharloop	move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		move.b	(a3),(a2)
		lea	PT_FontWidth(a3),a3
		lea	40(a2),a2
		;dbra	d3,.hexcharloop
.skipzero	ror.l	#4,d0
		tst.w	d0
		beq.b	.skipfx
		lea	-1(a4),a4		
		dbra	d6,.fxloop
		
.skipfx		lea	10(a6),a6	; next 8 chars
		dbra	d7,.chanloop


		lea	(PT_LineHeight-1)*40(a6),a6
		dbra	d4,.lineloop
		
.quit		rts
				


PT_PatPos2	;move.l	#_dir,d0		; load plane to copper
		move.l	PT_PlanePtr(pc),d0
		sub.l	#40*PT_LineHeight*PT_Offset,d0
		moveq	#0,d1
		move.w	mt_PatternPos,d1
		lsr.w	#4,d1
		mulu	#40*PT_LineHeight,d1
		add.l	d1,d0
		lea	_cpat,a0		
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)

		rts

PT_PlanePtr	dc.l	_pattern1
		dc.l	_pattern2

PT_HexList	dc.b	"0123456789ABCDEF"		
		even
		
PT_Notes	
	dc.w 113
	dc.b "B-3 "
	dc.w 120
	dc.b "A#3 "
	dc.w 127
	dc.b "A-3 "
	dc.w 135
	dc.b "G#3 "
	dc.w 143
	dc.b "G-3 "
	dc.w 151
	dc.b "F#3 "
	dc.w 160
	dc.b "F-3 "
	dc.w 170
	dc.b "E-3 "
	dc.w 180
	dc.b "D#3 "
	dc.w 190
	dc.b "D-3 "
	dc.w 202
	dc.b "C#3 "
	dc.w 214
	dc.b "C-3 "
	dc.w 226
	dc.b "B-2 "
	dc.w 240
	dc.b "A#2 "
	dc.w 254
	dc.b "A-2 "
	dc.w 269
	dc.b "G#2 "
	dc.w 285
	dc.b "G-2 "
	dc.w 302
	dc.b "F#2 "
	dc.w 320
	dc.b "F-2 "
	dc.w 339
	dc.b "E-2 "
	dc.w 360
	dc.b "D#2 "
	dc.w 381
	dc.b "D-2 "
	dc.w 404
	dc.b "C#2 "
	dc.w 428
	dc.b "C-2 "
	dc.w 453
	dc.b "B-2 "
	dc.w 480
	dc.b "A#1 "
	dc.w 508
	dc.b "A-1 "
	dc.w 538
	dc.b "G#1 "
	dc.w 570
	dc.b "G-1 "
	dc.w 604
	dc.b "F#1 "
	dc.w 640
	dc.b "F-1 "
	dc.w 678
	dc.b "E-1 "
	dc.w 720
	dc.b "D#1 "
	dc.w 762
	dc.b "D-1 "
	dc.w 808
	dc.b "C#1 "
	dc.w 856
	dc.b "C-1 "

			;0000000000111111111122222222223333333333
			;0123456789012345678901234567890123456789
PT_BaseLine	dc.b	" ---00000  ---00000  ---00000  ---00000 "


PT_PrevPat	dc.b	-1
		even
		

ST_Type		lea	_font_small,a5

.nextline	moveq	#39,d4		; line loop

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
		lea	40(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	40(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	40(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	40(a3),a3
		move.b	(a2),(a3)
		lea	FONTWIDTH(a2),a2
		lea	40(a3),a3

		lea	1(a1),a1
		dbra	d4,.nextchar
		
		lea	(40*6)(a1),a1		; next plane line
		dbra	d7,.nextline
		rts
