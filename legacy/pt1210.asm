***************************************************************************
*
* PT-1210
*
* ProTracker DJ Player
*
* Credits...
*
* Concept - h0ffman & Akira
* Code - h0ffman
* Graphics - Akira
* Bug testing - Akira
* Startup / Restore Code - Stingray
*
***************************************************************************

;	include exec/execbase.i

SW_Splash = 0		; Include splash screen

	section pt1210,code		



FONTWIDTH = 64

INTENASET	= %1100000000100000

TIMERSET	= %1100000000001000
TIMERCLR	= %0100000000001000
;		   ab-------cdefg--
;	a: SET/CLR Bit
;	b: Master Bit
;	c: Blitter Int
;	d: Vert Blank Int
;	e: Copper Int
;	f: IO Ports/Timers
;	g: Software Int

DMASET		= %1000001111111111
;		   a----bcdefghi--j
;	a: SET/CLR Bit
;	b: Blitter Priority
;	c: Enable DMA
;	d: Bit Plane DMA
;	e: Copper DMA
;	f: Blitter DMA
;	g: Sprite DMA
;	h: Disk DMA
;	i..j: Audio Channel 0-3



***************************************************
*** MACRO DEFINITION				***
***************************************************

WAITBLIT	MACRO
		tst.b	$02(a6)
.\@		btst	#6,$02(a6)
		bne.b	.\@
		ENDM
		

***************************************************
*** CLOSE DOWN SYSTEM - INIT PROGRAM		***
***************************************************

START	bsr	mi_GenList
	
.go	bsr	mi_SortFileAsc	

	movem.l	d0-a6,-(a7)
	move.l	$4.w,a6
	lea	.VARS_HW(pc),a5
	lea	.GFXname(pc),a1
	moveq	#0,d0
	jsr	-552(a6)			; OpenLibrary()
	move.l	d0,.GFXbase-.VARS_HW(a5)
	beq.b	.END
	move.l	d0,a6
	move.l	34(a6),.OldView-.VARS_HW(a5)
	sub.l	a1,a1
	bsr.w	.DoView
	move.l	$26(a6),.OldCop1-.VARS_HW(a5)	; Store old CL 1
	move.l	$32(a6),.OldCop2-.VARS_HW(a5)	; Store old CL 2
	bsr	.GetVBR
	move.l	d0,VBRptr
	move.l	d0,a0

	***	Store Custom Regs	***

	lea	$dff000,a6			; base address
	move.w	$10(a6),.ADK-.VARS_HW(a5)	; Store old ADKCON
	move.w	$1C(a6),.INTENA-.VARS_HW(a5)	; Store old INTENA
	move.w	$02(a6),.DMA-.VARS_HW(a5)	; Store old DMA
	move.w	#$7FFF,d0
	bsr	WaitRaster
	move.w	d0,$9A(a6)			; Disable Interrupts
	move.w	d0,$96(a6)			; Clear all DMA channels
	move.w	d0,$9C(a6)			; Clear all INT requests

	move.l	$6c(a0),.OldVBI-.VARS_HW(a5)
	lea	.NewVBI(pc),a1
	move.l	a1,$6c(a0)

	move.w	#INTENASET!$C000,$9A(a6)	; set Interrupts+ BIT 14/15
	move.w	#DMASET!$8200,$96(a6)		; set DMA	+ BIT 09/15
	bsr	MAIN

	
***************************************************
*** Restore Sytem Parameter etc.		***
***************************************************

.END	lea	.VARS_HW(pc),a5
	lea	$dff000,a6
	clr.l	VBIptr-.VARS_HW(a5)

	move.w	#$8000,d0
	or.w	d0,.INTENA-.VARS_HW(a5)		; SET/CLR-Bit to 1
	or.w	d0,.DMA-.VARS_HW(a5)		; SET/CLR-Bit to 1
	or.w	d0,.ADK-.VARS_HW(a5)		; SET/CLR-Bit to 1
	subq.w	#1,d0
	bsr	WaitRaster
	move.w	d0,$9A(a6)			; Clear all INT bits
	move.w	d0,$96(a6)			; Clear all DMA channels
	move.w	d0,$9C(a6)			; Clear all INT requests

	move.l	VBRptr(pc),a0
	move.l	.OldVBI(pc),$6c(a0)

	move.l	.OldCop1(pc),$80(a6)		; Restore old CL 1
	move.l	.OldCop2(pc),$84(a6)		; Restore old CL 2
	move.w	d0,$88(a6)			; start copper1
	move.w	.INTENA(pc),$9A(a6)		; Restore INTENA
	move.w	.DMA(pc),$96(a6)		; Restore DMAcon
	move.w	.ADK(pc),$9E(a6)		; Restore ADKcon

	move.l	.GFXbase(pc),a6
	move.l	.OldView(pc),a1			; restore old viewport
	bsr.b	.DoView

	move.l	a6,a1
	move.l	$4.w,a6
	jsr	-414(a6)			; Closelibrary()
	movem.l	(a7)+,d0-a6
	moveq	#0,d0
	rts


.DoView	jsr	-222(a6)			; LoadView()
	jsr	-270(a6)			; WaitTOF()
	jmp	-270(a6)


*******************************************
*** Get Address of the VBR		***
*******************************************

.GetVBR	move.l	a5,-(a7)
	moveq	#0,d0			; default at $0
	move.l	$4.w,a6
	btst	#0,296+1(a6)		; 68010+?
	beq.b	.is68k			; nope.
	lea	.getit(pc),a5
	jsr	-30(a6)			; SuperVisor()
.is68k	move.l	(a7)+,a5
	rts

.getit	;movec   vbr,d0
	dc.l	$4e7a0801
	rte				; back to user state code
	

*******************************************
*** VERTICAL BLANK (VBI)		***
*******************************************

.NewVBI	movem.l	d0-a6,-(a7)
	;lea	$dff09c,a6
	;moveq	#$20,d0
	;move.w	d0,(a6)
	;move.w	d0,(a6)			; twice to avoid a4k hw bug
	
	move.l	VBIptr(pc),d0
	beq.b	.noVBI
	move.l	d0,a0
	jsr	(a0)
.noVBI	lea	$dff09c,a6
	moveq	#$20,d0
	move.w	d0,(a6)
	move.w	d0,(a6)			; twice to avoid a4k hw bug
	movem.l	(a7)+,d0-a6
	rte

*******************************************
*** DATA AREA		FAST		***
*******************************************

.VARS_HW
.GFXname	dc.b	'graphics.library',0,0
.GFXbase	dc.l	0
.OldView	dc.l	0
.OldCop1	dc.l	0
.OldCop2	dc.l	0
.VBRptr		dc.l	0
.OldVBI		dc.l	0
.ADK		dc.w	0
.INTENA		dc.w	0
.DMA		dc.w	0

VBIptr		dc.l	0
VBRptr		dc.l	0

WaitRaster
	move.l	d0,-(a7)
.loop	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.b	.loop
	move.l	(a7)+,d0
	rts

WaitRasterMid
	move.l	d0,-(a7)
.loop	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#100<<8,d0
	bne.b	.loop
	move.l	(a7)+,d0
	rts

WaitRasterEnd
	move.l	d0,-(a7)
.loop	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	beq.b	.loop
	move.l	(a7)+,d0
	rts


*****************************************
** keyboard system
*****************************************

	include cia.i
	include intbits.i

kbinit	movem.l	d0-a6,-(a7)
	move.l	VBRptr,a0
	move.l	$68(a0),oldint
	move.b	#CIAICRF_SETCLR|CIAICRF_SP,(ciaicr+$bfe001)
	;clear all ciaa-interrupts
	tst.b	(ciaicr+$bfe001)
	;set input mode
	and.b	#~(CIACRAF_SPMODE),(ciacra+$bfe001)
	;clear ports interrupt
	move.w	#INTF_PORTS,(intreq+$dff000)
	;allow ports interrupt
	move.l	#kbint,$68(a0)
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,(intena+$dff000)
	movem.l	(a7)+,d0-a6
	rts

kbrem	movem.l	d0-a6,-(a7)
	move.l	VBRptr,a0
	move.w	#INTF_SETCLR|INTF_PORTS,(intena+$dff000)
	move.l	oldint,$68(a0)
	movem.l	(a7)+,d0-a6
	rts	

kbint	movem.l	d0-d1/a0-a2,-(a7)
	
	lea	$dff000,a0
	move.w	intreqr(a0),d0
	btst	#INTB_PORTS,d0
	beq	.end
		
	lea	$bfe001,a1
	btst	#CIAICRB_SP,ciaicr(a1)
	beq	.end

	;read key and store him
	move.b	ciasdr(a1),d0
	or.b	#CIACRAF_SPMODE,ciacra(a1)
	not.b	d0
	ror.b	#1,d0
	spl	d1
	and.w	#$7f,d0
	lea	keys(pc),a2
	move.b	d1,(a2,d0.w)

;	clr.w	$100		;-- hello debugger

	;handshake
	moveq	#3-1,d1
.wait1	move.b	vhposr(a0),d0
.wait2	cmp.b	vhposr(a0),d0
	beq	.wait2
	dbf	d1,.wait1

	;set input mode
	and.b	#~(CIACRAF_SPMODE),ciacra(a1)

.end	move.w	#INTF_PORTS,intreq(a0)
	tst.w	intreqr(a0)
	movem.l	(a7)+,d0-d1/a0-a2
	rte

keys: 		dcb.b $80,0
keys2: 		dcb.b $80,0
keysfr: 	dcb.b $80,0


oldint	dc.l	0




	include exec/memory.i
	include dos.i
	include dos_lib.i
	
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



************************************
** The mega mod player by h0ffman **
************************************

	include	"custom.i"


		ifne	SW_Splash
splashkill	movem.l	d0-a6,-(sp)
		lea	splashgo-8,a1
		move.l	(a1),d0
		clr.l	nope-4
		move.l	ExecBase,a6
		jsr	FreeMem(a6)
		movem.l	(sp)+,d0-a6
		rts

		endc
MAIN		
		ifne	SW_Splash
		jsr	splashgo
		bsr	splashkill
		endc
		
		moveq	#1,d0
		bsr	FS_DrawType


		movem.l	d0-a6,-(sp)

		bsr	FS_DrawDir
		bsr	FS_Copper
		bsr	PT_Prep
		
		bsr	UI_DrawChip

		bsr	kbinit

		move.l	VBRptr,a0
		lea	$dff000,a6
		move.l	#1773447,d0
		jsr	CIA_AddCIAInt
		
		bsr	ScopeInit
		move.l	#VBInt,VBIptr		; set VB Int pointer
		
		lea	$dff000,a6		; hw base

		move.l	#_hud,d0		; load plane to copper
		lea	_hud_planes,a0		
		moveq	#5-1,d7
.hudloop	move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		add.l	#40,d0
		addq.l	#8,a0
		dbra	d7,.hudloop

		move.l	#_track,d0		; load plane to copper
		lea	_track_planes,a0		
		moveq	#3-1,d7
.trackloop	move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		add.l	#40,d0
		addq.l	#8,a0
		dbra	d7,.trackloop

		move.l	#_song_grid,d0		; load plane to copper
		lea	_grid_planes1,a0		
		lea	_grid_planes2,a1
		move.w	d0,6(a0)
		move.w	d0,6(a1)
		swap	d0
		move.w	d0,2(a0)
		move.w	d0,2(a1)

		moveq	#3-1,d7
		move.l	#_track_fill,d0		; load plane to copper
		lea	_track_plane,a0		
.tloop		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		lea	8(a0),a0
		add.l	#40,d0
		dbra	d7,.tloop

		move.l	#_song_grid_clr,d0		; load plane to copper
		lea	_grid_planes1c,a0		
		lea	_grid_planes2c,a1
		lea	_cScopeSpace,a2
		move.w	d0,6(a0)
		move.w	d0,6(a1)
		move.w	d0,6(a2)
		swap	d0
		move.w	d0,2(a0)
		move.w	d0,2(a1)
		move.w	d0,2(a2)


		lea	_hud_sprites,a0
		lea	_spritelist,a1
		moveq	#8-1,d7
		
.sprloop	move.l	(a1)+,d0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		addq.l	#8,a0
		dbra	d7,.sprloop

		move.l	#_select,d0		; load plane to copper
		lea	_select_planes,a0		
		moveq	#2-1,d7
.selectloop	move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		swap	d0
		add.l	#40,d0
		addq.l	#8,a0
		dbra	d7,.selectloop

		move.l	#_selectfilla,d0		; load plane to copper
		lea	_filla_planes,a0		
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)

		move.l	#_dir,d0
		addq.l	#8,a0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)
		
		move.l	#_selectfillb,d0
		addq.l	#8,a0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)


		move.l	#_song_grid_clr,d0		; load plane to copper
		lea	_cscreen,a0		
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)



		move.l	#_hud_cop,cop1lc(a6)					
		move.l	#_select_cop,cop2lc(a6)


