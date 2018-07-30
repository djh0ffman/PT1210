	IFND UTILITY_NAME_I
UTILITY_NAME_I	EQU	1
**
**	$VER: name.i 39.2 (04.09.92)
**	Includes Release 39.108
**
**	Namespace definitions
**
**	(C) Copyright 1992 Commodore-Amiga, Inc.
**	All Rights Reserved
**

	include	"exec/types.i"

* The named object structure */
* Note how simple this structure is!  You have nothing else that is
* defined.  Remember that...  Do not hack at the namespaces!!!
*
 STRUCTURE NamedObject,0
	APTR	no_Object	; Your pointer, for whatever you want
 LABEL NamedObject_End

*
ANO_NameSpace	equ	4000	; Tag to define namespace
ANO_UserSpace	equ	4001	; tag to define userspace
ANO_Priority	equ	4002	; tag to define priority
ANO_Flags	equ	4003	; tag to define flags

* flags for tag ANO_Flags

	BITDEF	NS,NODUPS,0	; defaults to allowing duplicates
	BITDEF	NS,CASE,1	; so it defaults to caseless

	ENDC
