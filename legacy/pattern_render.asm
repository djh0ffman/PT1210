
***********************************
**
** Pattern Draw (double buffered)
**
** by Hoffman
**
** pattern drawing is done by char plotting a template line then duplicating that
** line for the whole pattern. we then only draw the items from the pattern where
** they are popluated.  This means the time it takes to draw a pattern relies on
** the contents.
**
** routine will only draw a pattern if it detects that its changed.
**
** double buffer works by firing off a blit on the previous pattern to re-template it
** while CPU char plotting current pattern
**
***********************************

PT_FontWidth	= 64
PT_FontHeight	= 5			; this is never used but our font is 5 pixels high
PT_VPos			= 100
PT_LineHeight	= 7
PT_Offset		= 10

			; creates the two template patterns
			; needs to be called in the init phase
PT_Prep		lea		PT_BaseLine,a0
			lea		_basepattern,a1

			moveq	#0,d7
			bsr		ST_Type								; char plot the template line

			lea		$dff000,a6
			WAITBLIT
			move.l	#_basepattern,bltapt(a6)
			move.l	#_pattern1,bltdpt(a6)
			move.l	#-1,bltafwm(a6)
			move.w	#$09f0,bltcon0(a6)
			move.w	#$0000,bltcon1(a6)
			move.w	#0,bltamod(a6)
			move.w	#0,bltdmod(a6)
			move.w	#7<<6+20,bltsize(a6)				; copy template line to destination (buffer 1)
			WAITBLIT
			move.l	#_pattern1,bltapt(a6)
			move.l	#_pattern1+(7*40),bltdpt(a6)
			move.w	#7*63<<6+20,bltsize(a6)				; duplicate template line over whole pattern (buffer 1)
			WAITBLIT
			move.l	#_basepattern,bltapt(a6)
			move.l	#_pattern2,bltdpt(a6)
			move.w	#7<<6+20,bltsize(a6)				; copy template line to destination (buffer 2)
			WAITBLIT
			move.l	#_pattern2,bltapt(a6)
			move.l	#_pattern2+(7*40),bltdpt(a6)
			move.w	#7*63<<6+20,bltsize(a6)				; duplicate template line over whole pattern (buffer 2)
			rts

			; draws the pattern
PT_DrawPat2	tst.l	_mt_SongDataPtr					; test song pointer, blank then quit.
			beq		.quit
			move.l	_mt_SongDataPtr,a0
			lea		952(a0),a1						; song positions
			lea		1084(a0),a0						; first pattern
			moveq	#0,d0
			moveq	#0,d1
			move.b	_mt_SongPos,d0					; get current song position
			move.b	(a1,d0.w),d1					; get current pattern
			cmp.b	PT_PrevPat(pc),d1				; compare with current, the same the dont draw
			beq		.quit
			move.b	d1,PT_PrevPat					; store new current pattern
			lsl.l	#8,d1
			lsl.l	#2,d1							; 10 x logical shift = 1024 (one pattern)
			add.l	d1,a0							; move pointer to pattern data

			lea		PT_PlanePtr(pc),a1				; flip the pattern buffers
			move.l	4(a1),d0
			move.l	(a1),d1
			move.l	d0,(a1)
			move.l	d1,4(a1)

			lea		$dff000,a6
			WAITBLIT
			move.l	#_basepattern,bltapt(a6)
			move.l	d1,bltdpt(a6)
			move.l	#-1,bltafwm(a6)
			move.w	#$09f0,bltcon0(a6)
			move.w	#$0000,bltcon1(a6)
			move.w	#0,bltamod(a6)
			move.w	#0,bltdmod(a6)
			move.w	#0,bltamod(a6)
			move.w	#7<<6+20,bltsize(a6)			; blit template line
			WAITBLIT
			move.l	d1,bltapt(a6)
			move.w	#7*63<<6+20,bltsize(a6)			; duplicate line to create blank pattern

			move.l	d0,a6							; move

			lea		_font_small,a5					; font source

			moveq	#64-1,d4						; pattern line counter
.lineloop	moveq	#4-1,d7							; channel counter

.chanloop	move.l	(a0)+,d0
			move.l	d0,d1
			swap	d1
			and.w	#$fff,d1						; d1 = note
			beq		.skipnote						; result of and means no period value found so skip

			lea		PT_Notes(pc),a1					; ascii note look up

													; rolled out loop to save some cycles
.notefind	rept	36
			cmp.w	(a1)+,d1						; TODO: maybe optimise thie with a look up
			beq		.gotnote
			addq.l	#4,a1
			endr
			bra.b	.skipnote

.gotnote	lea		1(a6),a4						; note text now in A1

			moveq	#3-1,d5							; 3 chars per note
.nextlet	moveq	#0,d1
			move.b	(a1)+,d1
			move.l	a5,a3					; a3 now at font..
			move.l	a4,a2

.charloop	PT_CharPlot a3,a2,40,d1
			addq.l	#1,a4
			dbra	d5,.nextlet

.skipnote	; do effects
			swap	d0								; flip to focus on effect data
			and.w	#$f000,d0
			beq.b	.skiprot
			rol.w	#4,d0

.skiprot	swap	d0
			tst.l	d0
			beq.b	.skipfx							; no effect command or values, so skip

			moveq	#5-1,d6							; 5 letters
			lea		PT_HexList,a1
			lea		8(a6),a4						; plane data

.fxloop		moveq	#0,d2							; char..
			moveq	#0,d1
			move.b	d0,d1
			and.b	#$f,d1							; current value
			beq.b	.skipzero

			move.b	(a1,d1.w),d2					; char value
			move.l	a5,a3

			move.l	a4,a2
			PT_CharPlot	a3,a2,40,d2

.skipzero	ror.l	#4,d0
			tst.w	d0
			beq.b	.skipfx
			lea		-1(a4),a4
			dbra	d6,.fxloop

.skipfx		lea		10(a6),a6							; move to next 8 chars on the plane
			dbra	d7,.chanloop						; loop to next channel

			lea		(PT_LineHeight-1)*40(a6),a6			; move to next char line on the plane
			dbra	d4,.lineloop						; loop to next pattern line
.quit		;move.w	#$0f0,$dff180						; terrible mechanism for seeing how quick it is
			rts


			; pushes plane pointers in copper to follow pattern data
PT_PatPos2	move.l	PT_PlanePtr(pc),d0
			sub.l	#40*PT_LineHeight*PT_Offset,d0
			moveq	#0,d1
			move.w	_mt_PatternPos,d1
			lsr.w	#4,d1
			mulu	#40*PT_LineHeight,d1
			add.l	d1,d0
			lea		_cpat,a0
			move.w	d0,6(a0)
			swap	d0
			move.w	d0,2(a0)

			rts


			; a0 = text
			; a1 = plane area
ST_Type		lea		_font_small,a5

.nextline	moveq	#40-1,d4				; character line counter

.nextchar	moveq	#0,d0
			move.b	(a0)+,d0
			move.l	a5,a2					; copy font pointer
			move.l	a1,a3					; copy plane pointer

.charloop	PT_CharPlot a2,a3,40,d0			; plot char

			addq.l	#1,a1					; move plane pointer
			dbra	d4,.nextchar			; loop char

			lea		(40*6)(a1),a1			; move to next character line on the plane
			dbra	d7,.nextline
			rts

PT_PlanePtr	dc.l	_pattern1
			dc.l	_pattern2 

PT_HexList	dc.b	"0123456789ABCDEF"
			even

PT_Notes	dc.w 113
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