.lp 		tst.b	FS_DoLoad
		beq.b	.skipload
		clr.b	FS_DoLoad
		bsr	kbrem
		bsr	FS_LoadTune
		bsr	kbinit
.skipload

		tst.b	FS_DoScan
		beq.b	.skipscan
		clr.b	FS_DoScan
		bsr	kbrem
		bsr	FS_Rescan
		bsr	kbinit
.skipscan



		tst.w	quitmeplease
		beq.b	.lp

;		btst    #6,$bfe001
;	        bne.s   .lp      	

		jsr	CIA_RemCIAInt
	        jsr	mt_end
		bsr	unallocchip

		bsr	kbrem
	        
	        movem.l	(sp)+,d0-a6
	    	rts

; ************* CIA Int

CIA_CIAInt	movem.l	d0-a6,-(sp)
		tst.b	mt_TuneEnd
		bne.b	.skip
		jsr	mt_music
		
		tst.b	repitch
		beq.b	.skip
		jsr	mt_retune

.skip		tst.b	mt_TuneEnd
		beq.b	.skip2
		jsr	mt_end
		clr.b	mt_Enabled
		clr.b	mt_TuneEnd
.skip2		movem.l	(sp)+,d0-a6
		rts

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

; ********* WHATS THE FUCKING TIME!!!

DOTIME		tst.b	mt_Enabled
		beq.b	.out
		tst.b	mt_TuneEnd
		bne.b	.out

		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		
		lea	Time_Frames(pc),a0
		lea	Time_Seconds(pc),a1
		lea	Time_Minutes(pc),a2
		lea	Time_FPS(pc),a3		
		move.b	(a0),d0
		move.b	(a1),d1
		move.b	(a2),d2

		add.b	#1,d0
		cmp.b	(a3),d0
		blo.b	.quit
		moveq	#0,d0
		addq.b	#1,d1		; add second
		cmp.b	#60,d1
		blo.b	.quit
		moveq	#0,d1
		addq.b	#1,d2
		cmp.b	#99,d2
		blo.b	.quit
		moveq	#0,d2
		
.quit		move.b	d0,(a0)
		move.b	d1,(a1)
		move.b	d2,(a2)
.out		rts

Time_FPS	dc.b	50
Time_Frames	dc.b	0
Time_Seconds	dc.b	0
Time_Minutes	dc.b	0

; ******************************************
; ********* NEW UI CODE
; ******************************************


UI_CuePos	moveq	#0,d0
		moveq	#0,d1
		move.b	mt_PatternCue,d0
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
		move.b	mt_SongLen,d0
;		MOVE.L	mt_SongDataPtr,A0
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
		MOVE.L	mt_SongDataPtr,A0
		cmp.l	d0,a0
		beq.b	.quit
		move.b	950(A0),D0	; max patterns
		
		moveq	#0,d1
		move.b	mt_SongPos,d1	; current pattern

		moveq	#0,d2
		move.w	mt_PatternPos,d2

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
		tst.b	patslipflag
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

UI_BPMFine	lea	BPMFINE,a3
		lea	UI_BPMFINE,a4
		moveq	#0,d0
		move.b	(a3),d0
		cmp.b	(a4),d0
		beq.b	.skip
		move.b	d0,(a4)


		move.w	ACTUALBPM,d0
		lsl.w	#4,d0

		move.w	FRAMES,d1
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

UI_BPMDiff	lea	UI_BPMCent,a0
		move.b	#"+",(a0)
		lea	ACTUALBPM,a3
		lea	UI_ActualBPM,a4
		moveq	#0,d0
		move.w	(a3),d0
		cmp.w	(a4),d0
		beq.b	.skip
		move.w	d0,(a4)
		
 		moveq	#0,d1
		move.b	CIABPM,d1
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
.pos		and.l	#$ff,d0

		move.w	#(UI_TotWidth*32)+37,d5	; screen pos
		moveq	#3-1,d6			; num chars
		bsr	UI_Decimal
		bsr	UI_ValType

		lea	UI_BPMCent,a0
		move.w	#(UI_TotWidth*32)+34,d5	; screen pos
		moveq	#0,d4
		bsr	UI_TypeSmall

.skip		


UI_TrackBPM	lea	CIABPM,a3
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

UI_SpeedText	lea	mt_speed,a3
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


UI_SlipText1	lea	mt_SLSongPos,a3
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

UI_SlipText2	lea	mt_SLPatternPos,a3
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
		sub.w	#$20,d2
		lea	(a5,d2.w),a2		; font point
.charloop	move.b	(a2),(a3)
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),(a3)
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),(a3)
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),(a3)
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	UI_TotWidth(a3),a3
		move.b	(a2),(a3)
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	UI_TotWidth(a3),a3
;		dbra	d7,.charloop
		lea	-1(a0),a0
		ror.w	#4,d1
		dbra	d6,.valueloop
		rts

UI_SpritePos	
		movem.l	d0-a6,-(sp)
		lea	UI_TrackPosPix(pc),a1
		moveq	#0,d0

		moveq	#0,d6
		move.b	mt_PatternLock,d6

		moveq	#0,d1
		lea	_spritelefttop,a0
		lea	_spriteleftbot,a2
		move.b	mt_PatLockStart,d1
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
		move.b	mt_PatLockEnd,d1
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
		lea	_font_big,a5
		moveq	#20-1,d4
		bsr	UI_Type						

		lea	howmuch(pc),a0
		lea	_hud+2,a1
		lea	22(a1),a4
		lea	_font_big,a5
		moveq	#20-1,d4
		bsr	UI_TypeOR					
		movem.l	(sp)+,d0-a6
		rts


UI_DrawTitle	movem.l	d0-a6,-(sp)
		move.l	mt_SongDataPtr,a0
		lea	_hud+42,a1
		lea	_font_big,a5
		moveq	#20-1,d4
		bsr	UI_Type						

		move.l	mt_SongDataPtr,a0
		lea	_hud+2,a1
		lea	22(a1),a4
		lea	_font_big,a5
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
UI_TypeSmall	lea	(a6,d5.w),a1
		lea	_font_small,a5

;.nextline	moveq	#39,d4		; line loop

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
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3
		move.b	(a2),(a3)
		move.b	(a2),40(a3)
		lea	FONTWIDTH(a2),a2
		lea	(UI_TotWidth)(a3),a3

		lea	1(a1),a1
		dbra	d4,.nextchar
		
;		lea	(UI_TotWidth*7)(a1),a1		; next plane line
;		dbra	d7,.nextline
		rts



		; A0 = TEXT
		; A1 = SCREEN
		; A5 = FONT
		; D7 = Num Lines
		; D4 = Number of Chars
UI_Type		;lea	font,a5

;.nextline	moveq	#39,d4		; line loop

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
		
;		lea	(UI_TotWidth*7)(a1),a1		; next plane line
;		dbra	d7,.nextline
		rts

UI_TypeOR	;lea	font,a5

;.nextline	moveq	#39,d4		; line loop

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
		
;		lea	(UI_TotWidth*7)(a1),a1		; next plane line
;		dbra	d7,.nextline
		rts



; 34 = bpm last
; digits on line 38

UI_Width	= 40
UI_Planes	= 5
UI_TotWidth	= UI_Width*UI_Planes

UI_DigiLine	= UI_TotWidth*38

UI_TogStart	= UI_TotWidth*16

UI_RepitchLoc	= UI_TogStart+38

UI_Draw		movem.l	d0-a6,-(sp)



.skip

UI_ALL		lea	$dff000,a6
		
		lea	_hud+UI_TogStart,a0		; a0 = dest source
		
		lea	_hud_on,a1	; hudon
		lea	_hud_off,a2	; hudoff

		; REPITCH
UI_RPDraw	moveq	#0,d0
		move.w	#38,d5		; pos onscreen
		move.w	#20,d6			; pos in lights
		lea	repitch,a3
		lea	UI_Repitch,a4
		bsr	UI_CompBlit

		; LineLoop on off
UI_LPDraw	moveq	#0,d0
		move.w	#4,d5			; pos onscreen
		move.w	#0,d6			; pos in lights
		lea	loopactive,a3
		lea	UI_LoopActive,a4
		bsr	UI_CompBlit

		; slip
UI_SlipDraw	moveq	#0,d0
		move.w	#22,d5			; pos onscreen
		move.w	#14,d6			; pos in lights
		lea	slipon,a3
		tst.b	(a3)
		beq.b	.skip

		tst.b	loopactive
		bne.b	.skip

		move.b	mt_SongPos,mt_SLSongPos
		move.w	mt_PatternPos,mt_SLPatternPos

.skip		lea	UI_SlipOn,a4
		bsr	UI_CompBlit


		; slip
UI_PatLockDraw	moveq	#0,d0
		move.w	#28,d5			; pos onscreen
		move.w	#16,d6			; pos in lights
		lea	mt_PatternLock,a3
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
		lea	loopsize,a3
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
		
		lea	chantog,a3
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

		
UI_BPMDrawDigi	lea	CURBPM,a3
		lea	UI_CurBPM,a4
		move.w	(a3),d0
		cmp.w	(a4),d0
		beq.b	.skip
		move.w	d0,(a4)

		move.w	FRAMES,d1
		beq.b	.skipframe
		
		move.w	ACTUALBPM,d0
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


UI_SecDraw	lea	Time_Seconds,a3
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

UI_MinDraw	lea	Time_Minutes,a3
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


UI_PatPosDraw	lea	mt_PatternPos,a3
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

UI_SongPosDraw	lea	mt_SongPos,a3
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

; *******************************************
; ******************** CONTROLS!!!!!!!!!!!!
; *******************************************

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

sortbpm		tst.w	sortbpmtog
		bne.b	.desc
		bsr	mi_SortBPMAsc
		move.w	#1,sortbpmtog
		bra	.done
		
.desc		bsr	mi_SortBPMDesc
		move.w	#0,sortbpmtog
		
.done		bsr	FS_DrawDir
		rts

sortbpmtog	dc.w	0

sortfile	tst.w	sortfiletog
		bne.b	.desc
		bsr	mi_SortFileAsc
		move.w	#1,sortfiletog
		bra	.done
		
.desc		bsr	mi_SortFileDesc
		move.w	#0,sortfiletog
		
.done		bsr	FS_DrawDir
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

hunt		bsr	mi_FindFirst
		;clr.w	$100
		cmp.w	#-1,d0
		beq.b	.notfound
		move.w	d0,FS_Current
		moveq	#0,d3		; -- offset

		moveq	#0,d1
		move.w	mi_FileCount,d1
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





*********************************************
** File Selecta
*********************************************


FS_CurrentType	dc.b	0
		even
		
FS_SwitchType	moveq	#0,d0
;		clr.w	$100
		move.b	FS_CurrentType,d0
		tst.b	d0
		beq.b	.kb
		moveq	#0,d0
		bra.b	.go
.kb		moveq	#1,d0
.go		move.b	d0,FS_CurrentType
		bsr	FS_DrawType
		bsr	FS_DrawDir
		rts

		; d0 = 0 = BPM / 1 = KB
		
FS_DrawType	moveq	#0,d0
		move.b	FS_CurrentType,d0
		lea	_bpm,a0
		tst.b	d0
		beq.b	.gobpm
		lea	_kb,a0
