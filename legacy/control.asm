
; *******************************************
; ******************** CONTROLS!!!!!!!!!!!!
; *******************************************

; Imports from C code
	XREF _pt1210_file_sort_list

keyboard	lea	keys(pc),a0
		lea	keys2(pc),a1
		lea	keysfr(pc),a4
		move.l	keylistptr(pc),a2
.loop		moveq	#-1,d0
		moveq	#0,d1
		move.b	(a2),d1				; get key code
		cmp.b	d0,d1				; check for end of list
		beq.b	.quit				; end of list quit
		cmp.b	(a0,d1.w),d0		; check for key pressed
		beq.b	.dokey				; key pressed
.nextkey	lea	6(a2),a2
		bra.b	.loop
.quit		rts

.dokey
		move.l	2(a2),a3		; get the function
		tst.b	1(a2)				; test press type
		beq.b	.dofunc				; 0 = do it all the time

		cmp.b	#1,1(a2)			; 1 = once only
		beq.b	.once

		cmp.b	#2,1(a2)			; 2 = press and hold
		beq.b	.phold

		cmp.b	#3,1(a2)
		beq.b	.quiter

		bra.b	.nextkey


.quiter		tst.b	(a1,d1.w)
		bne.b	.pquit
		move.b	#1,(a4,d1.w)
		bra.b	.nextkey

.pquit		add.b	#1,(a4,d1.w)
		cmp.b	#30,(a4,d1.w)
		ble.b	.nextkey
		bra.b	.dofunc


.phold		tst.b	(a1,d1.w)
		bne.b	.pcont
		move.b	#1,(a4,d1.w)
		bra.b	.dofunc

.pcont		add.b	#1,(a4,d1.w)
		cmp.b	#30,(a4,d1.w)
		ble.b	.nextkey
		cmp.b	#32,(a4,d1.w)
		ble.b	.nextkey
		move.b	#30,(a4,d1.w)
		bra.b	.dofunc

.once		tst.b	(a1,d1.w)			; else test to see if was pressed last time
		bne.b	.nextkey			; was pressed last frame, skip to next key
.dofunc		movem.l	d0-a6,-(sp)
		jsr	(a3)			; do the function
		movem.l	(sp)+,d0-a6
		bra	.nextkey				; done, go to next key



pitchdown	tst.b	$60(a0)
		bne.b	.fine
		tst.b	$61(a0)
		bne.b	.fine

		moveq	#0,d0
		move.b	CIABPM,d0
		add.w	OFFBPM,d0
		cmp.w	#20,d0
		ble.b	.skip
		subq.w	#1,OFFBPM
.skip		rts

.fine		move.b	BPMFINE,d0
		subq.b	#1,d0
		cmp.b	#0,d0
		bge.b	.ok

		moveq	#0,d1
		move.b	CIABPM,d1
		add.w	OFFBPM,d1
		cmp.w	#20,d1
		ble.b	.skipfine
		sub.w	#1,OFFBPM
		moveq	#$f,d0
.ok		move.b	d0,BPMFINE
.skipfine	rts

pitchup		tst.b	$60(a0)
		bne.b	.fine
		tst.b	$61(a0)
		bne.b	.fine

		moveq	#0,d0
		move.b	CIABPM,d0
		add.w	OFFBPM,d0
		cmp.w	#300,d0
		bge.b	.skip
		addq.w	#1,OFFBPM
.skip		rts

.fine		move.b	BPMFINE,d0
		addq.b	#1,d0
		cmp.b	#$f,d0
		ble.b	.ok

		moveq	#0,d1
		move.b	CIABPM,d1
		add.w	OFFBPM,d1
		cmp.w	#299,d1
		bge.b	.skipfine

		add.w	#1,OFFBPM
		moveq	#0,d0
.ok		move.b	d0,BPMFINE
.skipfine	rts


nudgefwd
		tst.b	$60(a0)
		bne.b	.large
		tst.b	$61(a0)
		bne.b	.large
		move.w	#1,NUDGE
		bra	.quit
.large		move.w	#6,NUDGE
.quit		rts

