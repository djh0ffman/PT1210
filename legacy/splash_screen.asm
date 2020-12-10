
		ifne	SW_Splash
;---------------------------------------------------
;-- Splash screen
;---------------------------------------------------

		section splashstart,code_c

nope		rts

		section splash,code_c

splashgo	lea	splashimage(pc),a0
		lea	splashplanes(pc),a1

		move.l	a0,d0
		moveq	#5-1,d7
.hudloop	move.w	d0,6(a1)
		swap	d0
		move.w	d0,2(a1)
		swap	d0
		add.l	#40,d0
		addq.l	#8,a1
		dbra	d7,.hudloop

		lea	splashblack(pc),a0
		move.l	a0,d0
		lea	splashsprites(pc),a0

		moveq	#8-1,d7

.sprloop	move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		addq.l	#8,a0
		dbra	d7,.sprloop


		lea	splashcopper(pc),a0
		lea	$dff000,a6
		move.l	a0,cop1lc(a6)

		lea	splashpalcop(pc),a0
		lea	splashpal(pc),a1
		moveq	#32-1,d0
		moveq	#3,d1
		bsr	CF_Init

.loop		bsr	splashwait
		moveq	#0,d0
		bsr	CF_Do
		tst.b	d0
		beq.b	.loop

		move.w	#3*50,d7
.wait		bsr	splashwait
		dbra	d7,.wait

		lea	splashpalcop(pc),a0
		lea	splashblack(pc),a1
		moveq	#32-1,d0
		moveq	#3,d1
		bsr	CF_Init

.loop2		bsr	splashwait
		moveq	#0,d0
		bsr	CF_Do
		tst.b	d0
		beq.b	.loop2


		rts

*************************************************
**  Colour Fade System
** CF_Init
** A0 = Copper Pointer (current colours)
** A1 = Destination Pallete (color to go too)
** D0 = Color count (zero based!!)
** D1 = Frame wait
** CF_Do		; call each frame
** no Params
*************************************************

;- data structure
		rsreset
CF_CopPtr	rs.l	1
CF_PalPtr	rs.l	1
CF_ColCnt	rs.b	1
CF_FrmWait	rs.b	1
CF_FrmCnt	rs.b	1
CF_ColChange	rs.b	1
CF_Complete	rs.b	1
CF_DataSize	rs.b	0

CF_Init		lea	CF_Data(pc),a2
		move.l	a0,CF_CopPtr(a2)
		move.l	a1,CF_PalPtr(a2)	; store cp ptr
		move.b	d0,CF_ColCnt(a2)
		move.b	d1,CF_FrmWait(a2)
		clr.b	CF_FrmCnt(a2)
		clr.b	CF_Complete(a2)
		rts

CF_Do		movem.l	d1-a6,-(sp)
		lea	CF_Data(pc),a2

		add.b	#1,CF_FrmCnt(a2)
		move.b	CF_FrmCnt(a2),d0
		lea	CF_FrmWait(a2),a3
		cmp.b	(a3),d0
		bne	CF_Quit

		clr.b	CF_FrmCnt(a2)

		tst.b	CF_Complete(a2)
		bne	CF_Quit

		clr.b	CF_ColChange(a2)	;test for complete

		moveq	#0,d0
		move.b	CF_ColCnt(a2),d0	; get count of colours

		move.l	CF_CopPtr(a2),a0	; copper a0
		move.l	CF_PalPtr(a2),a1	; pallete a1

CF_NextColour	moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3			; final colour
		moveq	#2,d6			; rgb count
		move.w	2(a0),d1		; current colour
		move.w	(a1),d2			; destination colour

		cmp.w	d1,d2
		beq.s	CF_NoChange

		move.b	#1,CF_ColChange(a2)	; color change flagged
CF_NextPrime	moveq	#0,d4
		moveq	#0,d5
		move.b	d1,d4
		move.b	d2,d5
		and.b	#$f,d4
		and.b	#$f,d5

		cmp.b	d5,d4
		blo.s	CF_AddCol
		beq.s	CF_MoveCol

		sub.b	#$1,d4
		bra.s	CF_MoveCol

CF_AddCol	add.b	#$1,d4