.gobpm		lea	_select,a1
		lea	(40*5)-4(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
		move.l	(a0)+,(a1)
		lea	40(a1),a1
	
		rts

FS_Clear	lea	_dir,a0
		lea	_dirend,a1
.clr		clr.w	(a0)+
		cmp.l	a1,a0
		blo.b	.clr
		
		lea	FS_FileList,a0
		lea	FS_FileListEnd,a1
.clr2		clr.w	(a0)+
		cmp.l	a1,a0
		blo.b	.clr2

		rts
		
		; d5 = type (0 bpm / 1 =kb)

FS_DrawDir	cmp.w	#$0,mi_FileCount
		bne.b	.go
		bra	FS_DrawNoMods
		
.go		moveq	#0,d5
		move.b	FS_CurrentType,d5
		lea	FS_FileList,a0
		lea	mi_FileList,a1
		moveq	#0,d0
		move.w	FS_Current,d0
		sub.w	FS_ListPos,d0
		mulu	#mi_Sizeof,d0
		add.l	d0,a1
		
		moveq	#FS_ListMax-1,d7	; max file count...
.loop		lea	mi_FileName(a1),a2
		tst.b	(a2)
		beq	.quit		
		moveq	#36-1,d6	; char count
		move.l	a0,a3
		cmp.l	#"mod.",(a2)
		bne.b	.skipmod
		addq.l	#4,a2
.skipmod		
.charloop	tst.b	(a2)
		beq.b	.ended
		move.b	(a2)+,(a3)+
		bra.b	.doloop
.ended		move.b	#$20,(a3)+
.doloop		dbra	d6,.charloop	

		tst.b	d5
		bne.b	.kb

		moveq	#0,d0
		move.w	mi_BPM(a1),d0
		moveq	#3-1,d2
		lea	3(a3),a3
		
.bpmconv	divu.w	#10,d0
		swap	d0
		add.b	#"0",d0
		move.b	d0,-(a3)
		clr.w	d0
		swap	d0
		dbra	d2,.bpmconv
		bra	.nextfile
		
.kb		move.l	mi_FileSize(a1),d0
		divu	#1024,d0
		and.l	#$ffff,d0
		moveq	#6-1,d2
		lea	3(a3),a3
				
.kbconv		divu.w	#10,d0
		swap	d0
		add.b	#"0",d0
		move.b	d0,-(a3)
		clr.w	d0
		swap	d0
		dbra	d2,.kbconv

		moveq	#6-1,d2
.tidy		cmp.b	#"0",(a3)+
		bne.b	.quitzero
		move.b	#" ",-1(a3)
		dbra	d2,.tidy

.quitzero
		
.nextfile	lea	40(a0),a0
		lea	mi_Sizeof(a1),a1
		tst.l	(a1)
		beq.b	.quit
		dbra	d7,.loop
.quit
		; all done now draw...
		lea	FS_FileList,a0
		lea	_dir+80,a1
		moveq	#FS_ListMax-1,d7		; number of lines
		bsr	ST_Type
;		bsr	FS_Copper
		rts


FS_Copper	cmp.w	#$0,mi_FileCount
		bgt.b	.go
		bsr	FS_CopperClr
		rts
		
.go		movem.l	d0-a6,-(sp)
		moveq	#0,d0
		move.w	FS_ListPos,d0
		move.w	#FS_ListMax-1,d7
		lea	_selectaline,a0
.loop		clr.w	6(a0)
		tst.w	d0
		bne.b	.skip
		nop
		move.w	#$00f,6(a0)
			
.skip		subq.w	#1,d0
		lea	_selectasize(a0),a0
		dbra	d7,.loop
		movem.l	(sp)+,d0-a6
		rts
		


FS_CopperClr	movem.l	d0-a6,-(sp)
		moveq	#0,d0
		move.w	#FS_ListMax-1,d7
		lea	_selectaline,a0
.loop		clr.w	6(a0)
		lea	_selectasize(a0),a0
		dbra	d7,.loop
		movem.l	(sp)+,d0-a6
		rts
		

FS_MoveDown	moveq	#1,d2
		bra	FS_Move
		
FS_MoveUp	moveq	#-1,d2
		bra	FS_Move
		

		; d2 = add value
FS_Move		lea	FS_Current(pc),a0
		lea	FS_ListPos(pc),a1
		move.w	(a0),d0
		move.w	(a1),d1
		move.w	FS_FileCount,d3		; total
		move.w	#FS_ListMax-1,d4		; total on screen

		cmp.w	d3,d4
		blo.b	.lessthan
		move.w	d3,d4
		

.lessthan	add.w	d2,d0		
		cmp.w	#0,d0
		bge.b	.skiplow_a
		moveq	#0,d0
		bra.b	.skiphi
.skiplow_a	cmp.w	d3,d0
		blo.b	.skiphi
		move.w	d3,d0
.skiphi		move.w	d0,(a0)
				

		add.w	d2,d1		
		cmp.w	#0,d1
		bge.b	.skiplow_b
		moveq	#0,d1
		bra.b	.skiphi_b
.skiplow_b	cmp.w	d4,d1
		blo.b	.skiphi_b
		move.w	d4,d1
.skiphi_b	move.w	d1,(a1)
		
		bsr	FS_DrawDir	

.skipdraw	bsr	FS_Copper

		rts

FS_Rescan	movem.l	d0-a6,-(sp)
		
		clr.b	mt_Enabled	; stop the current track
		jsr	mt_end
		move.b	#1,VBDisable		
		jsr	ScopeStop

		clr.w	FS_Current
		clr.w	FS_ListPos

		bsr	FS_Clear
		bsr	FS_CopperClr
		
		
		bsr	CIA_RemCIAInt	
		move.w	#TIMERSET!$C000,$9A(a6)	; set Interrupts+ BIT 14/15

		bsr	mi_GenList	
		move.w	#TIMERCLR!$C000,$9A(a6)	; set Interrupts+ BIT 14/15

		bsr	CIA_AddCIAInt	
		jsr	mi_SortFileAsc	

		bsr	FS_DrawDir
		bsr	FS_Copper

		clr.b	VBDisable

		movem.l	(sp)+,d0-a6
		rts

FS_LoadTune	movem.l	d0-a6,-(sp)
		
		clr.b	mt_Enabled	; stop the current track
		
		jsr	mt_end

		move.b	#1,VBDisable
		
		jsr	ScopeStop

		move.w	#TIMERSET!$C000,$9A(a6)	; set Interrupts+ BIT 14/15

		bsr	unallocchip

		moveq	#0,d0
		move.w	FS_Current,d0
		mulu	#mi_Sizeof,d0
		lea	mi_FileList,a0
		add.l	d0,a0
		move.l	mi_FileSize(a0),memsize
		move.w	mi_Frames(a0),FRAMES
		lea	mi_FileName(a0),a0
		move.l	a0,a6
		tst.l	memsize
		beq	.error
		bsr	allocchip
		tst.l	memptr
		beq.b	.memerror
		moveq	#0,d0	
	
		move.l	a6,a0
		move.l	memptr,a1
		moveq	#0,d6		; seek
		move.l	memsize,d7
		bsr	mi_LoadFile		
		tst.l	d0
		bne.b	.quit
		
		move.l	memptr,a0
		jsr	mt_init		

		bsr	FS_Reset


		bsr	switch

		move.b	#1,mt_Enabled
		
.quit		clr.b	FS_DoLoad
		move.w	#TIMERCLR!$C000,$9A(a6)	; set Interrupts+ BIT 14/15
		clr.b	VBDisable
		movem.l	(sp)+,d0-a6
		rts

.memerror	bsr	FS_DrawOutRam
		bra.b	.quit

.error		bsr	unallocchip
		jsr	FS_DrawError
		bra	.quit		



FS_Reset	move.b	#125,CIABPM
		;clr.w	FRAMES
		clr.w	OFFBPM
		clr.b	BPMFINE
		move.w	#%0000000000001111,chantog

		move.b #4,loopsize	
		move.b #0,loopactive	
		move.b #0,loopstart		
		move.b #0,loopend		
	
		move.b #0,patslipflag	
		move.b #0,patslippat	
		move.b	#1,slipon
		move.b	#1,repitch
		clr.b	mt_TuneEnd
		move.b	#0,mt_PatternLock
		move.b	#0,mt_PatLockStart
		move.b	#0,mt_PatLockEnd
		move.b	#0,mt_PatternCue
		clr.b	Time_Frames
		clr.b	Time_Seconds
		clr.b	Time_Minutes

		clr.b	mt_SLSongPos
		clr.w	mt_SLPatternPos

		move.b	#-1,PT_PrevPat
		bsr	PT_DrawPat2
		bsr	UI_DrawTitle
		jsr	UI_TrackDraw

		move.b	#-1,UI_PatternCue
		move.b	#-1,UI_BPMFINE
	
		jsr	UI_CuePos

		rts

FS_ListMax	=	21
FS_FileCount	dc.w	0
FS_Current	dc.w	0
FS_ListPos	dc.w	0
FS_DoLoad	dc.b	0
FS_DoScan	dc.b	0
		even

			;0000000000111111111122222222223333333333
			;0123456789012345678901234567890123456789
FS_FileList	rept	FS_ListMax
		dc.b	"                                        "
		endr		
FS_FileListEnd

FS_DrawError	bsr	FS_CopperClr
		lea	FS_Error,a0
		lea	_dir+80,a1
		lea	10*7*40(a1),a1
		moveq	#5-1,d7		; number of lines
		bsr	ST_Type
		rts

FS_DrawNoMods	bsr	FS_CopperClr
		lea	FS_NoMods,a0
		lea	_dir+80,a1
		lea	10*7*40(a1),a1
		moveq	#5-1,d7		; number of lines
		bsr	ST_Type
		rts
		
FS_DrawOutRam	bsr	FS_CopperClr
		lea	FS_OutRam,a0
		lea	_dir+80,a1
		lea	10*7*40(a1),a1
		moveq	#5-1,d7		; number of lines
		bsr	ST_Type
		rts

		; d0 = load error code
FS_DrawLoadError
		;clr.w	$100
		lea	FS_LoadErrCode+32,a0
		lea	PT_HexList,a1
		moveq	#8-1,d7		; all d0

.code		moveq	#0,d1
		move.b	d0,d1
		and.b	#$f,d1
		move.b	(a1,d1.w),d1
		move.b	d1,-(a0)
		lsr.l	#4,d0
		dbra	d7,.code

		bsr	FS_CopperClr
		lea	FS_LoadError,a0
		lea	_dir+80,a1
		lea	10*7*40(a1),a1
		moveq	#5-1,d7		; number of lines
		bsr	ST_Type
		rts


FS_CopClear	
		rts
			;0000000000111111111122222222223333333333
			;0123456789012345678901234567890123456789
FS_OutRam	dc.b	"--------------------------------------- "
		dc.b	"                                        "
		dc.b	"           NOT ENOUGH MEMORY            "
		dc.b	"                                        "
		dc.b	"--------------------------------------- "


FS_NoMods	dc.b	"--------------------------------------- "
		dc.b	"                                        "
		dc.b	"            NO MODULES FOUND            "
		dc.b	"                                        "
		dc.b	"--------------------------------------- "

			;0000000000111111111122222222223333333333
			;0123456789012345678901234567890123456789
FS_LoadError	dc.b	"--------------------------------------- "
FS_LoadErrCode	dc.b	"       LOADING ERROR : $00000000        "
FS_LoadErrBuff	dc.b	"                                        "
		dc.b	"                                        "
		dc.b	"--------------------------------------- "


FS_LoadErrHead	dc.b	0,0

FS_Error	dc.b	"--------------------------------------- "
		dc.b	"                                        "
		dc.b	"          UNSPECIFIED ERROR!            "
		dc.b	"                                        "
		dc.b	"--------------------------------------- "


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
		tst.b	mt_Enabled
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

ScopeD	move.w	chantog,d4
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




;------------------------------------------------------------------------------
;
;	$VER: CIA Shell Hardware v1.1 - by H�vard "Howard" Pedersen
;	� 1994-96 Mental Diseases
;
;	A hardware-banging CIA-shell
;
;	I cannot be held responsible for any damage caused directly or in-
;	directly by this code. Still, every released version is thouroughly
;	tested with Mungwall and Enforcer, official Commodore debugging tools.
;	These programs traps writes to unallocated ram and reads/writes to/from
;	non-ram memory areas, which should cover most bugs.
;
;	HISTORY:
;
;v1.0	Simple thingy that worked with ProPruner only. Pretty nasty and thrown
;	together for the musicdisk "Hypnophone" by Compact.
;
;v1.1	Compatibility fix. Rewritten for less label confusion and compatibility
;	with my ProTracker replay.
;
;------------------------------------------------------------------------------
;
;	PUBLIC FUNCTIONS:
;
;Function:	CIA_AddCIAInt(CIASeed, VBR) (D0,A0)
;Purpose:	Attaches our interrupt to the CIAB chip, timer A. CIASeed:
;		PAL = 1773447 and NTSC = 1789773.
;
;Function:	CIA_RemCIAInt()
;Purpose:	Removes our interrupt from the CIAB chip, timer B.
;
;Function:	CIA_IntCode()
;Purpose:	Our CIA interrupt. Only callable from within an CIA interrupt.
;
;Function:	CIA_SetBPM(BPM)(D0.B)
;Purpose:	Adjusts the tempo of the current module.
;
;
;	EXTERNAL FUNCTIONS:
;
;Function:	CIA_CIAInt()
;Purpose:	Does any thingies that are necessary to perform within a CIA
;		interrupt. May trash any register.
;
;------------------------------------------------------------------------------

; Constants. Feel free to change if you know what you're doing.

CIA_CIABase	=	$bfd000
CIA_CIAVector	=	$78

;------------------------------------------------------------------------------
;			C I A _ A D D C I A I N T
;------------------------------------------------------------------------------
CIA_AddCIAInt	move.l	d0,CIA_CIASeed
		move.l	a0,CIA_VBR
		lea.l	$dff000,a6

		move.l	CIA_CIASeed,d0
		divu.w	#125,D0 		; Defaults to 125 BPM

		move.b	d0,CIA_TimerLo
		lsr.w	#8,d0
		move.b	d0,CIA_TimerHi
	
		move.l	CIA_VBR,a0
		move.l	CIA_CIAVector(a0),CIA_OldIntCode
		move.l	#CIA_IntCode,CIA_CIAVector(a0); Set interrupt vector

		lea.l	CIA_CIABase,a0

		move.b	#$7f,$d00(a0)		; Stop all

		move.b	$e00(a0),d0
		and.b	#%11000000,d0
		or.b	#%00001011,d0
		move.b	d0,$e00(a0)

		move.b	CIA_TimerLo,$400(a0)	; Set delay
		move.b	CIA_TimerHi,$500(a0)
		move.w	#$a000,$9a(a6)		; Enable CIA interrupt (Level6)

		move.b	#$81,$d00(a0)		; Start

		rts

;------------------------------------------------------------------------------
;			C I A _ R E M C I A I N T
;------------------------------------------------------------------------------
CIA_RemCIAInt	lea.l	$dff000,a6
		move	#$2000,$9a(a6)		; Disable CIA int.

		lea	CIA_CIABase,a0
		move.b	#$7f,$d00(a0)		; Disable CIA clock
		move.b	#%00011000,$e00(a0)

		move.l	CIA_VBR,a0
		move.l	CIA_OldIntCode,CIA_CIAVector(a0); Restore interrupt vector

		rts

;------------------------------------------------------------------------------
;			C I A _ I N T C O D E
;------------------------------------------------------------------------------
CIA_IntCode	movem.l	d0-a6,-(sp)

		lea	CIA_CIABase,a0

		tst.b	$d00(a0)
		move.b	#$7e,$d00(a0)		; Stop some

		move.b	CIA_TimerLo,$400(a0)	; Bestill vekking!
		move.b	CIA_TimerHi,$500(a0)

		move.b	#$81,$d00(a0)		; Start

		move.b	$e00(a0),d0
		and.b	#%11000000,d0
		or.w	#%00001011,d0
		move.b	d0,$e00(a0)		; ...tut & kj�r!

		tst.b	mt_Enabled
		beq.b	.dontplay
		jsr	CIA_CIAInt

.dontplay
; Legg gjerne inn mer her hvis du har lyst...

		move	#$2000,$dff09c
		movem.l	(sp)+,d0-a6
		rte

;------------------------------------------------------------------------------
;			C I A _ S E T B P M
;------------------------------------------------------------------------------
CIA_SetBPM	movem.l	d0-a6,-(sp)
		and.l	#$ff,d0
		lea	CIABPM(pc),a0
		move.b	d0,(a0)
		add.w	OFFBPM(pc),d0
		add.w	NUDGE(pc),d0
		;cmp.w	CURBPM(pc),d0
		;beq.b	CIA_SkipBPM
		move.w	d0,CURBPM

		cmp.w	#32,d0
		bgt.b	.lo
		move.w	#32,d0
		bra	.done
.lo		cmp.w	#300,d0
		blo.b	.done
		move.w	#300,d0

.done		move.l	CIA_CIASeed,d1

		lsl.l	#4,d0	; sift left
		lsl.l	#4,d1
		
		or.b	BPMFINE(pc),d0
		cmp.w	CURBPM(pc),d0
		beq.b	CIA_SkipBPM
		move.w	d0,ACTUALBPM
		
		divu.w	d0,d1

		move.b	d1,CIA_TimerLo
		lsr.w	#8,d1
		move.b	d1,CIA_TimerHi

CIA_SkipBPM	movem.l	(sp)+,d0-a6
		rts

CURBPM		dc.w	0
OFFBPM		dc.w	0
NUDGE		dc.w	0
ACTUALBPM	dc.w	0
BPMFINE		dc.b	0
CIABPM		dc.b	0
FRAMES		dc.w	0
		even

;------------------------------------------------------------------------------
;			D A T A
;------------------------------------------------------------------------------
CIA_OldIntCode	dc.l	0
CIA_TimerLo	dc.b	0
CIA_TimerHi	dc.b	0
CIA_CIASeed	dc.l	1773447
CIA_VBR		dc.l	0





;---- Playroutine ----

n_note		EQU	0  ; W
n_cmd		EQU	2  ; W
n_cmdlo		EQU	3  ; B
n_start		EQU	4  ; L
n_length	EQU	8  ; W
n_loopstart	EQU	10 ; L
n_replen	EQU	14 ; W
n_period	EQU	16 ; W
n_finetune	EQU	18 ; B
n_volume	EQU	19 ; B
n_dmabit	EQU	20 ; W
n_toneportdirec	EQU	22 ; B
n_toneportspeed	EQU	23 ; B
n_wantedperiod	EQU	24 ; W
n_vibratocmd	EQU	26 ; B
n_vibratopos	EQU	27 ; B
n_tremolocmd	EQU	28 ; B
n_tremolopos	EQU	29 ; B
n_wavecontrol	EQU	30 ; B
n_glissfunk	EQU	31 ; B
n_sampleoffset	EQU	32 ; B
n_pattpos	EQU	33 ; B
n_loopcount	EQU	34 ; B
n_funkoffset	EQU	35 ; B
n_wavestart	EQU	36 ; L
n_reallength	EQU	40 ; W
n_trigger	EQU	42 ; B
n_samplenum	EQU	43 ; B
n_altperiod	EQU	44 ; W
n_offsethack	EQU	46 ; L
n_offsetlen	EQU	50 ; W

mt_DMALines	equ	5

mt_init	;LEA	mt_data,A0
	MOVE.L	A0,mt_SongDataPtr
	MOVE.L	A0,A1
	move.b	950(A0),mt_SongLen	; max patterns

	LEA	952(A1),A1
	MOVEQ	#127,D0
	MOVEQ	#0,D1
mtloop	MOVE.L	D1,D2
	SUBQ.W	#1,D0
mtloop2	MOVE.B	(A1)+,D1
	CMP.B	D2,D1
	BGT.S	mtloop
	DBRA	D0,mtloop2
	ADDQ.B	#1,D2
			

	lea	_Sample,a3
	
	LEA	mt_SampleStarts(PC),A1
	ASL.L	#8,D2
	ASL.L	#2,D2
	ADD.L	#1084,D2
	ADD.L	A0,D2
	MOVE.L	D2,A2
	MOVEQ	#30,D0

mtloop3	CLR.w	(A2)

	tst.w	$30(a0)		; fix for FT2 modules with no replen
	bne.b	.skipft2fix
	move.w	#$1,$30(a0)
.skipft2fix

	moveq	#0,d1
	move.w	42(a0),d1
	asl.l	#1,d1
	tst.l	d1
	bne.b	.fill
	move.l	a3,(a1)+
	move.w	#$80,42(a0)
	move.w	#$80,$30(a0)
	bra.b	.next

.fill	MOVE.L	A2,(A1)+
.next	add.l	d1,a2
	lea	30(a0),a0
	
	DBRA	D0,mtloop3

	OR.B	#2,$BFE001
	MOVE.B	#6,mt_speed
	CLR.B	mt_counter
	CLR.B	mt_SongPos
	CLR.W	mt_PatternPos
	clr.b	mt_PBreakPos
	clr.b	mt_PBreakFlag
	clr.b	mt_PosJumpFlag
	clr.b	mt_LowMask

	lea	mt_chan1temp,a1
	move.l	a1,a0
	moveq	#4-1,d7
.chanclr
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	addq.l	#4,a0
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	lea	mt_chansize(a1),a0
	dbra	d7,.chanclr
	
mt_end	LEA	$DFF000,A0
	CLR.W	$A8(A0)
	CLR.W	$B8(A0)
	CLR.W	$C8(A0)
	CLR.W	$D8(A0)
	MOVE.W	#$F,$DFF096
	RTS

mt_retune
	LEA	$DFF0A0,A5
	LEA	mt_chan1temp(PC),A6
	move.w	n_altperiod(a6),d5
	bne.b	.vib1
	move.w	n_period(a6),d5
.vib1	bsr	mt_tuneup
	move.w	d5,6(a5)

	LEA	$DFF0B0,A5
	LEA	mt_chan2temp(PC),A6
	move.w	n_altperiod(a6),d5
	bne.b	.vib2
	move.w	n_period(a6),d5
.vib2	bsr	mt_tuneup
	move.w	d5,6(a5)

	LEA	$DFF0C0,A5
	LEA	mt_chan3temp(PC),A6
	move.w	n_altperiod(a6),d5
	bne.b	.vib3
	move.w	n_period(a6),d5
.vib3	bsr	mt_tuneup
	move.w	d5,6(a5)

	LEA	$DFF0D0,A5
	LEA	mt_chan4temp(PC),A6
	move.w	n_altperiod(a6),d5
	bne.b	.vib4
	move.w	n_period(a6),d5
.vib4	bsr	mt_tuneup
	move.w	d5,6(a5)
	rts

mt_music
	MOVEM.L	D0-D4/A0-A6,-(SP)
	tst.l	mt_SongDataPtr
	beq	mt_exit
	;TST.B	mt_Enable
	;BEQ	mt_exit
	ADDQ.B	#1,mt_counter
	MOVE.B	mt_counter(PC),D0
	CMP.B	mt_speed(PC),D0
	BLO.S	mt_NoNewNote
	CLR.B	mt_counter
	TST.B	mt_PattDelTime2
	BEQ.S	mt_GetNewNote
	BSR.S	mt_NoNewAllChannels
	BRA	mt_dskip

mt_NoNewNote
	BSR.S	mt_NoNewAllChannels
	BRA	mt_NoNewPosYet

mt_NoNewAllChannels
	LEA	$DFF0A0,A5
	LEA	mt_chan1temp(PC),A6
	BSR	mt_CheckEfx
	LEA	$DFF0B0,A5
	LEA	mt_chan2temp(PC),A6
	BSR	mt_CheckEfx
	LEA	$DFF0C0,A5
	LEA	mt_chan3temp(PC),A6
	BSR	mt_CheckEfx
	LEA	$DFF0D0,A5
	LEA	mt_chan4temp(PC),A6
	BRA	mt_CheckEfx

mt_GetNewNote
	MOVE.L	mt_SongDataPtr(PC),A0
	LEA	12(A0),A3
	LEA	952(A0),A2	;pattpo
	LEA	1084(A0),A0	;patterndata
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.B	mt_SongPos(PC),D0
	MOVE.B	(A2,D0.W),D1
	ASL.L	#8,D1
	ASL.L	#2,D1
	ADD.W	mt_PatternPos(PC),D1
	CLR.W	mt_DMACONtemp

	LEA	$DFF0A0,A5
	LEA	mt_chan1temp(PC),A6
	BSR.S	mt_PlayVoice
	LEA	$DFF0B0,A5
	LEA	mt_chan2temp(PC),A6
	BSR.S	mt_PlayVoice
	LEA	$DFF0C0,A5
	LEA	mt_chan3temp(PC),A6
	BSR.S	mt_PlayVoice
	LEA	$DFF0D0,A5
	LEA	mt_chan4temp(PC),A6
	BSR.S	mt_PlayVoice
	BRA	mt_SetDMA

mt_PlayVoice
	clr.l	n_offsethack(a6)	; clear offset patch
	clr.w	n_offsetlen(a6)
	clr.w	n_altperiod(a6)
	TST.L	(A6)
	BNE.S	mt_plvskip
	BSR	mt_PerNop
mt_plvskip
	MOVE.L	(A0,D1.L),(A6)
	ADDQ.L	#4,D1
	MOVEQ	#0,D2
	MOVE.B	n_cmd(A6),D2
	AND.B	#$F0,D2
	LSR.B	#4,D2
	MOVE.B	(A6),D0
	AND.B	#$F0,D0
	OR.B	D0,D2
	TST.B	D2
	BEQ	mt_SetRegs
	MOVEQ	#0,D3
	LEA	mt_SampleStarts(PC),A1		; SAMPLE NUMBER!!!!!
	MOVE	D2,D4
	MOVE.B	D2,n_samplenum(A6)
	SUBQ.L	#1,D2
	ASL.L	#2,D2
	MULU	#30,D4
	MOVE.L	(A1,D2.L),n_start(A6)
	MOVE.W	(A3,D4.L),n_length(A6)
	MOVE.W	(A3,D4.L),n_reallength(A6)
	MOVE.B	2(A3,D4.L),n_finetune(A6)
	
.noc	MOVE.B	3(A3,D4.L),n_volume(A6)
.next	MOVE.W	4(A3,D4.L),D3 ; Get repeat
	TST.W	D3
	BEQ.S	mt_NoLoop
	MOVE.L	n_start(A6),D2	; Get start
	ASL.W	#1,D3
	ADD.L	D3,D2		; Add repeat
	MOVE.L	D2,n_loopstart(A6)
	MOVE.L	D2,n_wavestart(A6)
	MOVE.W	4(A3,D4.L),D0	; Get repeat
	ADD.W	6(A3,D4.L),D0	; Add replen
	MOVE.W	D0,n_length(A6)
	MOVE.W	6(A3,D4.L),n_replen(A6)	; Save replen
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)	; Set volume
	BRA.S	mt_SetRegs

