	IFND	RESOURCES_POTGO_I
RESOURCES_POTGO_I	EQU	1
**
**	$VER: potgo.i 36.0 (13.04.90)
**	Includes Release 39.108
**
**	potgo resource name
**
**	(C) Copyright 1986-1992 Commodore-Amiga, Inc.
**	    All Rights Reserved
**
POTGONAME MACRO
		dc.b	'potgo.resource',0
		ds.w	0
	ENDM

	ENDC	; RESOURCES_POTGO_I
