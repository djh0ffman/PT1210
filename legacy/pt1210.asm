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

SW_Splash = 0		; Include splash screen

	section pt1210,code

; Exports for C code (places them in global scope)
	XDEF _START
	XDEF _FS_LoadErrBuff
	XDEF _FS_DrawLoadError

; Imports from C code
	XREF _pt1210_file_gen_list
	XREF _pt1210_file_read
	XREF _pt1210_file_count
	XREF _pt1210_file_list

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
*** SORT KEYS FOR FILE LIST				***
***************************************************
SORT_NAME = 0
SORT_FILE_NAME = 1
SORT_BPM = 2
SORT_SIZE = 3

***************************************************
*** CLOSE DOWN SYSTEM - INIT PROGRAM		***
***************************************************

_START	bsr	_pt1210_file_gen_list

.go
	move.l	#1,-(sp)				; ascending
	move.l	#SORT_NAME,-(sp)		; sort by name
	bsr	_pt1210_file_sort_list
	add.l #8,sp

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


************************************
** The mega mod player by h0ffman **
************************************

	include	hardware/custom.i


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

		include keyboard.asm
		include file_system.asm
		include vblank_int.asm
		include time.asm
		include ui.asm
		include control.asm
		include pattern_render.asm
		include file_selector.asm
		include scope.asm
		include cia_int.asm
		include player.asm
		include data_fast.asm
		include data_chip.asm
		include splash_screen.asm