CF_MoveCol	or.w	d4,d3

		ror.w	#4,d3
		lsr.w	#4,d1		; shift cols
		lsr.w	#4,d2

	        dbra	d6,CF_NextPrime

		lsr.w	#4,d3		; now have final colour
		move.w	d3,2(a0)	; chuck it on the copper

CF_NoChange	lea	4(a0),a0
		lea	2(a1),a1
		dbra	d0,CF_NextColour

		tst.b	CF_ColChange(a2)
		bne.s	CF_Quit

		move.b	#1,CF_Complete(a2)

CF_Quit		move.b	CF_Complete(a2),d0
		movem.l	(sp)+,d1-a6
		rts

CF_Data		ds.b	CF_DataSize

		even



splashwait
	move.l	d0,-(a7)
.loop	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.loop
.loop2	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.loop2
	move.l	(a7)+,d0
	rts



splashcopper
		dc.w	bplcon0,$5200	; set as 1 bp display
		dc.w	bplcon1,$0000	; set scroll 0
		dc.w	bpl1mod,(4*40)
		dc.w	bpl2mod,(4*40)
		dc.w	ddfstrt,$38	; datafetch start stop
		dc.w	ddfstop,$d0
		dc.w	diwstrt,$2c81	; window start stop
		dc.w	diwstop,$f4c1

splashpalcop	dc.w	$180,$0
		dc.w	$182,$0
		dc.w	$184,$0
		dc.w	$186,$0
		dc.w	$188,$0
		dc.w	$18a,$0
		dc.w	$18c,$0
		dc.w	$18e,$0
		dc.w	$190,$0
		dc.w	$192,$0
		dc.w	$194,$0
		dc.w	$196,$0
		dc.w	$198,$0
		dc.w	$19a,$0
		dc.w	$19c,$0
		dc.w	$19e,$0
		dc.w	$1a0,$0
		dc.w	$1a2,$0
		dc.w	$1a4,$0
		dc.w	$1a6,$0
		dc.w	$1a8,$0
		dc.w	$1aa,$0
		dc.w	$1ac,$0
		dc.w	$1ae,$0
		dc.w	$1b0,$0
		dc.w	$1b2,$0
		dc.w	$1b4,$0
		dc.w	$1b6,$0
		dc.w	$1b8,$0
		dc.w	$1ba,$0
		dc.w	$1bc,$0
		dc.w	$1be,$0

splashplanes	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
		dc.w	bplpt+8,$0
		dc.w	bplpt+10,$0
		dc.w	bplpt+12,$0
		dc.w	bplpt+14,$0
		dc.w	bplpt+16,$0
		dc.w	bplpt+18,$0

splashsprites	dc.w	sprpt,0
		dc.w	sprpt+2,0
		dc.w	sprpt+4,0
		dc.w	sprpt+6,0
		dc.w	sprpt+8,0
		dc.w	sprpt+10,0
		dc.w	sprpt+12,0
		dc.w	sprpt+14,0
		dc.w	sprpt+16,0
		dc.w	sprpt+18,0
		dc.w	sprpt+20,0
		dc.w	sprpt+22,0
		dc.w	sprpt+24,0
		dc.w	sprpt+26,0
		dc.w	sprpt+28,0
		dc.w	sprpt+30,0

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe


splashpal	dc.w	$0000
		dc.w	$0111
		dc.w	$0222
		dc.w	$0333
		dc.w	$0444
		dc.w	$0555
		dc.w	$0777
		dc.w	$0888
		dc.w	$0999
		dc.w	$0BBB
		dc.w	$0DDD
		dc.w	$0FFF
		dc.w	$0F29
		dc.w	$0904
		dc.w	$0567
		dc.w	$0666
		dc.w	$0F70
		dc.w	$0940
		dc.w	$0D00
		dc.w	$0900
		dc.w	$00FB
		dc.w	$0096
		dc.w	$0FC0
		dc.w	$0FAD
		dc.w	$0C07
		dc.w	$0A05
		dc.w	$0703
		dc.w	$001F
		dc.w	$0015
		dc.w	$04F0
		dc.w	$0290
		dc.w	$0000

splashblack
		dcb.w	32,$0

splashimage
		incbin	gfx/splash.raw


		endc

