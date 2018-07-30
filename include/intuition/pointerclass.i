    IFND INTUITION_POINTERCLASS_I
INTUITION_POINTERCLASS_I SET 1
**
** $VER: pointerclass.i 39.3 (22.06.92)
** Includes Release 39.108
**
**  'boopsi' pointer class interface
**
**  (C) Copyright 1992 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"
	ENDC

	IFND INTUITION_INTUITION_I
	INCLUDE "intuition/intuition.i"
	ENDC

	IFND UTILITY_TAGITEM_I
	INCLUDE "utility/tagitem.i"
	ENDC


* The following tags are recognized at NewObject() time by
* pointerclass:
*
* POINTERA_BitMap (struct BitMap *) - Pointer to bitmap to
*	get pointer imagery from.  Bitplane data need not be
*	in chip RAM.
* POINTERA_XOffset (LONG) - X-offset of the pointer hotspot.
* POINTERA_YOffset (LONG) - Y-offset of the pointer hotspot.
* POINTERA_WordWidth (ULONG) - designed width of the pointer in words
* POINTERA_XResolution (ULONG) - one of the POINTERXRESN_ flags below
* POINTERA_YResolution (ULONG) - one of the POINTERYRESN_ flags below
*

POINTERA_Dummy		EQU	(TAG_USER+$39000)

POINTERA_BitMap		EQU	(POINTERA_Dummy+$01)
POINTERA_XOffset	EQU	(POINTERA_Dummy+$02)
POINTERA_YOffset	EQU	(POINTERA_Dummy+$03)
POINTERA_WordWidth	EQU	(POINTERA_Dummy+$04)
POINTERA_XResolution	EQU	(POINTERA_Dummy+$05)
POINTERA_YResolution	EQU	(POINTERA_Dummy+$06)

* These are the choices for the POINTERA_XResolution attribute which
* will determine what resolution pixels are used for this pointer.
*
* POINTERXRESN_DEFAULT (ECS-compatible pointer width)
*	= 70 ns if SUPERHIRES-type mode, 140 ns if not
*
* POINTERXRESN_SCREENRES
*	= Same as pixel speed of screen
*
* POINTERXRESN_LORES (pointer always in lores-like pixels)
*	= 140 ns in 15kHz modes, 70 ns in 31kHz modes
*
* POINTERXRESN_HIRES (pointer always in hires-like pixels)
*	= 70 ns in 15kHz modes, 35 ns in 31kHz modes
*
* POINTERXRESN_140NS (pointer always in 140 ns pixels)
*	= 140 ns always
*
* POINTERXRESN_70NS (pointer always in 70 ns pixels)
*	= 70 ns always
*
* POINTERXRESN_35NS (pointer always in 35 ns pixels)
*	= 35 ns always

POINTERXRESN_DEFAULT	EQU	0
POINTERXRESN_140NS	EQU	1
POINTERXRESN_70NS	EQU	2
POINTERXRESN_35NS	EQU	3

POINTERXRESN_SCREENRES	EQU	4
POINTERXRESN_LORES	EQU	5
POINTERXRESN_HIRES	EQU	6

* These are the choices for the POINTERA_YResolution attribute which
* will determine what vertical resolution is used for this pointer.
*
* POINTERYRESN_DEFAULT
*	= In 15 kHz modes, the pointer resolution will be the same
*	  as a non-interlaced screen.  In 31 kHz modes, the pointer
*	  will be doubled vertically.  This means there will be about
*	  200-256 pointer lines per screen.
*
* POINTERYRESN_HIGH
* POINTERYRESN_HIGHASPECT
*	= Where the hardware/software supports it, the pointer resolution
*	  will be high.  This means there will be about 400-480 pointer
*	  lines per screen.  POINTERYRESN_HIGHASPECT also means that
*	  when the pointer comes out double-height due to hardware/software
*	  restrictions, its width would be doubled as well, if possible
*	  (to preserve aspect).
*
* POINTERYRESN_SCREENRES
* POINTERYRESN_SCREENRESASPECT
*	= Will attempt to match the vertical resolution of the pointer
*	  to the screen's vertical resolution.  POINTERYRESN_HIGHASPECT also
*	  means that when the pointer comes out double-height due to
*	  hardware/software restrictions, its width would be doubled as well,
*	  if possible (to preserve aspect).

POINTERYRESN_DEFAULT		EQU	0
POINTERYRESN_HIGH		EQU	2
POINTERYRESN_HIGHASPECT		EQU	3
POINTERYRESN_SCREENRES		EQU	4
POINTERYRESN_SCREENRESASPECT	EQU	5

	ENDC
