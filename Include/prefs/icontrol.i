	IFND	PREFS_ICONTROL_I
PREFS_ICONTROL_I	SET	1
**
**	$VER: icontrol.i 38.3 (30.12.91)
**	Includes Release 39.108
**
**	File format for intuition control preferences
**
**	(C) Copyright 1991-1992 Commodore-Amiga, Inc.
**	All Rights Reserved
**

;---------------------------------------------------------------------------

    IFND EXEC_TYPES_I
    INCLUDE "exec/types.i"
    ENDC

;---------------------------------------------------------------------------

ID_ICTL equ "ICTL"


   STRUCTURE IControlPrefs,0
	STRUCT ic_Reserved,4*4	; System reserved
	UWORD ic_TimeOut	; Verify timeout
	WORD  ic_MetaDrag	; Meta drag mouse event
	ULONG ic_Flags		; IControl flags (see below)
	UBYTE ic_WBtoFront	; CKey: WB to front
	UBYTE ic_FrontToBack	; CKey: front screen to back
	UBYTE ic_ReqTrue	; CKey: Requester TRUE
	UBYTE ic_ReqFalse	; CKey: Requester FALSE
   LABEL IControlPrefs_SIZEOF

; flags for IControlPrefs.ic_Flags
	BITDEF	IC,COERCE_COLORS,0
	BITDEF	IC,COERCE_LACE,1
	BITDEF	IC,STRGAD_FILTER,2
	BITDEF	IC,MENUSNAP,3

;---------------------------------------------------------------------------

	ENDC	; PREFS_ICONTROL_I
