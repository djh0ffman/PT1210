
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
mi_FileName	rs.b	108		; -- file name
mi_Name		rs.b	40 		; -- display name
mi_Sizeof	rs.b	0

		; d0 = first char
mi_FindFirst	moveq	#0,d2
		lea	_pt1210_file_list,a0
		move.w	_pt1210_file_count,d7
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
		cmp.w	#$1,_pt1210_file_count
		bgt.b	.go
		rts
.go
		movem.l	d0-a6,-(sp)

.resort
		lea	_pt1210_file_list,a0
		moveq	#0,d7
		moveq	#0,d4			; check if any change
		move.w	_pt1210_file_count,d7
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
		lea	_pt1210_file_list,a0
		moveq	#0,d7
		moveq	#0,d4			; check if any change
		move.w	_pt1210_file_count,d7
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
		lea	_pt1210_file_list,a0
		moveq	#0,d7
		moveq	#0,d4			; check if any change
		move.w	_pt1210_file_count,d7
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
		lea	_pt1210_file_list,a0
		moveq	#0,d7
		moveq	#0,d4			; check if any change
		move.w	_pt1210_file_count,d7
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

