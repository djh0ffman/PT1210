
	include exec/memory.i
	include dos/dos.i
	include dos/dos_lib.i
	
ExecBase	= 4
AllocMem	= -$c6
FreeMem 	= -$d2
AvailMem	= -$d8
OpenLib		= -30-378
CloseLib	= -414
Open		= -30
Close		= -36

	; file block definition

		rsreset	
mi_FileSize	rs.l	1
mi_BPM		rs.w	1
mi_Frames	rs.w	1
mi_FileName	rs.b	108	; -- file name
mi_Sizeof	rs.b	0

		; d0 = first char
mi_FindFirst	moveq	#0,d2
		lea	mi_FileList,a0
		move.w	mi_FileCount,d7
		subq.b	#1,d7
.huntloop	moveq	#0,d1
		cmp.l	#"mod.",mi_FileName(a0)	
		bne.b	.skipmod
		move.b	mi_FileName+4(a0),d1
		bra	.comp
.skipmod	move.b	mi_FileName(a0),d1
.comp		cmp.b	#$60,d1
		blo.b	.upper
		sub.b	#$20,d1
.upper		cmp.b	d0,d1
		beq.b	.found
		lea	mi_Sizeof(a0),a0
		addq.w	#1,d2
		dbra	d7,.huntloop		
		moveq	#-1,d2
.found		move.l	d2,d0
		rts
		


mi_SortFileAsc	
		cmp.w	#$1,mi_FileCount
		bgt.b	.go
		rts
.go
		movem.l	d0-a6,-(sp)

.resort
		lea	mi_FileList,a0
		moveq	#0,d7
		moveq	#0,d4			; check if any change
		move.w	mi_FileCount,d7
		subq.w	#2,d7

.nextfile	lea	mi_FileName(a0),a1
		
		lea	mi_Sizeof(a1),a2
		;moveq	#0,d5			; d5 = check		

		bsr	mi_Compare

		cmp.b	#0,d0
		ble.b	.ok

		moveq	#1,d4
		move.l	a0,a1
		lea	mi_Sizeof(a1),a2
		move.w	#mi_Sizeof-1,d3
.swaploop	move.b	(a2),d2
		move.b	(a1),(a2)
		move.b	d2,(a1)
		addq.l	#1,a1
		addq.l	#1,a2
		dbra	d3,.swaploop
		nop				; swap code here...


.ok		lea	mi_Sizeof(a0),a0
		dbra	d7,.nextfile
		
		tst.b	d4
		bne.b	.resort

		movem.l	(sp)+,d0-a6
		rts

mi_SortFileDesc	movem.l	d0-a6,-(sp)

.resort
		lea	mi_FileList,a0
		moveq	#0,d7
		moveq	#0,d4			; check if any change
		move.w	mi_FileCount,d7
		subq.w	#2,d7

.nextfile	lea	mi_FileName(a0),a1
		
		lea	mi_Sizeof(a1),a2
		;moveq	#0,d5			; d5 = check		

		bsr	mi_Compare

		cmp.b	#0,d0
		bge.b	.ok

		moveq	#1,d4
		move.l	a0,a1
		lea	mi_Sizeof(a1),a2
		move.w	#mi_Sizeof-1,d3
.swaploop	move.b	(a2),d2
		move.b	(a1),(a2)
		move.b	d2,(a1)
		addq.l	#1,a1
		addq.l	#1,a2
		dbra	d3,.swaploop
		nop				; swap code here...


.ok		lea	mi_Sizeof(a0),a0
		dbra	d7,.nextfile
		
		tst.b	d4
		bne.b	.resort

		movem.l	(sp)+,d0-a6
		rts

mi_Compare
	cmp.l	#"mod.",(a1)
	bne.b	.skipa
	addq.l	#4,a1
.skipa	cmp.l	#"mod.",(a2)
	bne.b	.skipb
	addq.l	#4,a2
.skipb

.cmp      move.b    (a1)+,d1     ; run until end of string or until
          bsr       lowcase       ; characters differ
          move.b    d1,d0
          move.b    (a2)+,d1
          beq       .done
          bsr       lowcase
          cmp.b     d0,d1
          beq       .cmp

.done     sub.b     d1,d0        ; update condition codes with result
          rts


lowcase   cmp.b     #65,d1       ; check range 'A' to 'Z'
          blo       .noascii
          cmp.b     #90,d1
          bls       .makelow

.noascii  cmp.b     #192,d1      ; 'A' to '?' and ignore '?' 'y' '?' '?' 
          blo       .done
          cmp.b     #222,d1
          bhi       .done
          cmp.b     #215,d1
          beq       .done

.makelow  add.b     #32,d1
.done     rts
		

mi_SortBPMDesc
		movem.l	d0-a6,-(sp)

.resort
		lea	mi_FileList,a0
		moveq	#0,d7
		moveq	#0,d4			; check if any change
		move.w	mi_FileCount,d7
		subq.w	#2,d7