mt_NoLoop
	MOVE.L	n_start(A6),D2
	ADD.L	D3,D2
	MOVE.L	D2,n_loopstart(A6)
	MOVE.L	D2,n_wavestart(A6)
	MOVE.W	6(A3,D4.L),n_replen(A6)	; Save replen
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)	; Set volume
mt_SetRegs
	MOVE.W	(A6),D0
	AND.W	#$0FFF,D0
	BEQ	mt_CheckMoreEfx	; If no note
	MOVE.W	2(A6),D0
	AND.W	#$0FF0,D0
	CMP.W	#$0E50,D0
	BEQ.S	mt_DoSetFineTune
	MOVE.B	2(A6),D0
	AND.B	#$0F,D0
	CMP.B	#3,D0	; TonePortamento
	BEQ.S	mt_ChkTonePorta
	CMP.B	#5,D0
	BEQ.S	mt_ChkTonePorta
	CMP.B	#9,D0	; Sample Offset

	;BEQ.B	mt_OffsetFix

	BNE.S	mt_SetPeriod

	BSR	mt_CheckMoreEfx_First

	BRA.S	mt_SetPeriod

;mt_OffsetFix
;	bsr	mt_SampleOffset
;	bsr	mt_CheckMoreEfx	
;	bra.s	mt_SetPeriod

