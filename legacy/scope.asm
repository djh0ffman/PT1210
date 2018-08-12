
***************************************************
** mega scope!!
***************************************************

;---- Scope ----

ns_sampleptr =  0
ns_endptr    =  4
ns_repeatptr =  8
ns_rependptr = 12
ns_period    = 16
ns_volume    = 18

scopepos	= 0		; line number
scopeplanewidth	= 40		; plane width
scopesize	= 32		; 16 or 32 pixels
scopefactor	= 7		; set as 7 for 16 and 8 for 32
scopebytewd	= 10	; byte draw width

ScopeInit	lea	VolCalc(pc),a0
		moveq	#1,d2		; volume counter
		moveq	#0,d0		; smp data
	
.nxsmp		move.l	d0,d3
		move.l	d2,d4
		EXT.W	D0		; extend to word
		NEG.W	D0		; negate
		MULS	D2,D0		; multiply by volume
		ASR.W	#7,D0		; shift down
		MOVE.W	D0,D1
		ASL.W	#5,D0		; * 32
		ASL.W	#3,D1		; * 8
		ADD.W	D1,D0		; (32+8) = * 40
		move.w	d0,(a0)+
		move.l	d3,d0
		move.l	d2,d4
		addq.b	#1,d0
		tst.b	d0
		bne.b	.nxsmp
		addq.b	#1,d2
		cmp.b	#33,d2
		bne.b	.nxsmp		
		rts

Scope		bsr	ScopeClr
		tst.b	_mt_Enabled
		beq.b	ScopeStop
		bsr	ScopeD
		bsr.b	ScopeBlitFill
ScopeCont	bsr.b	ScopeRt
		bsr	ScopeShow
		rts
		
ScopeStop	LEA	ScopeInfo(pc),A2
		clr.l	ns_sampleptr(A2)
		lea	20(a2),a2
		clr.l	ns_sampleptr(A2)
		lea	20(a2),a2
		clr.l	ns_sampleptr(A2)
		lea	20(a2),a2
		clr.l	ns_sampleptr(A2)
		bra.b	ScopeCont
		
ScopeRt		lea	ScopePtr(pc),a0
		movem.l	(a0)+,d0/d1
		move.l	d0,-(a0)
		move.l	d1,-(a0)
		rts

ScopeBlitFill	lea	$dff000,a6
		move.l	ScopePtr+4,d2
		moveq	#20,d0			; width words
		moveq	#(scopesize)-1,d1			; lines
		lsl.w	#6,d1			; shift up
		or.w	d0,d1			; blitsize
		moveq	#-1,d7
		
		WAITBLIT

		move.l	d2,bltapt(a6)	
		add.l	#40,d2
		move.l	d2,bltcpt(a6)
		move.l	d2,bltdpt(a6)		; load dest
				
		move.l	d7,bltafwm(a6)		; clear word masks
		clr.l	bltcmod(a6)		; clear mods
		clr.l	bltamod(a6)		;
		clr.w	bltcon1(a6)		; clear control2
		move.w	#$0b5a,bltcon0(a6)	; set control1
		move.w	d1,bltsize(a6)		; BLIT!
		
		WAITBLIT

		moveq	#20,d0			; width words
		moveq	#(scopesize),d1		; lines
		lsl.w	#6,d1			; shift up
		or.w	d0,d1			; blitsize

		move.l	ScopePtr+4,d2
		add.l	#(((scopesize*2)+1)*scopeplanewidth)-1,d2
		move.l	d2,bltapt(a6)	
		sub.l	#40,d2
				
		move.l	d2,bltcpt(a6)
		move.l	d2,bltdpt(a6)		; load dest

		move.l	d7,bltafwm(a6)		; clear word masks
		clr.l	bltcmod(a6)		; clear mods
		clr.l	bltamod(a6)		;

		move.w	#2,bltcon1(a6)		; clear control2
		move.w	#$0b5a,bltcon0(a6)	; set control1
		move.w	d1,bltsize(a6)		; BLIT!

		rts

ScopeClr	lea	$dff000,a6
		move.l	ScopePtr+4,d2
		moveq	#20,d0			; width words

		moveq	#(scopesize*2)+1,d1			; lines
		lsl.w	#6,d1			; shift up
		or.w	d0,d1			; blitsize
		WAITBLIT
		move.l	d2,bltdpt(a6)		; load dest
		clr.w	bltdmod(a6)		; clear dest mod
		clr.w	bltcon1(a6)		; clear control2
		move.w	#$100,bltcon0(a6)	; set control1
		move.w	d1,bltsize(a6)		; BLIT!
		WAITBLIT
		rts

ScopeShow	move.l	ScopePtr(pc),d0		; load plane to copper
		lea	_cScope,a0		
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		rts

ScopeD	move.w	_channel_toggle,d4
	LEA	mt_chan1temp(pc),A0
	LEA	ScopeInfo(pc),A2
	LEA	ScopeSamInfo(pc),A1
	MOVEQ.L	#3,D6
