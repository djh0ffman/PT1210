	IFND	PREFS_PREFHDR_I
PREFS_PREFHDR_I	SET	1
**
**	$VER: prefhdr.i 38.1 (19.06.91)
**	Includes Release 39.108
**
**	File format for preferences header
**
**	(C) Copyright 1991-1992 Commodore-Amiga, Inc.
**	All Rights Reserved
**

;---------------------------------------------------------------------------

    IFND EXEC_TYPES_I
    INCLUDE "exec/types.i"
    ENDC

;---------------------------------------------------------------------------

ID_PREF	equ "PREF"
ID_PRHD	equ "PRHD"

;---------------------------------------------------------------------------

   STRUCTURE PrefHeader,0
	UBYTE	ph_Version	; version of following data
	UBYTE	ph_Type		; type of following data
	ULONG	ph_Flags	; always set to 0 for now
   LABEL PrefHeader_SIZEOF

;---------------------------------------------------------------------------

	ENDC	; PREFS_PREFHDR_I
