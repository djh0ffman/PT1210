
	include exec/memory.i
	
ExecBase	= 4
AllocMem	= -$c6
FreeMem 	= -$d2
AvailMem	= -$d8
OpenLib		= -30-378
CloseLib	= -414
Open		= -30
Close		= -36

		rsreset	
mi_FileSize	rs.l	1
mi_BPM		rs.w	1
mi_Frames	rs.w	1
mi_FileName	rs.b	108		; -- file name
mi_Name		rs.b	40 		; -- display name
mi_Sizeof	rs.b	0

		; d0 = first char
mi_FindFirst	
			moveq	#0,d2
			lea		_pt1210_file_list,a0
			move.w	_pt1210_file_count,d7
			subq.b	#1,d7
.huntloop	moveq	#0,d1
			move.b	mi_Name(a0),d1
.comp		cmp.b	#$60,d1
			blo.b	.upper
			sub.b	#$20,d1
.upper		cmp.b	d0,d1
			beq.b	.found
			lea		mi_Sizeof(a0),a0
			addq.w	#1,d2
			dbra	d7,.huntloop		
			moveq	#-1,d2
.found		move.l	d2,d0
			rts
		
mi_SortFileAsc	
			bsr 	_pt1210_file_sort_name_asc
			rts

mi_SortFileDesc	
			bsr		_pt1210_file_sort_name_desc
			rts

mi_SortBPMAsc
			bsr		_pt1210_file_sort_bpm_asc
			rts

mi_SortBPMDesc
			bsr		_pt1210_file_sort_bpm_desc
			rts

freechip	movem.l	d1-a6,-(sp)
			move.l	#MEMF_CHIP|MEMF_LARGEST,d1
			move.l	ExecBase,a6
			jsr	AvailMem(a6)
			movem.l	(sp)+,d1-a6
			rts


allocchip	movem.l	d0-a6,-(sp)
			move.l	memsize,d0
			move.w	#MEMF_CHIP,d1
			move.l	ExecBase,a6
			jsr		AllocMem(a6)
			move.l	d0,memptr
			movem.l	(sp)+,d0-a6
			rts

unallocchip
			movem.l	d0-a6,-(sp)
			move.l	memsize,d0
			move.l	memptr,a1
			beq.b	.noal
			move.l	ExecBase,a6
			jsr		FreeMem(a6)
			clr.l	memptr
			clr.l	memsize
.noal		movem.l	(sp)+,d0-a6
			rts
	
memptr	dc.l	0
memsize	dc.l	0

