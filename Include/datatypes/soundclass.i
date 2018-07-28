	IFND	DATATYPES_SOUNDCLASS_I
DATATYPES_SOUNDCLASS_I	SET	1
**
**  $VER: soundclass.i 39.0 (24.06.92)
**  Includes Release 39.108
**
**  Interface definitions for DataType sound objects.
**
**  (C) Copyright 1992 Commodore-Amiga, Inc.
**	All Rights Reserved
**

    IFND	UTILITY_TAGITEM_I
    INCLUDE <utility/tagitem.i>
    ENDC

    IFND	DATATYPES_DATATYPESCLASS_I
    INCLUDE <datatypes/datatypesclass.i>
    ENDC

    IFND	LIBRARIES_IFFPARSE_I
    INCLUDE <libraries/iffparse.i>
    ENDC

;------------------------------------------------------------------------------

SOUNDDTCLASS	equ	"sound.datatype"

;------------------------------------------------------------------------------

/* Sound attributes */
SDTA_Dummy		equ	(DTA_Dummy+500)
SDTA_VoiceHeader	equ	(SDTA_Dummy+1)
SDTA_Sample		equ	(SDTA_Dummy+2)
SDTA_SampleLength	equ	(SDTA_Dummy+3)
SDTA_Period		equ	(SDTA_Dummy+4)
SDTA_Volume		equ	(SDTA_Dummy+5)
SDTA_Cycles		equ	(SDTA_Dummy+6)

;------------------------------------------------------------------------------

    STRUCTURE VoiceHeader,0
	ULONG	vh_OneShotHiSamples
	ULONG	vh_RepeatHiSamples
	ULONG	vh_SamplesPerHiCycle
	UWORD	vh_SamplesPerSec
	UBYTE	vh_Octaves
	UBYTE	vh_Compression
	ULONG	vh_Volume
    LABEL VoiceHeader_SIZEOF

;------------------------------------------------------------------------------

CMP_NONE		equ	 0
CMP_FIBDELTA		equ	 1

;------------------------------------------------------------------------------

; IFF types
ID_8SVX	equ	'8SVX'
ID_VHDR	equ	'VHDR'
ID_BODY	equ	'BODY'

;------------------------------------------------------------------------------

    ENDC	; DATATYPES_SOUNDCLASS_I