.nextfile	lea	mi_BPM(a0),a1
		
		lea	mi_Sizeof(a1),a2
		moveq	#0,d5			; d5 = check		
		cmp.w	(a1)+,(a2)+
		bgt.b	.lower
		moveq	#1,d5

.lower		tst.b	d5
		bne.b	.ok		
	
		moveq	#1,d4
		move.l	a0,a1
		lea	mi_Sizeof(a1),a2
		move.w	#mi_Sizeof-1,d3
.swaploop	move.b	(a2),d2
		move.b	(a1),(a2)
		move.b	d2,(a1)
		addq.l	#1,a1
		addq.l	#1,a2
		dbra	d3,.swaploop
		nop				; swap code here...


.ok		lea	mi_Sizeof(a0),a0
		dbra	d7,.nextfile
		
		tst.b	d4
		bne.b	.resort

		movem.l	(sp)+,d0-a6
		rts

mi_SortBPMAsc
		movem.l	d0-a6,-(sp)

.resort
		lea	mi_FileList,a0
		moveq	#0,d7
		moveq	#0,d4			; check if any change
		move.w	mi_FileCount,d7
		subq.w	#2,d7

.nextfile	lea	mi_BPM(a0),a1
		
		lea	mi_Sizeof(a1),a2
		moveq	#0,d5			; d5 = check		
		cmp.w	(a1)+,(a2)+
		blo.b	.lower
		moveq	#1,d5

.lower		tst.b	d5
		bne.b	.ok		
	
		moveq	#1,d4
		move.l	a0,a1
		lea	mi_Sizeof(a1),a2
		move.w	#mi_Sizeof-1,d3
.swaploop	move.b	(a2),d2
		move.b	(a1),(a2)
		move.b	d2,(a1)
		addq.l	#1,a1
		addq.l	#1,a2
		dbra	d3,.swaploop
		nop				; swap code here...


.ok		lea	mi_Sizeof(a0),a0
		dbra	d7,.nextfile
		
		tst.b	d4
		bne.b	.resort

		movem.l	(sp)+,d0-a6
		rts

mi_GenList	movem.l	d0-a6,-(sp)
		clr.w	mi_FileCount

		lea	mi_FileList,a4
		bsr	mi_opendos
		tst.l	dosbase
		beq	.quit

		move.l	dosbase,a6
		move.l	#folder,d1
		moveq	#-2,d2
		jsr	_LVOLock(a6)
		move.l	d0,fldlock
		tst.l	d0
		beq.b	.quit	

		move.l	d0,d5
		move.l	dosbase,a6
		move.l	fldlock,d1
		move.l	#fib,d2
		jsr	_LVOExamine(a6)
		tst.l	d0
		beq.b	.quit	
		move.l	d0,d6

.fileloop
		clr.l	(a4)		; set clear 
		move.l	dosbase,a6
		move.l	fldlock,d1
		move.l	#fib,d2
		jsr	_LVOExNext(a6)
		tst.l	d0
		beq.b	.quit

		lea	fib,a1
		lea	8(a1),a2
		
		bsr	mi_CheckFile

.nextfile	cmp.w	#mi_MaxFileCount,mi_FileCount
		blo.b	.fileloop
;		bra	.fileloop
	
.quit
		move.l	fldlock,d1
		jsr	_LVOUnLock(a6)	;-- maybe this might fix it??
		movem.l	(sp)+,d0-a6
		move.w	mi_FileCount,FS_FileCount
		sub.w	#1,FS_FileCount
		rts

		; a1 = fib
		; a2 = filename
mi_CheckFile	movem.l	d0/d1/d2/d3/d4/d5/d6/d7/a0/a1/a2/a3/a5/a6,-(sp)

		move.l	124(a1),d7
		cmp.l	#1190,d7
		ble	.skip

		move.l	d7,(a4)		; store size for later

		move.l	a2,a0
		lea	mi_Tag(pc),a1		
		clr.l	(a1)
		move.l	#$438,d6	; load from start pos
		move.l	#4,d7		; load 4 bytes
		moveq	#0,d0
		bsr	mi_LoadFile

		cmp.l	#"M.K.",(a1)
		beq.w	.go

		cmp.l	#"M!K!",(a1)
		bne.w	.skip
		
.go		move.w	#-1,(a1)
		move.l	#$438-128,d6	; 
		move.l	#1,d7		; load pattern number
		moveq	#0,d0
		bsr	mi_LoadFile

		cmp.w	#-1,(a1)
		beq	.skip

		moveq	#0,d6
		move.b	(a1),d6		; get first pattern
		mulu	#4*4*64,d6	; mulu pat size
		add.l	#$43c,d6	; add header offset
		move.l	#8*4,d7
		lea	mi_PatLine(pc),a1
		bsr	mi_LoadFile

		moveq	#8-1,d7
.loopchan	move.w	2(a1),d1
		move.w	d1,d0
		and.w	#$0f00,d0
		cmp.w	#$0f00,d0
		bne.b	.skipchan

		and.w	#$ff,d1
		cmp.w	#40,d1
		bgt.b	.foundbpm
		
