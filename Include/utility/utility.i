	IFND UTILITY_UTILITY_I
UTILITY_UTILITY_I SET 1
**
**	$VER: utility.i 39.3 (18.09.92)
**	Includes Release 39.108
**
**	utility.library include file
**
**	(C) Copyright 1989-1992 Commodore-Amiga, Inc.
**	All Rights Reserved
**

;---------------------------------------------------------------------------

UTILITYNAME MACRO
	DC.B 'utility.library',0
	ENDM

   STRUCTURE UtilityBase,LIB_SIZE
	UBYTE ub_Language
	UBYTE ub_Reserved

;---------------------------------------------------------------------------

	ENDC	; UTILITY_UTILITY_I
