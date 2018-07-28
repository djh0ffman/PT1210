	IFND DATATYPES_PICTURECLASS_I
DATATYPES_PICTURECLASS_I	SET	1
**
**  $VER: pictureclass.i 39.0 (29.06.92)
**  Includes Release 39.108
**
**  Interface definitions for DataType picture objects.
**
**  (C) Copyright 1992 Commodore-Amiga, Inc.
**	All Rights Reserved
**

    IFND UTILITY_TAGITEM_I
    INCLUDE 'utility/tagitem.i'
    ENDC

    IFND DATATYPES_DATATYPESCLASS_I
    INCLUDE 'datatypes/datatypesclass.i'
    ENDC

    IFND LIBRARIES_IFFPARSE_I
    INCLUDE 'libraries/iffparse.i'
    ENDC

;------------------------------------------------------------------------------

PICTUREDTCLASS	equ	"picture.datatype"

;------------------------------------------------------------------------------

; Picture attributes
PDTA_ModeID		equ	(DTA_Dummy+200)
	; Mode ID of the picture

PDTA_BitMapHeader	equ	(DTA_Dummy+201)

PDTA_BitMap		equ	(DTA_Dummy+202)
	; Pointer to a class-allocated bitmap, that will end
	; up being freed by picture.class when DisposeDTObject()
	; is called

PDTA_ColorRegisters	equ	(DTA_Dummy+203)
PDTA_CRegs		equ	(DTA_Dummy+204)
PDTA_GRegs		equ	(DTA_Dummy+205)
PDTA_ColorTable		equ	(DTA_Dummy+206)
PDTA_ColorTable2	equ	(DTA_Dummy+207)
PDTA_Allocated		equ	(DTA_Dummy+208)
PDTA_NumColors		equ	(DTA_Dummy+209)
PDTA_NumAlloc		equ	(DTA_Dummy+210)

PDTA_Remap		equ	(DTA_Dummy+211)
	; Boolean : Remap picture (defaults to TRUE)

PDTA_Screen		equ	(DTA_Dummy+212)
	; Screen to remap to

PDTA_FreeSourceBitMap	equ	(DTA_Dummy+213)
	; Boolean : Free the source bitmap after remapping

PDTA_Grab		equ	(DTA_Dummy+214)
	; Pointer to a Point structure

PDTA_DestBitMap		equ	(DTA_Dummy+215)
	; Pointer to the destination (remapped) bitmap

PDTA_ClassBitMap	equ	(DTA_Dummy+216)
	; Pointer to class-allocated bitmap, that will end
	; up being freed by the class after DisposeDTObject()
	; is called

PDTA_NumSparse		equ	(DTA_Dummy+217)
	; (UWORD) Number of colors used for sparse remapping

PDTA_SparseTable	equ	(DTA_Dummy+218)
	; (UBYTE *) Pointer to a table of pen numbers indicating
	; which colors should be used when remapping the image.
	; This array must contain as many entries as there
	; are colors specified with PDTA_NumSparse

;------------------------------------------------------------------------------

; Masking techniques
mskNone			equ	0
mskHasMask		equ	1
mskHasTransparentColor	equ	2
mskLasso		equ	3

; Compression techniques
cmpNone			equ	0
cmpByteRun1		equ	1

; Bitmap header (BMHD) structure
    STRUCTURE BitMapHeader,0
	UWORD	 bmh_Width;		; Width in pixels
	UWORD	 bmh_Height		; Height in pixels
	WORD	 bmh_Left		; Left position
	WORD	 bmh_Top		; Top position
	UBYTE	 bmh_Depth		; Number of planes
	UBYTE	 bmh_Masking		; Masking type
	UBYTE	 bmh_Compression	; Compression type
	UBYTE	 bmh_Pad
	UWORD	 bmh_Transparent	; Transparent color
	UBYTE	 bmh_XAspect
	UBYTE	 bmh_YAspect
	WORD	 bmh_PageWidth
	WORD	 bmh_PageHeight
    LABEL BitMapHeader_SIZEOF

;------------------------------------------------------------------------------

;  Color register structure
    STRUCTURE ColorRegister,0
	UBYTE	red
	UBYTE	green
	UBYTE	blue
    LABEL ColorRegister_SIZEOF

;------------------------------------------------------------------------------

; IFF types that may be in pictures
ID_ILBM		equ	'ILBM'
ID_BMHD		equ	'BMHD'
ID_BODY		equ	'BODY'
ID_CMAP		equ	'CMAP'
ID_CRNG		equ	'CRNG'
ID_GRAB		equ	'GRAB'
ID_SPRT		equ	'SPRT'
ID_DEST		equ	'DEST'
ID_CAMG		equ	'CAMG'

;------------------------------------------------------------------------------

    ENDC	; DATATYPES_PICTURECLASS_I
