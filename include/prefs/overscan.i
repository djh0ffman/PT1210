	IFND	PREFS_OVERSCAN_I
PREFS_OVERSCAN_I	SET	1
**
**	$VER: overscan.i 38.2 (26.06.91)
**	Includes Release 39.108
**
**	File format for overscan preferences
**
**	(C) Copyright 1991-1992 Commodore-Amiga, Inc.
**	All Rights Reserved
**

;---------------------------------------------------------------------------

    IFND EXEC_TYPES_I
    INCLUDE "exec/types.i"
    ENDC

    IFND GRAPHICS_GFX_I
    INCLUDE "graphics/gfx.i"
    ENDC

;---------------------------------------------------------------------------

ID_OSCN equ "OSCN"

   STRUCTURE OverscanPrefs,0
	STRUCT os_Reserved,4*4
	ULONG  os_DisplayID;
	STRUCT os_ViewPos,tpt_SIZEOF
	STRUCT os_Text,tpt_SIZEOF
	STRUCT os_Standard,ra_SIZEOF
   LABEL OverscanPrefs_SIZEOF

;---------------------------------------------------------------------------

	ENDC	; PREFS_OVERSCAN_I
