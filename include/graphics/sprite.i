	IFND	GRAPHICS_SPRITE_I
GRAPHICS_SPRITE_I	SET	1
**
**	$VER: sprite.i 39.5 (09.06.92)
**	Includes Release 39.108
**
**
**
**	(C) Copyright 1985-1992 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

    IFND    EXEC_TYPES_I
    include 'exec/types.i'
    ENDC

   STRUCTURE   SimpleSprite,0
   APTR        ss_posctldata
   WORD        ss_height
   WORD        ss_x
   WORD        ss_y
   WORD        ss_num
   LABEL       ss_SIZEOF


	STRUCTURE	ExtSprite,0
	STRUCT	es_SimpleSprite,ss_SIZEOF
	WORD	es_wordwidth
	WORD	es_flags
	LABEL	es_SIZEOF



; tags for AllocSpriteData:
SPRITEA_Width		equ	$81000000
SPRITEA_XReplication	equ	$81000002
SPRITEA_YReplication	equ	$81000004
SPRITEA_OutputHeight	equ	$81000006
SPRITEA_Attached	equ	$81000008
SPRITEA_OldDataFormat	equ	$8100000a	; MUST pass in outputheight if using this tag


; tags for GetExtSprite:

GSTAG_SPRITE_NUM	equ	$82000020
GSTAG_ATTACHED		equ	$82000022
GSTAG_SOFTSPRITE	equ	$82000024

; tags valid for either GetExtSprite or ChangeExtSprite:
GSTAG_SCANDOUBLED	equ	$83000000	; request "NTSC-Like" height if possible.

	ENDC	; GRAPHICS_SPRITE_I
