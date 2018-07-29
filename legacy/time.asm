
; ********* WHATS THE FUCKING TIME!!!
; TODO replace this with something bloody accurate! 

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
