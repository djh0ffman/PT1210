	IFND	PREFS_WBPATTERN_I
PREFS_WBPATTERN_I	SET	1
**
**	$VER: wbpattern.i 39.3 (11.06.92)
**	Includes Release 39.108
**
**	File format for wbpattern preferences
**
**	(C) Copyright 1991-1992 Commodore-Amiga, Inc.
**	All Rights Reserved
**

;---------------------------------------------------------------------------

	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"
	ENDC

	IFND LIBRARIES_IFFPARSE_I
	INCLUDE "libraries/iffparse.i"
	ENDC

;---------------------------------------------------------------------------

ID_PTRN		equ	'PTRN'

;---------------------------------------------------------------------------

    STRUCTURE WBPatternPrefs,0
	STRUCT	wbp_Reserved,(4*4)
	UWORD	wbp_Which			; Which pattern is it
	UWORD	wbp_Flags
	BYTE	wbp_Revision			; Must be set to zero
	BYTE	wbp_Depth			; Depth of pattern
	UWORD	wbp_DataLength			; Length of following data
    LABEL WBPatternPrefs_SIZEOF

;---------------------------------------------------------------------------

; constants for WBPatternPrefs.wbp_Which
WBP_ROOT	equ	0
WBP_DRAWER	equ	1
WBP_SCREEN	equ	2

; wbp_Flags values
    BITDEF WBP,PATTERN,0
	; Data contains a pattern

    BITDEF WBP,NOREMAP,4
	; Don't remap the pattern

;---------------------------------------------------------------------------

MAXDEPTH	equ	3			;  Max depth supported (8 colors)
DEFPATDEPTH	equ	2			;  Depth of default patterns

;  Pattern width & height:
PAT_WIDTH	equ	16
PAT_HEIGHT	equ	16

;---------------------------------------------------------------------------

	ENDC	; PREFS_WBPATTERN_I
