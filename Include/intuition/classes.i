	IFND INTUITION_CLASSES_I
INTUITION_CLASSES_I SET 1
**
**  $VER: classes.i 38.1 (11.11.91)
**  Includes Release 39.108
**
**  Only used by class implementors
**
**  (C) Copyright 1989-1992 Commodore-Amiga, Inc.
**	    All Rights Reserved
**

	IFND UTILITY_HOOKS_I
	INCLUDE "utility/hooks.i"
	ENDC

	IFND	INTUITION_CLASSUSR_I
	INCLUDE "intuition/classusr.i"
	ENDC

;*******************************************
;*** "White box" access to struct IClass ***
;*******************************************

 STRUCTURE ICLASS,0
    STRUCT cl_Dispatcher,h_SIZEOF
    ULONG  cl_Reserved		; must be 0

    APTR   cl_Super
    APTR   cl_ID		; pointer to null-terminated string

    ; where within an object is the instance data for this class?
    UWORD  cl_InstOffset
    UWORD  cl_InstSize

    ULONG  cl_UserData		; per-class data of your choice
    ULONG  cl_SubclassCount	; how many direct subclasses?
    ULONG  cl_ObjectCount	; how many objects created of this class?
    ULONG  cl_Flags
    ; no iclass_SIZEOF because only Intuition allocates these

; defined values of cl_Flags
CLB_INLIST EQU 0
CLF_INLIST EQU $00000001	; class in in public class list

; see classes.h for common calculations (sorry, no macros yet)

;**************************************************
;*** "White box" access to struct _Object	***
;**************************************************

* We have this, the instance data of the root class, PRECEDING
* the "object".  This is so that Gadget objects are Gadget pointers,
* and so on.  If this structure grows, it will always have o_Class
* at the end, so the you can always get it by subtracting #4 from
* the pointer returned from NewObject().
*
* This data structure is subject to change.  Do not use the o_Node
* embedded structure.


 STRUCTURE _Object,0
    STRUCT o_Node,MLN_SIZE
    APTR   o_Class

    ; this value may change but difference between it and offset of o_Class
    ; will remain constant
    LABEL  _object_SIZEOF

    ENDC
