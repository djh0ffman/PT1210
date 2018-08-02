


*********************************************
** File Selecta
*********************************************


FS_CurrentType	dc.b	0
		even
		
FS_SwitchType	
			moveq	#0,d0
			move.b	FS_CurrentType,d0
			tst.b	d0
			beq.b	.kb
			moveq	#0,d0
			bra.b	.go
.kb			moveq	#1,d0
.go			move.b	d0,FS_CurrentType
			bsr	FS_DrawType
			bsr	FS_DrawDir
			rts

		; d0 = 0 = BPM / 1 = KB
		
FS_DrawType	moveq	#0,d0
			move.b	FS_CurrentType,d0
			lea		_bpm,a0
			tst.b	d0
			beq.b	.gobpm
			lea		_kb,a0
.gobpm		lea		_select,a1
			lea		(40*5)-4(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
			move.l	(a0)+,(a1)
			lea		40(a1),a1
	
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

FS_DrawDir	cmp.w	#$0,_pt1210_file_count
			bne.b	.go
			bra	FS_DrawNoMods
		
.go			moveq	#0,d5
			move.b	FS_CurrentType,d5
			lea		FS_FileList,a0
			lea		_pt1210_file_list,a1
			moveq	#0,d0
			move.w	FS_Current,d0
			sub.w	FS_ListPos,d0
			mulu	#mi_Sizeof,d0
			add.l	d0,a1
		
			moveq	#FS_ListMax-1,d7	; max file count...
.loop		lea		mi_Name(a1),a2
			tst.b	(a2)
			beq		.quit		
			moveq	#36-1,d6	; char count
			move.l	a0,a3
.charloop
			move.b	(a2)+,(a3)+
			bra.b	.doloop
.doloop		dbra	d6,.charloop	

			tst.b	d5
			bne.b	.kb

			moveq	#0,d0
			move.w	mi_BPM(a1),d0
			moveq	#3-1,d2
			lea		3(a3),a3
		
.bpmconv	divu.w	#10,d0
			swap	d0
			add.b	#"0",d0
			move.b	d0,-(a3)
			clr.w	d0
			swap	d0
			dbra	d2,.bpmconv
			bra		.nextfile
		
.kb			move.l	mi_FileSize(a1),d0
			divu	#1024,d0
			and.l	#$ffff,d0
			moveq	#6-1,d2
			lea		3(a3),a3
				
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
		
.nextfile	lea		40(a0),a0
			lea		mi_Sizeof(a1),a1
			tst.l	(a1)
			beq.b	.quit
			dbra	d7,.loop
.quit
			; all done now draw...
			lea		FS_FileList,a0
			lea		_dir+80,a1
			moveq	#FS_ListMax-1,d7		; number of lines
			bsr		ST_Type
	;		bsr		FS_Copper
			rts


FS_Copper	cmp.w	#$0,_pt1210_file_count
			bgt.b	.go
			bsr	FS_CopperClr
			rts
		
.go			movem.l	d0-a6,-(sp)
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
			move.w	_pt1210_file_count,d3		; total
			sub.w	#1,d3
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

			bsr	_pt1210_file_gen_list
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
			lea		_pt1210_file_list,a0
			add.l	d0,a0
			move.l	mi_FileSize(a0),memsize
			move.w	mi_Frames(a0),FRAMES
			lea		mi_FileName(a0),a0
			move.l	a0,a6
			tst.l	memsize
			beq		.error
			bsr		allocchip
			tst.l	memptr
			beq.b	.memerror

			move.l	memsize,-(sp)
			move.l	#0,-(sp)
			move.l	memptr,-(sp)
			move.l	a6,-(sp)

			bsr		_pt1210_file_read

			add.l 	#16,sp

			tst.l	d0
			bne.b	.quit
			
			move.l	memptr,a0
			jsr		mt_init		

			bsr		FS_Reset


			bsr		switch

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

FS_DrawError	
			bsr	FS_CopperClr
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
		
FS_DrawOutRam	
			bsr	FS_CopperClr
			lea	FS_OutRam,a0
			lea	_dir+80,a1
			lea	10*7*40(a1),a1
			moveq	#5-1,d7		; number of lines
			bsr	ST_Type
			rts

		; d0 = load error code
_FS_DrawLoadError
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
FS_LoadError	
			dc.b	"--------------------------------------- "
FS_LoadErrCode	
			dc.b	"       LOADING ERROR : $00000000        "
_FS_LoadErrBuff	
			dc.b	"                                        "
			dc.b	"                                        "
			dc.b	"--------------------------------------- "


FS_LoadErrHead	dc.b	0,0

FS_Error	dc.b	"--------------------------------------- "
			dc.b	"                                        "
			dc.b	"          UNSPECIFIED ERROR!            "
			dc.b	"                                        "
			dc.b	"--------------------------------------- "