mt_DoSetFineTune
	BSR	mt_SetFineTune
	BRA.S	mt_SetPeriod

mt_ChkTonePorta
	BSR	mt_SetTonePorta
	BRA	mt_CheckMoreEfx

mt_SetPeriod
	MOVEM.L	D0-D1/A0-A1,-(SP)
	ST	n_trigger(A6)
	MOVE.W	(A6),D1
	AND.W	#$0FFF,D1
	LEA	mt_PeriodTable(PC),A1
	MOVEQ	#0,D0
	MOVEQ	#36,D2
mt_ftuloop
	CMP.W	(A1,D0.W),D1
	BHS.S	mt_ftufound
	ADDQ.L	#2,D0
	DBRA	D2,mt_ftuloop
mt_ftufound
	MOVEQ	#0,D1
	MOVE.B	n_finetune(A6),D1
	MULU	#36*2,D1
	ADD.L	D1,A1
	;MOVE.W	(A1,D0.W),n_period(A6)
	move.w	(a1,d0.w),d2

	MOVEM.L	(SP)+,D0-D1/A0-A1

	MOVE.W	2(A6),D0
	AND.W	#$0FF0,D0
	CMP.W	#$0ED0,D0 ; Notedelay
	beq	mt_CheckNoteDelay
;	BEQ	mt_CheckMoreEfx

	move.w	d2,n_period(a6)
	MOVE.W	n_dmabit(A6),$DFF096
	BTST	#2,n_wavecontrol(A6)
	BNE.S	mt_vibnoc
	CLR.B	n_vibratopos(A6)
mt_vibnoc
	BTST	#6,n_wavecontrol(A6)
	BNE.S	mt_trenoc
	CLR.B	n_tremolopos(A6)
mt_trenoc
	MOVE.W	n_period(A6),D5
	bsr	mt_tuneup

	MOVE.L	n_start(A6),(A5)	; Set start
	MOVE.W	n_length(A6),4(A5)	; Set length
	MOVE.W	D5,6(A5)		; Set period

	
	MOVE.W	n_dmabit(A6),D0
;	or.w	chantog,d0
	OR.W	D0,mt_DMACONtemp
	BRA	mt_CheckMoreEfx
 
mt_SetDMA				; dma fix thanks to stringray!!
	move.b	$dff006,d0
	addq.b	#mt_DMALines,d0
.wait1	cmp.b	$dff006,d0
	bne.b	.wait1

;	MOVE.W	#1300,D0
;mt_WaitDMA
;	DBRA	D0,mt_WaitDMA

	MOVE.W	mt_DMACONtemp(PC),D0
	and.w	chantog,d0
	OR.W	#$8000,D0
	MOVE.W	D0,$DFF096

	move.b	$dff006,d0
	addq.b	#mt_DMALines,d0
.wait2	cmp.b	$dff006,d0
	bne.b	.wait2

;	MOVE.W	#1300,D0
;mt_WaitDMA2
;	DBRA	D0,mt_WaitDMA2

	LEA	$DFF000,A5
	LEA	mt_chan4temp(PC),A6
	MOVE.L	n_loopstart(A6),$D0(A5)
	MOVE.W	n_replen(A6),$D4(A5)
	LEA	mt_chan3temp(PC),A6
	MOVE.L	n_loopstart(A6),$C0(A5)
	MOVE.W	n_replen(A6),$C4(A5)
	LEA	mt_chan2temp(PC),A6
	MOVE.L	n_loopstart(A6),$B0(A5)
	MOVE.W	n_replen(A6),$B4(A5)
	LEA	mt_chan1temp(PC),A6
	MOVE.L	n_loopstart(A6),$A0(A5)
	MOVE.W	n_replen(A6),$A4(A5)

mt_dskip
	ADD.W	#16,mt_PatternPos		; hmm  skip eh?
	tst.b	slipon
	beq.b	.skip
	add.w	#16,mt_SLPatternPos
	CMP.W	#1024,mt_SLPatternPos
	BLO.S	.skip
	clr.w	mt_SLPatternPos
	add.b	#1,mt_SLSongPos

	cmp.b	#2,mt_PatternLock
	bne.b	.skip
	move.b	mt_SLSongPos,d6
	cmp.b	mt_PatLockEnd,d6
	ble.b	.skip
	move.b	mt_PatLockStart,mt_SLSongPos


.skip
	MOVE.B	mt_PattDelTime,D0
	BEQ.S	mt_dskc
	MOVE.B	D0,mt_PattDelTime2
	CLR.B	mt_PattDelTime
mt_dskc	TST.B	mt_PattDelTime2
	BEQ.S	mt_dska
	SUBQ.B	#1,mt_PattDelTime2
	BEQ.S	mt_dska
	SUB.W	#16,mt_PatternPos
mt_dska	TST.B	mt_PBreakFlag
	BEQ.S	mt_nnpysk
	SF	mt_PBreakFlag
	MOVEQ	#0,D0
	MOVE.B	mt_PBreakPos(PC),D0
	CLR.B	mt_PBreakPos
	LSL.W	#4,D0
	MOVE.W	D0,mt_PatternPos
mt_nnpysk
	tst.b	loopactive
	beq.b	.dontloop
	moveq	#0,d0
	move.b	loopend,d0
	lsl.w	#4,d0
	cmp.w	mt_PatternPos,d0
	bgt.b	.dontloop

	moveq	#0,d0
	move.b	loopstart,d0
	lsl.w	#4,d0
	move.w	d0,mt_PatternPos	


.dontloop
	CMP.W	#1024,mt_PatternPos
	BLO.S	mt_NoNewPosYet
mt_NextPosition	
	MOVEQ	#0,D0
	MOVE.B	mt_PBreakPos(PC),D0
	LSL.W	#4,D0
	MOVE.W	D0,mt_PatternPos
	CLR.B	mt_PBreakPos
	CLR.B	mt_PosJumpFlag
	
	ADDQ.B	#1,mt_SongPos

	tst.b	patslipflag
	beq.b	.noslip
	move.b	mt_PatternCue,mt_SongPos
	clr.b	patslipflag
	bra.b	.skip
.noslip

	cmp.b	#2,mt_PatternLock
	bne.b	.skip
	move.b	mt_SongPos,d6
	cmp.b	mt_PatLockEnd,d6
	ble.b	.skip
	move.b	mt_PatLockStart,mt_SongPos

.skip
	AND.B	#$7F,mt_SongPos
	MOVE.B	mt_SongPos(PC),D1
	MOVE.L	mt_SongDataPtr(PC),A0
	CMP.B	950(A0),D1
	BLO.S	mt_NoNewPosYet
	CLR.B	mt_SongPos
	ST.B	mt_TuneEnd
mt_NoNewPosYet	
	TST.B	mt_PosJumpFlag
	BNE.w	mt_NextPosition
mt_exit	MOVEM.L	(SP)+,D0-D4/A0-A6
	RTS