nudgebkw
		tst.b	$60(a0)
		bne.b	.large
		tst.b	$61(a0)
		bne.b	.large
		move.w	#-1,NUDGE
		bra	.quit
.large		move.w	#-6,NUDGE
.quit		rts


rescan		clr.b	(a0,d1.w)
		move.b	#1,FS_DoScan
		rts


loadtune
		clr.b	(a0,d1.w)
		move.b	#1,FS_DoLoad
		rts

backup		lea	keys(pc),a0
		lea	keys2(pc),a1
		moveq	#$20-1,d7
.lop		move.l	(a0)+,(a1)+
		dbra	d7,.lop

		rts


switch		;movem.l	d0-a6,-(sp)
		lea	$dff000,a6
		tst.w	currentscreen
		beq.b	.loaddj

		move.l	#keylistdir,keylistptr
		move.l	#_select_cop,cop2lc(a6)
		clr.w	currentscreen
		bra.b	.quit
.loaddj
		move.l	#keylistdj,keylistptr
		move.l	#_cCopper,cop2lc(a6)
		move.w	#1,currentscreen

.quit		;movem.l	(sp)+,d0-a6
		rts

currentscreen	dc.w	0


playpause	tst.b	mt_Enabled
		beq.b	.disable
		clr.b	mt_Enabled
		jsr	mt_end

		bra.b	.quit
.disable	move.b	#1,mt_Enabled
.quit		rts


patcueset	move.b	mt_SongPos,mt_PatternCue
		rts

patternlock	move.b	mt_PatternLock,d6
		tst.b	d6
		beq.b	.start
		cmp.b	#1,d6
		beq.b	.end
		cmp.b	#2,d6
		beq.b	.clear
		rts

.start		move.b	mt_SongPos,d6
		move.b	d6,mt_PatLockStart
		move.b	#1,mt_PatternLock
		bra.b	.quit

.end		move.b	mt_SongPos,d6
		move.b	d6,mt_PatLockEnd
		move.b	#2,mt_PatternLock
		bra	.quit

.clear		clr.b	mt_PatternLock
		clr.b	mt_PatLockStart
		clr.b	mt_PatLockEnd

.quit		rts


restart		clr.b	mt_SongPos
		move.b	mt_PatternCue,mt_SongPos
		clr.w	mt_PatternPos
		move.b	mt_speed,d6
		move.b	d6,mt_counter
		clr.b	mt_TuneEnd
		clr.b	Time_Frames
		clr.b	Time_Minutes
		clr.b	Time_Seconds
;		clr.b	mt_counter
		clr.b	mt_PattDelTime
		clr.b	mt_PattDelTime2
		rts

sliprestart	move.b	patslipflag,d0
		tst.b	d0
		beq.b	.active
		moveq	#0,d0
		bra.b	.write

.active		moveq	#1,d0


.write		move.b	d0,patslipflag
		rts

patslipflag	dc.b	0
patslippat	dc.b	0
		even


loopinc		move.b	loopsize(pc),d0
		cmp.b	#32,d0
		beq.b	.quit
		lsl.b	#1,d0
		move.b	d0,loopsize
		tst.b	loopactive
		bne.w	loopresize
.quit		rts

loopdec		move.b	loopsize(pc),d0
		cmp.b	#1,d0
		beq.b	.quit
		lsr.b	#1,d0
		move.b	d0,loopsize
		tst.b	loopactive
		bne	loopresize
.quit		rts

loopset		move.b	loopactive(pc),d0
		tst.b	d0
		beq.b	.set
		moveq	#0,d0
		tst.b	slipon
		beq.b	.meh
		moveq	#0,d1
		moveq	#0,d3

		move.b	mt_SLSongPos,d1
		move.b	mt_SongLen,d3
		move.w	mt_SLPatternPos,d2
		cmp.w	d1,d3
		bgt.b	.notend
		moveq	#0,d1
		moveq	#0,d2
		st.b	mt_TuneEnd
.notend		move.b	d1,mt_SongPos
		move.w	d2,mt_PatternPos
.meh		bra.b	.save

.set		moveq	#1,d0
		move.b	mt_SongPos,d1
		move.w	mt_PatternPos,d2
		move.b	d1,mt_SLSongPos
		move.w	d2,mt_SLPatternPos

		move.w	mt_PatternPos,d1
