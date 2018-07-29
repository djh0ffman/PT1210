
*****************************************
** keyboard system
*****************************************

	include hardware/cia.i
	include hardware/intbits.i

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