mt_CheckEfx
	BSR	mt_UpdateFunk
	;clr.w	n_altperiod(a6)
	MOVE.W	n_cmd(A6),D0
	AND.W	#$0FFF,D0
	BEQ.S	mt_PerNop
	MOVE.B	n_cmd(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_Arpeggio
	CMP.B	#1,D0
	BEQ	mt_PortaUp
	CMP.B	#2,D0
	BEQ	mt_PortaDown
	CMP.B	#3,D0
	BEQ	mt_TonePortamento
	CMP.B	#4,D0
	BEQ	mt_Vibrato
	CMP.B	#5,D0
	BEQ	mt_TonePlusVolSlide
	CMP.B	#6,D0
	BEQ	mt_VibratoPlusVolSlide
	CMP.B	#$E,D0
	BEQ	mt_E_Commands
SetBack	;MOVE.W	n_period(A6),6(A5)		; Set Period
	
	move.w	n_period(a6),d5
	bsr	mt_tuneup
	move.w	d5,6(a5)
	
	CMP.B	#7,D0
	BEQ	mt_Tremolo
	CMP.B	#$A,D0
	BEQ	mt_VolumeSlide
mt_Return
	RTS

mt_PerNop
	;MOVE.W	n_period(A6),6(A5)		; set period

	move.w	n_period(a6),d5
	bsr	mt_tuneup
	move.w	d5,6(a5)
	RTS

mt_Arpeggio
	clr.w	n_altperiod(a6)
	MOVEQ	#0,D0
	MOVE.B	mt_counter(PC),D0
	DIVS	#3,D0
	SWAP	D0
	CMP.W	#0,D0
	BEQ.S	mt_Arpeggio2
	CMP.W	#2,D0
	BEQ.S	mt_Arpeggio1
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	LSR.B	#4,D0
	BRA.S	mt_Arpeggio3

mt_Arpeggio1
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#15,D0
	BRA.S	mt_Arpeggio3

mt_Arpeggio2
	MOVE.W	n_period(A6),D2
	BRA.S	mt_Arpeggio4

mt_Arpeggio3
	ASL.W	#1,D0
	MOVEQ	#0,D1
	MOVE.B	n_finetune(A6),D1
	MULU	#36*2,D1
	LEA	mt_PeriodTable(PC),A0
	ADD.L	D1,A0
	MOVEQ	#0,D1
	MOVE.W	n_period(A6),D1
	MOVEQ	#36,D3
mt_arploop
	MOVE.W	(A0,D0.W),D2
	CMP.W	(A0),D1
	BHS.S	mt_Arpeggio4
	ADDQ.L	#2,A0
	DBRA	D3,mt_arploop
	RTS

mt_Arpeggio4
	MOVE.W	D2,6(A5)
	move.w	d2,n_altperiod(a6)
	;move.w	d2,d5
	;bsr	mt_tuneup
	;move.w	d5,6(a5)
	;move.w	d5,d2
	RTS

mt_FinePortaUp
	TST.B	mt_counter
	BNE	mt_Return
	MOVE.B	#$0F,mt_LowMask
mt_PortaUp
	clr.w	n_altperiod(a6)
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	mt_LowMask(PC),D0
	MOVE.B	#$FF,mt_LowMask
	SUB.W	D0,n_period(A6)
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	CMP.W	#113,D0
	BPL.S	mt_PortaUskip
	AND.W	#$F000,n_period(A6)
	OR.W	#113,n_period(A6)
mt_PortaUskip
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
;	MOVE.W	D0,6(A5)
	move.w	d0,n_altperiod(a6)
	
	move.l	d5,-(sp)
	move.w	d0,d5
	bsr	mt_tuneup
	move.w	d5,6(a5)
	move.w	d5,d0
	move.l	(sp)+,d5
	RTS	
 
mt_FinePortaDown
	TST.B	mt_counter
	BNE	mt_Return
	MOVE.B	#$0F,mt_LowMask
mt_PortaDown
	clr.w	n_altperiod(a6)
	CLR.W	D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	mt_LowMask(PC),D0
	MOVE.B	#$FF,mt_LowMask
	ADD.W	D0,n_period(A6)
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	CMP.W	#856,D0
	BMI.S	mt_PortaDskip
	AND.W	#$F000,n_period(A6)
	OR.W	#856,n_period(A6)
mt_PortaDskip
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0

	move.w	d0,n_altperiod(a6)
	;MOVE.W	D0,6(A5)
	
	move.w	d0,d5
	bsr	mt_tuneup
	move.w	d5,6(a5)
	RTS

mt_SetTonePorta
	MOVE.L	A0,-(SP)
	MOVE.W	(A6),D2
	AND.W	#$0FFF,D2
	MOVEQ	#0,D0
	MOVE.B	n_finetune(A6),D0
	MULU	#36*2,D0 ;37?
	LEA	mt_PeriodTable(PC),A0
	ADD.L	D0,A0
	MOVEQ	#0,D0
mt_StpLoop
	CMP.W	(A0,D0.W),D2
	BHS.S	mt_StpFound
	ADDQ.W	#2,D0
	CMP.W	#36*2,D0 ;37?
	BLO.S	mt_StpLoop
	MOVEQ	#35*2,D0
mt_StpFound
	MOVE.B	n_finetune(A6),D2
	AND.B	#8,D2
	BEQ.S	mt_StpGoss
	TST.W	D0
	BEQ.S	mt_StpGoss
	SUBQ.W	#2,D0
mt_StpGoss
	MOVE.W	(A0,D0.W),D2
	MOVE.L	(SP)+,A0

;	move.l	d5,-(sp)
;	move.w	d2,d5
;	bsr	mt_tuneup
;	move.w	d5,6(a5)
;	move.w	d5,d2
;	move.l	(sp)+,d5	

	MOVE.W	D2,n_wantedperiod(A6)
	MOVE.W	n_period(A6),D0
	CLR.B	n_toneportdirec(A6)
	CMP.W	D0,D2
	BEQ.S	mt_ClearTonePorta
	BGE	mt_Return
	MOVE.B	#1,n_toneportdirec(A6)
	RTS

mt_ClearTonePorta
	CLR.W	n_wantedperiod(A6)
	RTS

mt_TonePortamento
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_TonePortNoChange
	MOVE.B	D0,n_toneportspeed(A6)
	CLR.B	n_cmdlo(A6)
mt_TonePortNoChange
	clr.w	n_altperiod(a6)
	TST.W	n_wantedperiod(A6)
	BEQ	mt_Return
	MOVEQ	#0,D0
	MOVE.B	n_toneportspeed(A6),D0
	TST.B	n_toneportdirec(A6)
	BNE.S	mt_TonePortaUp
mt_TonePortaDown
	ADD.W	D0,n_period(A6)
	MOVE.W	n_wantedperiod(A6),D0
	CMP.W	n_period(A6),D0
	BGT.S	mt_TonePortaSetPer
	MOVE.W	n_wantedperiod(A6),n_period(A6)
	CLR.W	n_wantedperiod(A6)
	BRA.S	mt_TonePortaSetPer

mt_TonePortaUp
	SUB.W	D0,n_period(A6)
	MOVE.W	n_wantedperiod(A6),D0
	CMP.W	n_period(A6),D0
	BLT.S	mt_TonePortaSetPer
	MOVE.W	n_wantedperiod(A6),n_period(A6)
	CLR.W	n_wantedperiod(A6)

mt_TonePortaSetPer
	MOVE.W	n_period(A6),D2
	MOVE.B	n_glissfunk(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_GlissSkip
	MOVEQ	#0,D0
	MOVE.B	n_finetune(A6),D0
	MULU	#36*2,D0
	LEA	mt_PeriodTable(PC),A0
	ADD.L	D0,A0
	MOVEQ	#0,D0
mt_GlissLoop
	CMP.W	(A0,D0.W),D2
	BHS.S	mt_GlissFound
	ADDQ.W	#2,D0
	CMP.W	#36*2,D0
	BLO.S	mt_GlissLoop
	MOVEQ	#35*2,D0
mt_GlissFound
	MOVE.W	(A0,D0.W),D2

mt_GlissSkip
	MOVE.W	D2,6(A5) ; Set period
	move.w	d2,n_altperiod(a6)

	move.l	d5,-(sp)
	move.w	d2,d5
	bsr	mt_tuneup
	move.w	d5,6(a5)
	move.w	d5,d2
	move.l	(sp)+,d5	
	RTS

mt_Vibrato
	clr.w	n_altperiod(a6)
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_Vibrato2
	MOVE.B	n_vibratocmd(A6),D2
	AND.B	#$0F,D0
	BEQ.S	mt_vibskip
	AND.B	#$F0,D2
	OR.B	D0,D2
mt_vibskip
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	BEQ.S	mt_vibskip2
	AND.B	#$0F,D2
	OR.B	D0,D2
mt_vibskip2
	MOVE.B	D2,n_vibratocmd(A6)
mt_Vibrato2
	MOVE.B	n_vibratopos(A6),D0
	LEA	mt_VibratoTable(PC),A4
	LSR.W	#2,D0
	AND.W	#$001F,D0
	MOVEQ	#0,D2
	MOVE.B	n_wavecontrol(A6),D2
	AND.B	#$03,D2
	BEQ.S	mt_vib_sine
	LSL.B	#3,D0
	CMP.B	#1,D2
	BEQ.S	mt_vib_rampdown
	MOVE.B	#255,D2
	BRA.S	mt_vib_set
mt_vib_rampdown
	TST.B	n_vibratopos(A6)
	BPL.S	mt_vib_rampdown2
	MOVE.B	#255,D2
	SUB.B	D0,D2
	BRA.S	mt_vib_set
mt_vib_rampdown2
	MOVE.B	D0,D2
	BRA.S	mt_vib_set
mt_vib_sine
	MOVE.B	(A4,D0.W),D2
mt_vib_set
	MOVE.B	n_vibratocmd(A6),D0
	AND.W	#15,D0
	MULU	D0,D2
	LSR.W	#7,D2
	MOVE.W	n_period(A6),D0
	TST.B	n_vibratopos(A6)
	BMI.S	mt_VibratoNeg
	ADD.W	D2,D0
	BRA.S	mt_Vibrato3
mt_VibratoNeg
	SUB.W	D2,D0
mt_Vibrato3
	move.w	d0,n_altperiod(a6)
	MOVE.W	D0,6(A5)
	
	;move.l	d5,-(sp)
	;move.w	d0,d5
	;bsr	mt_tuneup
	;move.w	d5,6(a5)
	;move.w	d5,d0
	;move.l	(sp)+,d5
	
	MOVE.B	n_vibratocmd(A6),D0
	LSR.W	#2,D0
	AND.W	#$003C,D0
	ADD.B	D0,n_vibratopos(A6)
	RTS

mt_TonePlusVolSlide
	BSR	mt_TonePortNoChange
	BRA	mt_VolumeSlide

mt_VibratoPlusVolSlide
	BSR	mt_Vibrato2
	BRA	mt_VolumeSlide

mt_Tremolo
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_Tremolo2
	MOVE.B	n_tremolocmd(A6),D2
	AND.B	#$0F,D0
	BEQ.S	mt_treskip
	AND.B	#$F0,D2
	OR.B	D0,D2
mt_treskip
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	BEQ.S	mt_treskip2
	AND.B	#$0F,D2
	OR.B	D0,D2
mt_treskip2
	MOVE.B	D2,n_tremolocmd(A6)
mt_Tremolo2
	MOVE.B	n_tremolopos(A6),D0
	LEA	mt_VibratoTable(PC),A4
	LSR.W	#2,D0
	AND.W	#$001F,D0
	MOVEQ	#0,D2
	MOVE.B	n_wavecontrol(A6),D2
	LSR.B	#4,D2
	AND.B	#$03,D2
	BEQ.S	mt_tre_sine
	LSL.B	#3,D0
	CMP.B	#1,D2
	BEQ.S	mt_tre_rampdown
	MOVE.B	#255,D2
	BRA.S	mt_tre_set
mt_tre_rampdown
	TST.B	n_vibratopos(A6)
	BPL.S	mt_tre_rampdown2
	MOVE.B	#255,D2
	SUB.B	D0,D2
	BRA.S	mt_tre_set
mt_tre_rampdown2
	MOVE.B	D0,D2
	BRA.S	mt_tre_set
mt_tre_sine
	MOVE.B	(A4,D0.W),D2
mt_tre_set
	MOVE.B	n_tremolocmd(A6),D0
	AND.W	#15,D0
	MULU	D0,D2
	LSR.W	#6,D2
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	TST.B	n_tremolopos(A6)
	BMI.S	mt_TremoloNeg
	ADD.W	D2,D0
	BRA.S	mt_Tremolo3
mt_TremoloNeg
	SUB.W	D2,D0
mt_Tremolo3
	BPL.S	mt_TremoloSkip
	CLR.W	D0
mt_TremoloSkip
	CMP.W	#$40,D0
	BLS.S	mt_TremoloOk
	MOVE.W	#$40,D0
mt_TremoloOk
	MOVE.W	D0,8(A5)
	MOVE.B	n_tremolocmd(A6),D0
	LSR.W	#2,D0
	AND.W	#$003C,D0
	ADD.B	D0,n_tremolopos(A6)
	RTS

mt_SampleOffset_First
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_sononew
	MOVE.B	D0,n_sampleoffset(A6)
mt_sononew
	MOVE.B	n_sampleoffset(A6),D0
	LSL.W	#7,D0
	CMP.W	n_length(A6),D0
	BGE.S	mt_sofskip
	SUB.W	D0,n_length(A6)
	move.w	n_length(a6),n_offsetlen(a6)
	LSL.W	#1,D0
	ADD.L	D0,n_start(A6)			; OFFSET1
	move.l	n_start(a6),n_offsethack(a6)
	ST	n_trigger(a6)
	RTS
mt_sofskip
	MOVE.W	#$0001,n_length(A6)
	RTS



mt_SampleOffset
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_sononew2
	MOVE.B	D0,n_sampleoffset(A6)
mt_sononew2
	MOVE.B	n_sampleoffset(A6),D0
	LSL.W	#7,D0
	CMP.W	n_length(A6),D0
	BGE.S	mt_sofskip2
	SUB.W	D0,n_length(A6)
	LSL.W	#1,D0
	ADD.L	D0,n_start(A6)			; OFFSET1
	ST	n_trigger(a6)
	RTS
mt_sofskip2
	MOVE.W	#$0001,n_length(A6)
	RTS


mt_VolumeSlide
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	LSR.B	#4,D0
	TST.B	D0
	BEQ.S	mt_VolSlideDown
mt_VolSlideUp
	ADD.B	D0,n_volume(A6)
	CMP.B	#$40,n_volume(A6)
	BMI.S	mt_vsuskip
	MOVE.B	#$40,n_volume(A6)
mt_vsuskip
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)
	RTS

mt_VolSlideDown
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
mt_VolSlideDown2
	SUB.B	D0,n_volume(A6)
	BPL.S	mt_vsdskip
	CLR.B	n_volume(A6)
mt_vsdskip
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)
	RTS

mt_PositionJump
	cmp.b	#2,mt_PatternLock
	bne.b	.do
	rts
	
.do	MOVE.B	n_cmdlo(A6),D0
	SUBQ.B	#1,D0
	MOVE.B	D0,mt_SongPos
mt_pj2	CLR.B	mt_PBreakPos
	ST 	mt_PosJumpFlag
	RTS

mt_VolumeChange
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	CMP.B	#$40,D0
	BLS.S	mt_VolumeOk
	MOVEQ	#$40,D0
mt_VolumeOk
	MOVE.B	D0,n_volume(A6)
	MOVE.W	D0,8(A5)
	RTS

mt_PatternBreak
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	MOVE.L	D0,D2
	LSR.B	#4,D0
	MULU	#10,D0
	AND.B	#$0F,D2
	ADD.B	D2,D0
	CMP.B	#63,D0
	BHI.S	mt_pj2
	MOVE.B	D0,mt_PBreakPos
	ST	mt_PosJumpFlag
	RTS

mt_SetSpeed
	MOVEQ	#0,D0
	MOVE.B	3(A6),D0
	BEQ	.fuckoff
	CMP.B	#32,D0
	;BHS	SetTempo			; granny
	BHS	CIA_SetBPM
	CLR.B	mt_counter
	tst.b	d0
	beq.b	.fuckoff
	MOVE.B	D0,mt_speed
.fuckoff
	RTS

mt_CheckNoteDelay
	move.w	n_period(a6),n_altperiod(a6)
	move.w	d2,n_period(a6)
	bra	mt_NoteDelay


mt_CheckMoreEfx_First
	BSR	mt_UpdateFunk
	MOVE.B	2(A6),D0
	AND.B	#$0F,D0
	CMP.B	#$9,D0
	BEQ	mt_SampleOffset_First		; bUG!!
	CMP.B	#$B,D0
	BEQ	mt_PositionJump
	CMP.B	#$D,D0
	BEQ	mt_PatternBreak
	CMP.B	#$E,D0
	BEQ	mt_E_Commands
	CMP.B	#$F,D0
	BEQ	mt_SetSpeed
	CMP.B	#$C,D0
	BEQ	mt_VolumeChange
	BRA	mt_PerNop

mt_CheckMoreEfx
	BSR	mt_UpdateFunk
	MOVE.B	2(A6),D0
	AND.B	#$0F,D0
	CMP.B	#$9,D0
	BEQ	mt_SampleOffset		; bUG!!
	CMP.B	#$B,D0
	BEQ	mt_PositionJump
	CMP.B	#$D,D0
	BEQ	mt_PatternBreak
	CMP.B	#$E,D0
	BEQ.S	mt_E_Commands
	CMP.B	#$F,D0
	BEQ	mt_SetSpeed
	CMP.B	#$C,D0
	BEQ	mt_VolumeChange
	BRA	mt_PerNop