;		and.w	#$fff0,d1
		lsr.w	#4,d1
		and.b	#%11111100,d1
		move.b	d1,loopstart
		add.b	loopsize,d1
		move.b	d1,loopend

.save		move.b	d0,loopactive
		rts

loopresize	move.b	loopstart,d0
		add.b	loopsize,d0
		move.b	d0,loopend
		rts

loopsize	dc.b	4
loopactive	dc.b	0
loopstart	dc.b	0
loopend		dc.b	0
		even

tog1		move.w	chantog,d6
		btst	#3,d6
		beq.b	.turnon
		bclr	#3,d6
		bra	.doit

.turnon		bset	#3,d6
.doit		move.w	d6,chantog
		rts

tog2		move.w	chantog,d6
		btst	#2,d6
		beq.b	.turnon
		bclr	#2,d6
		bra	.doit

.turnon		bset	#2,d6
.doit		move.w	d6,chantog
		rts

tog3		move.w	chantog,d6
		btst	#1,d6
		beq.b	.turnon
		bclr	#1,d6
		bra	.doit

.turnon		bset	#1,d6
.doit		move.w	d6,chantog
		rts

tog4		move.w	chantog,d6
		btst	#0,d6
		beq.b	.turnon
		bclr	#0,d6
		bra	.doit

.turnon		bset	#0,d6
.doit		move.w	d6,chantog
		rts


chantog		dc.w	%0000000000001111


sliptog		move.b	slipon(pc),d0
		tst.b	d0
		beq.b	.active
		clr.b	d0
		clr.b	mt_SLSongPos
		clr.w	mt_SLPatternPos
		bra	.write

.active		moveq	#1,d0
		move.b	mt_SongPos,d1
		move.w	mt_PatternPos,d2
		move.b	d1,mt_SLSongPos
		move.w	d2,mt_SLPatternPos
		bra	.write

.write		move.b	d0,slipon
		rts


slipon		dc.b	1
		even


togglerepitch	move.b	repitch,d0
		tst.b	d0
		beq.b	.active
		moveq	#0,d0
		bra.b	.write

.active		moveq	#1,d0
.write		move.b	d0,repitch
		rts

repitch		dc.b	1
		even


movefwd		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2

		MOVE.L	mt_SongDataPtr,A1
		move.b	950(A1),D0
		move.b	mt_SongPos,d1
		move.b	mt_PatternCue,d2

		tst.b	$60(a0)
		bne.b	.movefwdline
		tst.b	$61(a0)
		bne.b	.movefwdline

		tst.b	$63(a0)
		bne.b	.movefwdcue

		subq.b	#2,d0
		cmp.b	d0,d1
		bgt.b	.skip
		add.b	#1,mt_SongPos
.skip		rts

.movefwdcue	subq.b	#2,d0
		cmp.b	d0,d2
		bgt.b	.skip
		add.b	#1,mt_PatternCue
		rts


.movefwdline	moveq	#0,d1
		moveq	#0,d2
		move.b	loopsize,d1
		move.w	mt_PatternPos,d2
		lsl.w	#4,d1
		add.l	d1,d2
		cmp.l	#1024,d2
		blo.b	.skipadd
		moveq	#0,d0
		cmp.b	mt_SongPos,d0
		subq.b	#1,d0
		blo.b	.skipadd
		add.b	#1,mt_SongPos
.skipadd	and.w	#1024-1,d2
		move.w	d2,mt_PatternPos
		rts


moveback	tst.b	$60(a0)
		bne.b	.movebackline
		tst.b	$61(a0)
		bne.b	.movebackline

		tst.b	$63(a0)
		bne.b	.movebackcue

		tst.b	mt_SongPos
		beq.b	.skip
		sub.b	#1,mt_SongPos
.skip		rts

.movebackcue	tst.b	mt_PatternCue
		beq.b	.skip2
		sub.b	#1,mt_PatternCue
.skip2		rts

