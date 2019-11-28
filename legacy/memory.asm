
	include exec/memory.i

ExecBase	= 4
AvailMem	= -$d8

freechip	movem.l	d1-a6,-(sp)
			move.l	#MEMF_CHIP|MEMF_LARGEST,d1
			move.l	ExecBase,a6
			jsr	AvailMem(a6)
			movem.l	(sp)+,d1-a6
			rts