mt_E_Commands
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	LSR.B	#4,D0
	BEQ.S	mt_FilterOnOff
	CMP.B	#1,D0
	BEQ	mt_FinePortaUp
	CMP.B	#2,D0
	BEQ	mt_FinePortaDown
	CMP.B	#3,D0
	BEQ.S	mt_SetGlissControl
	CMP.B	#4,D0
	BEQ	mt_SetVibratoControl
	CMP.B	#5,D0
	BEQ	mt_SetFineTune
	CMP.B	#6,D0
	BEQ	mt_JumpLoop
	CMP.B	#7,D0
	BEQ	mt_SetTremoloControl
	CMP.B	#9,D0
	BEQ	mt_RetrigNote
	CMP.B	#$A,D0
	BEQ	mt_VolumeFineUp
	CMP.B	#$B,D0
	BEQ	mt_VolumeFineDown
	CMP.B	#$C,D0
	BEQ	mt_NoteCut
	CMP.B	#$D,D0
	BEQ	mt_NoteDelay
	CMP.B	#$E,D0
	BEQ	mt_PatternDelay
	CMP.B	#$F,D0
	BEQ	mt_FunkIt
	RTS

mt_FilterOnOff
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#1,D0
	ASL.B	#1,D0
	AND.B	#$FD,$BFE001
	OR.B	D0,$BFE001
	RTS	

mt_SetGlissControl
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	AND.B	#$F0,n_glissfunk(A6)
	OR.B	D0,n_glissfunk(A6)
	RTS

mt_SetVibratoControl
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	AND.B	#$F0,n_wavecontrol(A6)
	OR.B	D0,n_wavecontrol(A6)
	RTS

mt_SetFineTune
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	MOVE.B	D0,n_finetune(A6)
	RTS

mt_JumpLoop
	TST.B	mt_counter
	BNE	mt_Return
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_SetLoop
	TST.B	n_loopcount(A6)
	BEQ.S	mt_jumpcnt
	SUBQ.B	#1,n_loopcount(A6)
	BEQ	mt_Return
mt_jmploop	MOVE.B	n_pattpos(A6),mt_PBreakPos
	ST	mt_PBreakFlag
	RTS

mt_jumpcnt
	MOVE.B	D0,n_loopcount(A6)
	BRA.S	mt_jmploop

mt_SetLoop
	MOVE.W	mt_PatternPos(PC),D0
	LSR.W	#4,D0
	MOVE.B	D0,n_pattpos(A6)
	RTS

mt_SetTremoloControl
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	LSL.B	#4,D0
	AND.B	#$0F,n_wavecontrol(A6)
	OR.B	D0,n_wavecontrol(A6)
	RTS

mt_RetrigNote
	MOVE.L	D1,-(SP)
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_rtnend
	MOVEQ	#0,D1
	MOVE.B	mt_counter(PC),D1
	BNE.S	mt_rtnskp
	MOVE.W	(A6),D1
	AND.W	#$0FFF,D1
	BNE.S	mt_rtnend
	MOVEQ	#0,D1
	MOVE.B	mt_counter(PC),D1
mt_rtnskp
	DIVU	D0,D1
	SWAP	D1
	TST.W	D1
	BNE.S	mt_rtnend
mt_DoRetrig
	MOVE.W	n_dmabit(A6),$DFF096	; Channel DMA off
	MOVE.L	n_start(A6),(A5)	; Set sampledata pointer
	MOVE.W	n_length(A6),4(A5)	; Set length	DMAWAIT!!

	move.b	$dff006,d0
	addq.b	#mt_DMALines,d0
.wait1	cmp.b	$dff006,d0
	bne.b	.wait1


	MOVE.W	n_dmabit(A6),D0
	and.w	chantog,d0
	BSET	#15,D0
	MOVE.W	D0,$DFF096

	move.b	$dff006,d0
	addq.b	#mt_DMALines,d0
.wait2	cmp.b	$dff006,d0
	bne.b	.wait2

	MOVE.L	n_loopstart(A6),(A5)
	MOVE.L	n_replen(A6),4(A5)
	ST	n_trigger(a6)
mt_rtnend
	MOVE.L	(SP)+,D1
	RTS

mt_VolumeFineUp
	TST.B	mt_counter
	BNE	mt_Return
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F,D0
	BRA	mt_VolSlideUp

mt_VolumeFineDown
	TST.B	mt_counter
	BNE	mt_Return
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BRA	mt_VolSlideDown2

mt_NoteCut
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	CMP.B	mt_counter(PC),D0
	BNE	mt_Return
	CLR.B	n_volume(A6)
	MOVE.W	#0,8(A5)
	RTS

mt_NoteDelay
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	CMP.B	mt_counter,D0
	BNE	mt_Return
	MOVE.W	(A6),D0
	BEQ	mt_Return
	MOVE.L	D1,-(SP)
	clr.w	n_altperiod(a6)
	BRA	mt_DoRetrig

mt_PatternDelay
	TST.B	mt_counter
	BNE	mt_Return
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	TST.B	mt_PattDelTime2
	BNE	mt_Return
	ADDQ.B	#1,D0
	MOVE.B	D0,mt_PattDelTime
	RTS

mt_FunkIt
	TST.B	mt_counter
	BNE	mt_Return
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	LSL.B	#4,D0
	AND.B	#$0F,n_glissfunk(A6)
	OR.B	D0,n_glissfunk(A6)
	TST.B	D0
	BEQ	mt_Return
mt_UpdateFunk
	MOVEM.L	A0/D1,-(SP)
	MOVEQ	#0,D0
	MOVE.B	n_glissfunk(A6),D0
	LSR.B	#4,D0
	BEQ.S	mt_funkend
	LEA	mt_FunkTable(PC),A0
	MOVE.B	(A0,D0.W),D0
	ADD.B	D0,n_funkoffset(A6)
	BTST	#7,n_funkoffset(A6)
	BEQ.S	mt_funkend
	CLR.B	n_funkoffset(A6)

	MOVE.L	n_loopstart(A6),D0
	MOVEQ	#0,D1
	MOVE.W	n_replen(A6),D1
	ADD.L	D1,D0
	ADD.L	D1,D0
	MOVE.L	n_wavestart(A6),A0
	ADDQ.L	#1,A0
	CMP.L	D0,A0
	BLO.S	mt_funkok
	MOVE.L	n_loopstart(A6),A0
mt_funkok
	MOVE.L	A0,n_wavestart(A6)
	MOVEQ	#-1,D0
	SUB.B	(A0),D0
	MOVE.B	D0,(A0)
mt_funkend
	MOVEM.L	(SP)+,A0/D1
	RTS

	; adjust period for new bpm
	; d5 = period

mt_tuneup
	tst.b	repitch
	beq.b	.quit2
	tst.w	d5
	beq.b	.quit2
	movem.l	d0-d1,-(sp)
	swap	d5
	clr.w	d5
	swap	d5
	moveq	#0,d0
	moveq	#0,d1
	move.b	CIABPM,d0
	beq.b	.quit
	lsl.w	#4,d0
	move.w	ACTUALBPM,d1
	beq.b	.quit
	mulu	d0,d5
	divu	d1,d5
.quit	movem.l	(sp)+,d0-d1
.quit2	rts
	

mt_FunkTable dc.b 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128

mt_VibratoTable	
	dc.b   0,24,49,74,97,120,141,161
	dc.b 180,197,212,224,235,244,250,253
	dc.b 255,253,250,244,235,224,212,197
	dc.b 180,161,141,120,97,74,49,24

mt_PeriodTable
; Tuning 0, Normal
	dc.w	856,808,762,720,678,640,604,570,538,508,480,453
	dc.w	428,404,381,360,339,320,302,285,269,254,240,226
	dc.w	214,202,190,180,170,160,151,143,135,127,120,113
; Tuning 1
	dc.w	850,802,757,715,674,637,601,567,535,505,477,450
	dc.w	425,401,379,357,337,318,300,284,268,253,239,225
	dc.w	213,201,189,179,169,159,150,142,134,126,119,113
; Tuning 2
	dc.w	844,796,752,709,670,632,597,563,532,502,474,447
	dc.w	422,398,376,355,335,316,298,282,266,251,237,224
	dc.w	211,199,188,177,167,158,149,141,133,125,118,112
; Tuning 3
	dc.w	838,791,746,704,665,628,592,559,528,498,470,444
	dc.w	419,395,373,352,332,314,296,280,264,249,235,222
	dc.w	209,198,187,176,166,157,148,140,132,125,118,111
; Tuning 4
	dc.w	832,785,741,699,660,623,588,555,524,495,467,441
	dc.w	416,392,370,350,330,312,294,278,262,247,233,220
	dc.w	208,196,185,175,165,156,147,139,131,124,117,110
; Tuning 5
	dc.w	826,779,736,694,655,619,584,551,520,491,463,437
	dc.w	413,390,368,347,328,309,292,276,260,245,232,219
	dc.w	206,195,184,174,164,155,146,138,130,123,116,109
; Tuning 6
	dc.w	820,774,730,689,651,614,580,547,516,487,460,434
	dc.w	410,387,365,345,325,307,290,274,258,244,230,217
	dc.w	205,193,183,172,163,154,145,137,129,122,115,109
; Tuning 7
	dc.w	814,768,725,684,646,610,575,543,513,484,457,431
	dc.w	407,384,363,342,323,305,288,272,256,242,228,216
	dc.w	204,192,181,171,161,152,144,136,128,121,114,108
; Tuning -8
	dc.w	907,856,808,762,720,678,640,604,570,538,508,480
	dc.w	453,428,404,381,360,339,320,302,285,269,254,240
	dc.w	226,214,202,190,180,170,160,151,143,135,127,120
; Tuning -7
	dc.w	900,850,802,757,715,675,636,601,567,535,505,477
	dc.w	450,425,401,379,357,337,318,300,284,268,253,238
	dc.w	225,212,200,189,179,169,159,150,142,134,126,119
; Tuning -6
	dc.w	894,844,796,752,709,670,632,597,563,532,502,474
	dc.w	447,422,398,376,355,335,316,298,282,266,251,237
	dc.w	223,211,199,188,177,167,158,149,141,133,125,118
; Tuning -5
	dc.w	887,838,791,746,704,665,628,592,559,528,498,470
	dc.w	444,419,395,373,352,332,314,296,280,264,249,235
	dc.w	222,209,198,187,176,166,157,148,140,132,125,118
; Tuning -4
	dc.w	881,832,785,741,699,660,623,588,555,524,494,467
	dc.w	441,416,392,370,350,330,312,294,278,262,247,233
	dc.w	220,208,196,185,175,165,156,147,139,131,123,117
; Tuning -3
	dc.w	875,826,779,736,694,655,619,584,551,520,491,463
	dc.w	437,413,390,368,347,328,309,292,276,260,245,232
	dc.w	219,206,195,184,174,164,155,146,138,130,123,116
; Tuning -2
	dc.w	868,820,774,730,689,651,614,580,547,516,487,460
	dc.w	434,410,387,365,345,325,307,290,274,258,244,230
	dc.w	217,205,193,183,172,163,154,145,137,129,122,115
; Tuning -1
	dc.w	862,814,768,725,684,646,610,575,543,513,484,457
	dc.w	431,407,384,363,342,323,305,288,272,256,242,228
	dc.w	216,203,192,181,171,161,152,144,136,128,121,114

mt_chan1temp	dc.l	0,0,0,0,0,$00010000,0,0,0,0,0,0,0,0
mt_chan2temp	dc.l	0,0,0,0,0,$00020000,0,0,0,0,0,0,0,0
mt_chan3temp	dc.l	0,0,0,0,0,$00040000,0,0,0,0,0,0,0,0
mt_chan4temp	dc.l	0,0,0,0,0,$00080000,0,0,0,0,0,0,0,0

mt_chansize	equ	14*4

mt_SampleStarts	dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		dc.l	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

mt_SongDataPtr	dc.l 0
mt_speed	dc.b 6
mt_counter	dc.b 0
mt_SongPos	dc.b 0
mt_PBreakPos	dc.b 0
mt_PosJumpFlag	dc.b 0
mt_PBreakFlag	dc.b 0
mt_LowMask	dc.b 0
mt_PattDelTime	dc.b 0
mt_PattDelTime2	dc.b 0
mt_Enable	dc.b 0
mt_PatternPos	dc.w 0
mt_DMACONtemp	dc.w 0
mt_TuneEnd	dc.b 0
mt_Enabled	dc.b 0
mt_PatternLock	dc.b 0
mt_PatLockStart	dc.b 0
mt_PatLockEnd	dc.b 0
mt_SLSongPos	dc.b 0
mt_SLPatternPos	dc.w 0
mt_PatternCue	dc.b 0
mt_SongLen	dc.b 0
		even
		
;/* End of File */


** GFX data for public memory

	section gfxdata_cpu,data

_font_big	incbin	"gfx/font-big_fix.raw"
_font_small	incbin	"gfx/font-small_fix.raw"
_font_digi2	incbin	"gfx/font-digi3.raw"
_kb		incbin	"gfx/kb.raw"
_bpm		incbin	"gfx/bpm.raw"