.movebackline	moveq	#0,d1
		moveq	#0,d2
		move.b	loopsize,d1
		move.w	mt_PatternPos,d2
		lsl.w	#4,d1
		sub.l	d1,d2
		cmp.l	#0,d2
		bge.b	.skipadd
		tst.b	mt_SongPos
		beq.b	.skipall
		sub.b	#1,mt_SongPos
.skipadd	and.w	#1024-1,d2
		move.w	d2,mt_PatternPos
.skipall	rts

sortbpm
		tst.w	sortbpmtog
		beq.b	.desc

		move.l	#0,-(sp)			; ascending
		move.w	#0,sortbpmtog
		bra .done

.desc	move.l	#1,-(sp)			; descending
		move.w	#1,sortbpmtog

.done	move.l	#SORT_BPM,-(sp)		; sort by bpm

		bsr	_pt1210_file_sort_list
		add.l #8,sp

		bsr	FS_DrawDir
		rts

sortbpmtog	dc.w	0

sortfile
		tst.w	sortfiletog
		beq.b	.desc

		move.l	#0,-(sp)				; ascending
		move.w	#0,sortfiletog
		bra .done

.desc	move.l	#1,-(sp)				; descending
		move.w	#1,sortfiletog

.done	move.l	#SORT_NAME,-(sp)		; sort by name

		bsr	_pt1210_file_sort_list
		add.l #8,sp

		bsr	FS_DrawDir
		rts

sortfiletog	dc.w	0

quitme		tst.b	mt_Enabled
		bne.b	.skip
		move.w	#1,quitmeplease
.skip		rts

