

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

; Exports to C code
	XDEF _CIABPM
	XDEF _OFFBPM
	XDEF _BPMFINE
	XDEF _NUDGE

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

		tst.b	_mt_Enabled
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
		lea	_CIABPM(pc),a0
		move.b	d0,(a0)
		add.w	_OFFBPM(pc),d0
		add.w	_NUDGE(pc),d0
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

		or.b	_BPMFINE(pc),d0
		cmp.w	CURBPM(pc),d0
		beq.b	CIA_SkipBPM
		move.w	d0,ACTUALBPM

		divu.w	d0,d1

		move.b	d1,CIA_TimerLo
		lsr.w	#8,d1
		move.b	d1,CIA_TimerHi

CIA_SkipBPM	movem.l	(sp)+,d0-a6
		rts


; ************* CIA Int

CIA_CIAInt	movem.l	d0-a6,-(sp)
		tst.b	_mt_TuneEnd
		bne.b	.skip
		jsr	mt_music

		tst.b	_repitch_enabled
		beq.b	.skip
		jsr	mt_retune

.skip		tst.b	_mt_TuneEnd
		beq.b	.skip2
		jsr	_mt_end
		clr.b	_mt_Enabled
		clr.b	_mt_TuneEnd
.skip2		movem.l	(sp)+,d0-a6
		rts

CURBPM		dc.w	0
_OFFBPM		dc.w	0
_NUDGE		dc.w	0
ACTUALBPM	dc.w	0
_BPMFINE		dc.b	0
_CIABPM		dc.b	0
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