mi_MaxFileCount	= 500
mi_FileCount	dc.w	0
mi_FileList	dcb.b	mi_Sizeof*mi_MaxFileCount
		dc.l	0


filehd	dc.l	0

fldlock	dc.l	0
dosbase	dc.l	0
doslib	dc.b	"dos.library",0
	even
folder	dc.b	"",0
	even

	CNOP	0,4
fib	dcb.b	300,0


** GFX data for chip ram

        section gfxdata,data_c           ;  keep data & code seperate!



_cCopper	dc.w	$83df,$fffe
		dc.w	bplcon0,$2200	; set as 1 bp display
		dc.w	bplcon1,$0000	; set scroll 0
		dc.w	bpl1mod,-40
		dc.w	bpl2mod,0
_col1		dc.w	color,$000
		dc.w	color+2,$fff
		dc.w	color+4,$111
		dc.w	color+6,$111


_cScopeSpace	dc.w	bplpt,$0
		dc.w	bplpt+2,$0



_cpat		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0

		dc.w	$85df,$fffe
		dc.w	bpl1mod,0

_cScope		dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		

		; high lighter!	
_pathide1	dc.w	$8401,$fffe,$184,$111
		dc.w	$8B01,$fffe,$184,$222
		dc.w	$9201,$fffe,$184,$333
		dc.w	$9901,$fffe,$184,$444
		dc.w	$A001,$fffe,$184,$555
		dc.w	$A701,$fffe,$184,$666
		dc.w	$AE01,$fffe,$184,$777
		dc.w	$B501,$fffe,$184,$888
		dc.w	$BC01,$fffe,$184,$999
		dc.w	$C301,$fffe,$184,$aaa
		dc.w	$C901,$fffe,$180,$00f

_cscreen	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bpl1mod,-40

		dc.w	$D001,$fffe,$180,$000


		dc.w	$D801,$fffe,$184,$aaa
		dc.w	$DF01,$fffe,$184,$999
		dc.w	$E601,$fffe,$184,$888
		dc.w	$ED01,$fffe,$184,$777
		dc.w	$F401,$fffe,$184,$666
		dc.w	$FB01,$fffe,$184,$555,$ffdf,$fffe
		dc.w	$0201,$fffe,$184,$444
		dc.w	$0901,$fffe,$184,$333
		dc.w	$1001,$fffe,$184,$222
		dc.w	$1701,$fffe,$184,$111
		dc.w	$1E01,$fffe,$184,$111
		dc.w	$2501,$fffe,$184,$111

                dc.w    $ffff,$fffe
                dc.w    $ffff,$fffe
                



;-----------------------------------------------------
; HUD copper list!!!!!!!
;-----------------------------------------------------

_hud_cop	dc.w	bplcon0,$5200	; set as 1 bp display
		dc.w	bplcon1,$0000	; set scroll 0
;		dc.w	bplcon2,7<<3
		dc.w	bpl1mod,(4*40)
		dc.w	bpl2mod,(4*40)
		dc.w	ddfstrt,$38	; datafetch start stop
		dc.w	ddfstop,$d0
		dc.w	diwstrt,$2c81	; window start stop
		dc.w	diwstop,$2cc1

_hud_sprites	dc.w	sprpt,0
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



		
_hud_planes	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
		dc.w	bplpt+8,$0
		dc.w	bplpt+10,$0
		dc.w	bplpt+12,$0
		dc.w	bplpt+14,$0
		dc.w	bplpt+16,$0
		dc.w	bplpt+18,$0

	dc.w	$0180,$0000,$0182,$0043,$0184,$0301,$0186,$00fc
	dc.w	$0188,$0dc0,$018a,$0ff0,$018c,$0ff6,$018e,$0ffc
	dc.w	$0190,$0905,$0192,$07f7,$0194,$00b0,$0196,$0086
	dc.w	$0198,$0000,$019a,$0f00,$019c,$0c00,$019e,$0d40
	dc.w	$01a0,$0f61,$01a2,$0fc8,$01a4,$0111,$01a6,$0222
	dc.w	$01a8,$0333,$01aa,$0444,$01ac,$0555,$01ae,$0666
	dc.w	$01b0,$0777,$01b2,$0888,$01b4,$0999,$01b6,$0aaa
	dc.w	$01b8,$0bbb,$01ba,$0ccc,$01bc,$0ddd,$01be,$0fff


		; pattern pos planes
		dc.w	$6adf,$fffe
		dc.w	bpl1mod,-40
		dc.w	bpl2mod,-40
		dc.w	bplcon0,$1100
		; sprite colours
		dc.w	$1a2,$f81
		dc.w	$1a4,$f81
		
		dc.w	$1aa,$f81
		dc.w	$1ac,$f81

		dc.w	$182,$bbb
_grid_planes1c	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	$6bdf,$fffe
_grid_planes1	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	$6edf,$fffe


		dc.w	bplcon0,$3100

_track_plane	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
		dc.w	bplpt+8,$0
		dc.w	bplpt+10,$0
		
		dc.w	$180,$000
		dc.w	$182,$143
_track_flash	dc.w	$184,$1fc
		dc.w	$186,$1fc		
_cue_flash	dc.w	$188,$811
		dc.w	$18a,$811
		dc.w	$18c,$f11
		dc.w	$18e,$f11

		dc.w	$76df,$fffe
		dc.w	bplcon0,$1100
		dc.w	$182,$bbb
_grid_planes2	dc.w	bplpt,$0
		dc.w	bplpt+2,$2
		dc.w	$79df,$fffe
_grid_planes2c	dc.w	bplpt,$0
		dc.w	bplpt+2,$2
	

		; track mute planes
		dc.w	$7adf,$fffe
		dc.w	bplcon0,$3100

_track_planes	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
		dc.w	bplpt+8,$0
		dc.w	bplpt+10,$0

		dc.w	bpl1mod,(2*40)
		dc.w	bpl2mod,(2*40)

		dc.w	$180,$0000
		dc.w	$182,$0222
		dc.w	$184,$0043
		dc.w	$186,$0666
		dc.w	$188,$0F81
		dc.w	$18a,$0E60
		dc.w	$18c,$0FFF
		dc.w	$18e,$0777

; time to jump?

;		dc.w	$83df,$fffe
		
		dc.w	copjmp2,0
		
		dc.w    $ffff,$fffe
                dc.w    $ffff,$fffe

		; **************************************
		; selecta copper
		; **************************************

_select_cop	dc.w	$83df,$fffe
		dc.w	bplcon0,$2100
_select_planes	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
		dc.w	bpl1mod,40
		dc.w	bpl2mod,40		

		dc.w	$0180,$0000,$0182,$0222,$0184,$0333,$0186,$00fc
		
		dc.w	$8edf,$fffe
		dc.w	bplcon0,$3100
		dc.w	bplcon1,$0040
		dc.w	bpl1mod,-40
		dc.w	bpl2mod,0
		
_filla_planes	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
_dir_planes	dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
_fillb_planes	dc.w	bplpt+8,$0
		dc.w	bplpt+10,$0

		dc.w	$184,$fff
		dc.w	$188,$000
	
_selectaline	dc.w	$9101,$fffe,$188,$00,$9601,$fffe,$188,$000,$188,$000
_selectanext	dc.w	$9801,$fffe,$188,$00,$9d01,$fffe,$188,$000,$188,$000
		dc.w	$9f01,$fffe,$188,$00,$a401,$fffe,$188,$000,$188,$000
		dc.w	$a601,$fffe,$188,$00,$ab01,$fffe,$188,$000,$188,$000
		dc.w	$ad01,$fffe,$188,$00,$b201,$fffe,$188,$000,$188,$000
		dc.w	$b401,$fffe,$188,$00,$b901,$fffe,$188,$000,$188,$000
		dc.w	$bb01,$fffe,$188,$00,$c001,$fffe,$188,$000,$188,$000
		dc.w	$c201,$fffe,$188,$00,$c701,$fffe,$188,$000,$188,$000
		dc.w	$c901,$fffe,$188,$00,$ce01,$fffe,$188,$000,$188,$000
		dc.w	$d001,$fffe,$188,$00,$d501,$fffe,$188,$000,$188,$000
		dc.w	$d701,$fffe,$188,$00,$dc01,$fffe,$188,$000,$188,$000
		dc.w	$de01,$fffe,$188,$00,$e301,$fffe,$188,$000,$188,$000
		dc.w	$e501,$fffe,$188,$00,$ea01,$fffe,$188,$000,$188,$000
		dc.w	$ec01,$fffe,$188,$00,$f101,$fffe,$188,$000,$188,$000
		dc.w	$f301,$fffe,$188,$00,$f801,$fffe,$188,$000,$188,$000
		dc.w	$fa01,$fffe,$188,$00,$ff01,$fffe,$188,$000,$ffdf,$fffe
		dc.w	$0101,$fffe,$188,$00,$0601,$fffe,$188,$000,$188,$000
		dc.w	$0801,$fffe,$188,$00,$0d01,$fffe,$188,$000,$188,$000
		dc.w	$0f01,$fffe,$188,$00,$1401,$fffe,$188,$000,$188,$000
		dc.w	$1601,$fffe,$188,$00,$1b01,$fffe,$188,$000,$188,$000
		dc.w	$1d01,$fffe,$188,$00,$2201,$fffe,$188,$000,$188,$000

		dc.w	$2401,$fffe
		dc.w	$188,$333
		dc.w	$2501,$fffe
		dc.w	bplcon0,$0100

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

_selectasize =	_selectanext-_selectaline


_cSwitch	dc.w	$8f01,$fffe
_cSelect	dc.w	$8f01,$fffe
		dc.w	$188,$00f
_cSwitch2	dc.w	$188,$00f
_cSelect2	dc.w	$9601,$fffe
		dc.w	$188,$000


_cSwitch3	dc.w	$ffdf,$fffe
		dc.w	$2401,$fffe
		dc.w	$188,$333

		dc.w	$2501,$fffe
		dc.w	bplcon0,$0100

		
		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

_sprite1	dc.w	$7890,$7b00

		dc.w	%0111111111111100,%0000000000000010
		dc.w	%0111111111111100,%0000000000000010
		dc.w	%0000000000000000,%0111111111111110

_spritelefttop	dc.w	$6c00,$6f00
		dc.w	%1110000000000000,%0000000000000000
		dc.w	%1100000000000000,%0000000000000000
		dc.w	%1000000000000000,%0000000000000000

_spriterighttop	dc.w	$6c00,$6f00
		dc.w	%0000000000000111,%0000000000000000
		dc.w	%0000000000000011,%0000000000000000
		dc.w	%0000000000000001,%0000000000000000


_spriteleftbot	dc.w	$7700,$7a00
		dc.w	%1000000000000000,%0000000000000000
		dc.w	%1100000000000000,%0000000000000000
		dc.w	%1110000000000000,%0000000000000000

_spriterightbot	dc.w	$7700,$7a00
		dc.w	%0000000000000001,%0000000000000000
		dc.w	%0000000000000011,%0000000000000000
		dc.w	%0000000000000111,%0000000000000000


_spriteblank	dc.w	0,0

_spritelist	dc.l	_spritelefttop
		dc.l	_spriterighttop
		dc.l	_spriteleftbot
		dc.l	_spriterightbot
		dc.l	_spriteblank
		dc.l	_spriteblank
		dc.l	_spriteblank
		dc.l	_spriteblank
		
		
		; hud gfx
_hud		incbin	"gfx/hud.raw"
_hud_on		incbin	"gfx/hud_on2.raw"
_hud_off	incbin	"gfx/hud_off.raw"
_trackoff	incbin	"gfx/trackoff.bin"
_trackon	incbin	"gfx/trackon.bin"
_font_digi	incbin	"gfx/font-digi2.raw"
_select		incbin	"gfx/selecta.raw"
_selectfilla	dc.b	$80
		dcb.b	40-2,0
		dc.b	$01
_selectfillb	dc.b	$7f
		dcb.b	40-2,$ff
		dc.b	$fe

_track_fill	dcb.b	40,$ff
_track_pos	dcb.b	40,$00
_track_cue	dcb.b	40,$00

				
_song_grid	dcb.b	40,$aa
_song_grid_clr	dcb.b	40,$00
		; track area
_track		dcb.b	40*9*3




	section gfx_mem,bss_c

_dir		dcb.b	FS_ListMax*7*40+(40*3),0
_dirend

_basepattern	dcb.b	40*PT_LineHeight

_pattern1_start	dcb.b	40*PT_LineHeight*PT_Offset
_pattern1	dcb.b	40*PT_LineHeight*64         
		dcb.b	40*PT_LineHeight*3
_pattern2_start	dcb.b	40*PT_LineHeight*PT_Offset
_pattern2	dcb.b	40*PT_LineHeight*64
		dcb.b	40*PT_LineHeight*13


_pScope1	ds.b	40*PT_LineHeight*10
_pScope2	ds.b	40*PT_LineHeight*10

_Sample		dcb.b	$100,0

		even


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