quitmeplease	dc.w	0

		; key list
		; byte1 key code
		; byte2 pressing type (0 = hold / 1 = hit /�2 = hold repeat)
		; long word (function

keylistptr	dc.l	keylistdir

keylistdj	dc.b	$5f,$1
		dc.l	switch
		dc.b	$4c,$02
		dc.l	pitchup
		dc.b	$4d,$02
		dc.l	pitchdown
		dc.b	$4e,$00
		dc.l	nudgefwd
		dc.b	$4f,$00
		dc.l	nudgebkw
		dc.b	$40,$01
		dc.l	playpause
		dc.b	$50,$01
		dc.l	restart
		dc.b	$51,$01
		dc.l	sliprestart
		dc.b	$52,$01
		dc.l	patcueset

		dc.b	$59,$01
		dc.l	patternlock
		dc.b	$55,$01
		dc.l	loopdec
		dc.b	$56,$01
		dc.l	loopinc
		dc.b	$54,$01
		dc.l	loopset
		dc.b	$53,$01
		dc.l	sliptog
		dc.b	$01,$01
		dc.l	tog4
		dc.b	$02,$01
		dc.l	tog3
		dc.b	$03,$01
		dc.l	tog2
		dc.b	$04,$01
		dc.l	tog1
		dc.b	$42,$01
		dc.l	togglerepitch
		dc.b	$00,$01
		dc.l	mt_end
		dc.b	$0c,$02
		dc.l	movefwd
		dc.b	$0b,$02
		dc.l	moveback
		dc.b	$45,$03
		dc.l	quitme
		dc.b	$ff
		even

keylistdir	dc.b	$5f,$01
		dc.l	switch
		dc.b	$4c,$02		; new key type 2
		dc.l	FS_MoveUp
		dc.b	$4d,$02
		dc.l	FS_MoveDown
		dc.b	$44,$01
		dc.l	loadtune
		dc.b	$58,$01
		dc.l	sortfile
		dc.b	$59,$01
		dc.l	sortbpm
		dc.b	$57,$01
		dc.l	FS_SwitchType
		dc.b	$45,$03
		dc.l	quitme

		dc.b	$50,$03
		dc.l	rescan

		dc.b	$10,$01
		dc.l	findQ
		dc.b	$11,$01
		dc.l	findW
		dc.b	$12,$01
		dc.l	findE
		dc.b	$13,$01
		dc.l	findR
		dc.b	$14,$01
		dc.l	findT
		dc.b	$15,$01
		dc.l	findY
		dc.b	$16,$01
		dc.l	findU
		dc.b	$17,$01
		dc.l	findI
		dc.b	$18,$01
		dc.l	findO
		dc.b	$19,$01
		dc.l	findP

		dc.b	$20,$01
		dc.l	findA
		dc.b	$21,$01
		dc.l	findS
		dc.b	$22,$01
		dc.l	findD
		dc.b	$23,$01
		dc.l	findF
		dc.b	$24,$01
		dc.l	findG
		dc.b	$25,$01
		dc.l	findH
		dc.b	$26,$01
		dc.l	findJ
		dc.b	$27,$01
		dc.l	findK
		dc.b	$28,$01
		dc.l	findL

		dc.b	$31,$01
		dc.l	findZ
		dc.b	$32,$01
		dc.l	findX
		dc.b	$33,$01
		dc.l	findC
		dc.b	$34,$01
		dc.l	findV
		dc.b	$35,$01
		dc.l	findB
		dc.b	$36,$01
		dc.l	findN
		dc.b	$37,$01
		dc.l	findM
		dc.b	$0a,$01
		dc.l	find0
		dc.b	$01,$01
		dc.l	find1
		dc.b	$02,$01
		dc.l	find2
		dc.b	$03,$01
		dc.l	find3
		dc.b	$04,$01
		dc.l	find4
		dc.b	$05,$01
		dc.l	find5
		dc.b	$06,$01
		dc.l	find6
		dc.b	$07,$01
		dc.l	find7
		dc.b	$08,$01
		dc.l	find8
		dc.b	$09,$01
		dc.l	find9
		dc.b	$ff

		even

find0		move.b	#"0",d0
		bra	hunt
find1		move.b	#"1",d0
		bra	hunt
find2		move.b	#"2",d0
		bra	hunt
find3		move.b	#"3",d0
		bra	hunt
find4		move.b	#"4",d0
		bra	hunt
find5		move.b	#"5",d0
		bra	hunt
find6		move.b	#"6",d0
		bra	hunt
find7		move.b	#"7",d0
		bra	hunt
find8		move.b	#"8",d0
		bra	hunt
find9		move.b	#"9",d0
		bra	hunt
findA		move.b	#"A",d0
		bra	hunt
findB		move.b	#"B",d0
		bra	hunt
findC		move.b	#"C",d0
		bra	hunt
findD		move.b	#"D",d0
		bra	hunt
findE		move.b	#"E",d0
		bra	hunt
findF		move.b	#"F",d0
		bra	hunt
findG		move.b	#"G",d0
		bra	hunt
findH		move.b	#"H",d0
		bra	hunt
findI		move.b	#"I",d0
		bra	hunt
findJ		move.b	#"J",d0
		bra	hunt
findK		move.b	#"K",d0
		bra	hunt
findL		move.b	#"L",d0
		bra	hunt
findM		move.b	#"M",d0
		bra	hunt
findN		move.b	#"N",d0
		bra	hunt
findO		move.b	#"O",d0
		bra	hunt
findP		move.b	#"P",d0
		bra	hunt
findQ		move.b	#"Q",d0
		bra	hunt
findR		move.b	#"R",d0
		bra	hunt
findS		move.b	#"S",d0
		bra	hunt
findT		move.b	#"T",d0
		bra	hunt
findU		move.b	#"U",d0
		bra	hunt
findV		move.b	#"V",d0
		bra	hunt
findW		move.b	#"W",d0
		bra	hunt
findX		move.b	#"X",d0
		bra	hunt
findY		move.b	#"Y",d0
		bra	hunt
findZ		move.b	#"Z",d0
		bra	hunt

		nop

hunt		;bsr	mi_FindFirst
		;clr.w	$100
		cmp.w	#-1,d0
		beq.b	.notfound
		move.w	d0,FS_Current
		moveq	#0,d3		; -- offset

		moveq	#0,d1
		move.w	_pt1210_file_count,d1
		sub.w	d0,d1
		cmp.w	#FS_ListMax,d1
		bgt.b	.ok

		move.w	#FS_ListMax,d2
		sub.w	d1,d2
		move.w	d2,d3

.ok		move.w	d3,FS_ListPos
		bsr	FS_DrawDir
		bsr	FS_Copper
.notfound	rts


setbpm		moveq	#0,d0
		move.b	CIABPM,d0
		jsr	CIA_SetBPM
		rts