ScoLoop	MOVE.W	(A0),D0
	AND.W	#$0FFF,D0
	OR.W	n_period(A0),D0
	BEQ	ScoSampleEnd ; end if no note & no period

	MOVE.W	n_period(A0),d5
	bsr	mt_tuneup
	move.w	d5,ns_period(A2)
	MOVE.B	n_volume(A0),ns_volume(A2)


	TST.B	n_trigger(A0)
	BEQ	ScoContinue
ScoRetrig
	SF	n_trigger(A0)
	btst	#0,d4
	bne.b	.skip
	move.l	#0,ns_sampleptr(a2)
	bra.b	.skip2
	
.skip	BSR	SetScope
	MOVEQ	#0,D0
	MOVE.B	n_samplenum(A0),D0
	SUBQ.W	#1,D0
	LSL.W	#4,D0
	MOVE.L	ns_sampleptr(A1,D0.W),ns_sampleptr(A2)
	MOVE.L	ns_endptr(A1,D0.W),ns_endptr(A2)
	MOVE.L	ns_repeatptr(A1,D0.W),ns_repeatptr(A2)
	MOVE.L	ns_rependptr(A1,D0.W),ns_rependptr(A2)
.skip2	MOVE.L	ns_sampleptr(A2),D0
	tst.l	d0
	BEQ.S	ScoNextChan
	BRA	ScoChk
ScoContinue
	MOVE.L	ns_sampleptr(A2),D0
	tst.l	d0
	BEQ.S	ScoNextChan
	MOVEQ.L	#0,D1
	MOVE.W	ns_period(A2),D1
	LSR.W	#1,D1
	BEQ.S	ScoNextChan
	MOVE.L	#35469,D2
	DIVU	D1,D2
	EXT.L	D2
	ADD.L	D2,D0
ScoChk	CMP.L	ns_endptr(A2),D0		
	BLO.S	ScoUpdatePtr
	TST.L	ns_repeatptr(A2)
	BNE.S	ScoSamLoop
ScoSampleEnd
	moveq	#0,d0
	BRA.S	ScoUpdatePtr

ScoSamLoop
	SUB.L	ns_endptr(A2),D0
	ADD.L	ns_repeatptr(A2),D0
	MOVE.L	ns_rependptr(A2),ns_endptr(A2)
	CMP.L	ns_endptr(A2),D0
	BHS	ScoSamLoop
ScoUpdatePtr
	MOVE.L	D0,ns_sampleptr(A2)
ScoNextChan
	ADD.L	#20,A2
	lea	mt_chansize(a0),a0
	lsr.b	#1,d4
	DBRA	D6,ScoLoop

; now draw channels

	MOVEQ	#0,D5
	MOVE.L	#((scopepos+scopesize)*scopeplanewidth),A1			; screen pos! centre scope
	LEA	ScopeInfo(pc),A2
	tst.l	(a2)
	beq.b	.skp1
	MOVE.B	ns_volume(A2),D5
	BSR.S	ScoDraw

.skp1	MOVEQ	#0,D5
	LEA	ScopeInfo+20(pc),A2
	tst.l	(a2)
	beq.b	.skp2
	MOVE.L	#((scopepos+scopesize)*scopeplanewidth)+10,A1			; screen pos!
	MOVE.B	ns_volume(A2),D5
	BSR.S	ScoDraw

.skp2	MOVEQ	#0,D5
	LEA	ScopeInfo+40(pc),A2
	tst.l	(a2)
	beq.b	.skp3
	MOVE.L	#((scopepos+scopesize)*scopeplanewidth)+20,A1			; screen pos!
	MOVE.B	ns_volume(A2),D5
	BSR.S	ScoDraw

.skp3	MOVEQ	#0,D5
	LEA	ScopeInfo+60(pc),A2
	tst.l	(a2)
	beq.b	.skp4
	MOVE.L	#((scopepos+scopesize)*scopeplanewidth)+30,A1			; screen pos!
	MOVE.B	ns_volume(A2),D5
	BSR	ScoDraw
.skp4	RTS

ScoDraw	LSR.W	#1,D5		; volume calc..
	CMP.W	#32,D5
	BLS.S	.sdsk1
	MOVEQ	#32,D5

.sdsk1	tst.b	d5
	bne.b	.godraw
	rts

.godraw	subq.b	#1,d5				; no pre-calc for 0 volume!
	MOVE.L	(A2),A0				; sample ptr
	ADD.L	ScopePtr+4(pc),A1		; draw pos
	MOVEQ	#scopebytewd-1,D2				; draw length!

	lea	VolCalc(pc),a3
	
	moveq	#9,d0
	lsl.w	d0,d5
	add.l	d5,a3	

	tst.l	ns_repeatptr(a2)
	beq.b	.noloop

	move.w	#(scopebytewd-1)*8,d6

	move.l	ns_rependptr(a2),d4
	move.l	d4,a4
	move.l	ns_repeatptr(a2),a5
	sub.l	a0,d4
	cmp.l	d6,d4		
	ble	sdloop
	bra.b	sdfast

.noloop	move.l	ns_endptr(a2),d4
	move.l	d4,a4
	sub.l	a0,d4
	moveq	#scopebytewd-1*8,d6
	cmp.l	d6,d4		
	ble	sdend