.skipchan	lea	4(a1),a1
		dbra	d7,.loopchan		
		moveq	#0,d1
.foundbpm	tst.w	d1
		bne.b	.nodefault
		move.w	#125,d1

.nodefault	move.w	d1,mi_BPM(a4)		; current base tempo
		clr.w	mi_Frames(a4)
		
		lea	mi_PatLine(pc),a1	; calc beats per frame
		clr.l	(a1)
		move.l	#$398,d6	; load from sample name 31
		move.l	#8,d7		; load 8 bytes
		moveq	#0,d0
		bsr	mi_LoadFile
		move.l	(a1),d0
		and.l	#$ffdfdfdf,d0
		cmp.l	#"!FRM",d0
		bne.b	.noframes
		and.w	#$0f0f,4(a1)
		moveq	#0,d0
		moveq	#0,d1
		move.b	5(a1),d0
		move.b	4(a1),d1
		mulu	#10,d1
		add.w	d1,d0	; frames per beat (now hex)
		tst.w	d0
		beq.b	.noframes
		move.w	d0,mi_Frames(a4)
		move.w	mi_BPM(a4),d1		; current base tempo
		mulu	#24,d1
		divu	d0,d1
		move.w	d1,mi_BPM(a4)		; recalced tempo


.noframes	lea	mi_Sizeof(a4),a5
		lea	mi_FileName(a4),a4

		move.l	(a0),d0
		and.l	#$dfdfdfff,d0
		cmp.l	#"MOD.",d0
		beq.b	.lower
	
		bra	.filename
.lower		move.l	#"mod.",(a0)
		
.filename	move.b	(a0)+,(a4)+
		cmp.l	a4,a5
		bgt.b	.filename
		add.w	#1,mi_FileCount
	
.skip		movem.l	(sp)+,d0/d1/d2/d3/d4/d5/d6/d7/a0/a1/a2/a3/a5/a6
		rts

mi_Tag		dc.l	0		
mi_PatLine	dcb.l	8,0

	;	a0 - filename
	;	a1 - load address
	;	d6 - seek point
	;	d7 - size of data to read
	;	ret d0

mi_LoadFile	
	;clr.w	$100
	movem.l	d1-a6,-(sp)
	move.l	d6,mi_SeekPoint
	move.l	a1,d6
	move.l	dosbase,a6
	move.l	a0,d1
	moveq	#0,d2
	move.w	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)
	move.l	d0,filehd
	tst.l	d0
	beq.b	.loaderror

	move.l	dosbase,a6
	move.l	filehd,d1
	move.l	mi_SeekPoint,d2
	moveq	#OFFSET_BEGINNING,d3
	jsr	_LVOSeek(a6)

	cmp.l	#-1,d0
	beq.b	.loaderror

	move.l	dosbase,a6
	move.l	filehd,d1
	move.l	d6,d2		; load address
	move.l	d7,d3		; load size
	jsr	_LVORead(a6)

	cmp.l	#-1,d0
	beq.b	.loaderror

	move.l	dosbase,a6
	move.l	filehd,d1
	jsr	_LVOClose(a6)
	
	cmp.l	d3,d7
	bne.b	.error

	moveq	#0,d0
	movem.l	(sp)+,d1-a6
	rts

.loaderror
	jsr	_LVOIoErr(a6)
	move.l	d0,-(sp)
	move.l	d0,d1
	move.l	#FS_LoadErrHead,d2
	move.l	#FS_LoadErrBuff,d3
	move.l	#80,d4		
	jsr	_LVOFault(a6)
	move.l	(sp)+,d0

	jsr	FS_DrawLoadError	
	moveq	#-1,d0
	movem.l	(sp)+,d1-a6
	rts

.error	moveq	#-1,d0
	movem.l	(sp)+,d1-a6
	rts

mi_SeekPoint	dc.l	0
	
mi_opendos	movem.l	d0-a6,-(sp)
		move.l	ExecBase,a6
		lea	doslib,a1
		moveq	#0,d0
		jsr	OpenLib(a6)
		move.l	d0,dosbase
		movem.l	(sp)+,d0-a6
		rts



freechip
	movem.l	d1-a6,-(sp)
	move.l	#MEMF_CHIP|MEMF_LARGEST,d1
	move.l	ExecBase,a6
	jsr	AvailMem(a6)
	movem.l	(sp)+,d1-a6
	rts


allocchip
	movem.l	d0-a6,-(sp)
	move.l	memsize,d0
	move.w	#MEMF_CHIP,d1
	move.l	ExecBase,a6
	jsr	AllocMem(a6)
	move.l	d0,memptr
	movem.l	(sp)+,d0-a6
	rts

unallocchip
	movem.l	d0-a6,-(sp)
	move.l	memsize,d0
	move.l	memptr,a1
	beq.b	.noal
	move.l	ExecBase,a6
	jsr	FreeMem(a6)
	clr.l	memptr
	clr.l	memsize
.noal	movem.l	(sp)+,d0-a6
	rts
	
memptr	dc.l	0
memsize	dc.l	0