sdfast	moveq	#0,d0
	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#7,d1
	bset	d1,(a1,d0.w)

	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#6,d0
	bset	d0,(a1,d1.w)

	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#5,d1
	bset	d1,(a1,d0.w)

	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#4,d0
	bset	d0,(a1,d1.w)

	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#3,d1
	bset	d1,(a1,d0.w)

	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#2,d0
	bset	d0,(a1,d1.w)

	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#1,d1
	bset	d1,(a1,d0.w)

	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#0,d0
	bset	d0,(a1,d1.w)

	addq.l	#1,a1
	dbra	d2,sdfast	
	rts

	; loop based drawer
sdloop	moveq	#0,d0
	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#7,d1
	bset	d1,(a1,d0.w)

	cmp.l	a0,a4
	bge.b	.sk1
	move.l	a5,a0
	
.sk1	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#6,d0
	bset	d0,(a1,d1.w)

	cmp.l	a0,a4
	bge.b	.sk2
	move.l	a5,a0

.sk2	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#5,d1
	bset	d1,(a1,d0.w)

	cmp.l	a0,a4
	bge.b	.sk3
	move.l	a5,a0

.sk3	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#4,d0
	bset	d0,(a1,d1.w)

	cmp.l	a0,a4
	bge.b	.sk4
	move.l	a5,a0

.sk4	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#3,d1
	bset	d1,(a1,d0.w)

	cmp.l	a0,a4
	bge.b	.sk5
	move.l	a5,a0

.sk5	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#2,d0
	bset	d0,(a1,d1.w)

	cmp.l	a0,a4
	bge.b	.sk6
	move.l	a5,a0

.sk6	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#1,d1
	bset	d1,(a1,d0.w)

	cmp.l	a0,a4
	bge.b	.sk7
	move.l	a5,a0

.sk7	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#0,d0
	bset	d0,(a1,d1.w)

	cmp.l	a0,a4
	bge.b	.sk8
	move.l	a5,a0

.sk8	addq.l	#1,a1
	dbra	d2,sdloop
	rts

	; sample ending drawer.
sdend	moveq	#0,d0
	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#7,d1
	bset	d1,(a1,d0.w)

	cmp.l	a0,a4
	bge.b	.sk1
	rts
	
.sk1	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#6,d0
	bset	d0,(a1,d1.w)

	cmp.l	a0,a4
	bge.b	.sk2
	rts

.sk2	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#5,d1
	bset	d1,(a1,d0.w)

	cmp.l	a0,a4
	bge.b	.sk3
	rts

.sk3	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#4,d0
	bset	d0,(a1,d1.w)

	cmp.l	a0,a4
	bge.b	.sk4
	rts

.sk4	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#3,d1
	bset	d1,(a1,d0.w)

	cmp.l	a0,a4
	bge.b	.sk5
	rts

.sk5	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#2,d0
	bset	d0,(a1,d1.w)

	cmp.l	a0,a4
	bge.b	.sk6
	rts

.sk6	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	(a3,d0.w),d0
	moveq	#1,d1
	bset	d1,(a1,d0.w)

	cmp.l	a0,a4
	bge.b	.sk7
	rts

.sk7	move.b	(a0)+,d1
	add.w	d1,d1
	move.w	(a3,d1.w),d1
	moveq	#0,d0
	bset	d0,(a1,d1.w)

	cmp.l	a0,a4
	bge.b	.sk8
	rts

.sk8	addq.l	#1,a1
	dbra	d2,sdend
	rts


SetScope
	MOVEQ	#0,D1
	MOVE.B	n_samplenum(A0),D1
	bne.b	.high
	clr.l	ns_sampleptr(a4)
	rts
	
.high	SUBQ.W	#1,D1
	LSL.W	#4,D1
	LEA	ScopeSamInfo,A4
	LEA	(A4,D1.W),A4

	move.l	n_offsethack(a0),d0
	bne.b	.hack
	MOVE.L	n_start(A0),D0
.hack

.skipset
	MOVE.L	D0,ns_sampleptr(A4)
	MOVEQ	#0,D1
	move.w	n_offsetlen(a0),d1
	bne.b	.skip
	MOVE.W	n_length(A0),D1
.skip	ADD.L	D1,D0
	ADD.L	D1,D0
	MOVE.L	D0,ns_endptr(A4)

	MOVE.L	n_loopstart(A0),D0
	MOVE.L	D0,ns_repeatptr(A4)
	MOVEQ	#0,D1
	MOVE.W	n_replen(A0),D1
	CMP.W	#1,D1
	BEQ.S	sconorep
	ADD.L	D1,D0
	ADD.L	D1,D0
	MOVE.L	D0,ns_rependptr(A4)
	RTS
sconorep
	CLR.L	ns_repeatptr(A4)
	RTS





ScopePtr	dc.l	_pScope1,_pScope2

SamDrawStart	dc.l 0
SamDrawEnd	dc.l 0

ScopeInfo	ds.b	22*4
ScopeSamInfo	ds.b	16*31

VolCalc		dcb.w	256*33,0

