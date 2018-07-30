	IFND	WORKBENCH_WORKBENCH_I
WORKBENCH_WORKBENCH_I	EQU	1
**
**	$VER: workbench.i 37.2 (01.02.91)
**	Includes Release 39.108
**
**	workbench.library general definitions
**
**	(C) Copyright 1985-1992 Commodore-Amiga, Inc.
**	All Rights Reserved
**

	IFND	EXEC_TYPES_I
	INCLUDE	"exec/types.i"
	ENDC

	IFND	EXEC_NODES_I
	INCLUDE	"exec/nodes.i"
	ENDC

	IFND	EXEC_LISTS_I
	INCLUDE	"exec/lists.i"
	ENDC

	IFND	EXEC_TASKS_I
	INCLUDE	"exec/tasks.i"
	ENDC

	IFND	INTUITION_INTUITION_I
	INCLUDE	"intuition/intuition.i"
	ENDC


; the Workbench object types
WBDISK		EQU	1
WBDRAWER	EQU	2
WBTOOL		EQU	3
WBPROJECT	EQU	4
WBGARBAGE	EQU	5
WBDEVICE	EQU	6
WBKICK		EQU	7
WBAPPICON	EQU	8

; the main workbench object structure
 STRUCTURE DrawerData,0
    STRUCT	dd_NewWindow,nw_SIZE	; args to open window
    LONG	dd_CurrentX		; current x coordinate of origin
    LONG	dd_CurrentY		; current y coordinate of origin
    LABEL	OldDrawerData_SIZEOF	; pre V36 size
; the amount of OldDrawerData actually written to disk
OLDDRAWERDATAFILESIZE	EQU (OldDrawerData_SIZEOF)
    ULONG	dd_Flags		; flags for drawer
    UWORD	dd_ViewModes		; view mode for drawer
    LABEL	DrawerData_SIZEOF
; the amount of DrawerData actually written to disk
DRAWERDATAFILESIZE	EQU (DrawerData_SIZEOF)


 STRUCTURE DiskObject,0
    UWORD	do_Magic		; a magic num at the start of the file
    UWORD	do_Version		; a version number, so we can change it
    STRUCT	do_Gadget,gg_SIZEOF	; a copy of in core gadget
    UBYTE	do_Type
    UBYTE	do_PAD_BYTE		; Pad it out to the next word boundry
    APTR	do_DefaultTool
    APTR	do_ToolTypes
    LONG	do_CurrentX
    LONG	do_CurrentY
    APTR	do_DrawerData
    APTR	do_ToolWindow		; only applies to tools
    LONG	do_StackSize		; only applies to tools
    LABEL	do_SIZEOF

WB_DISKMAGIC	EQU	$e310	; a magic number, not easily impersonated
WB_DISKVERSION	EQU	1	; our current version number
WB_DISKREVISION	EQU	1	; out current revision number
; I only use the lower 8 bits of Gadget.UserData for the revision #
WB_DISKREVISIONMASK	EQU	$ff

 STRUCTURE FreeList,0
    WORD	fl_NumFree
    STRUCT	fl_MemList,LH_SIZE
    ; weird name to avoid conflicts with FileLocks
    LABEL	FreeList_SIZEOF



* each message that comes into the WorkBenchPort must have a type field
* in the preceeding short.  These are the defines for this type
*

MTYPE_PSTD		EQU	1	; a "standard Potion" message
MTYPE_TOOLEXIT		EQU	2	; exit message from our tools
MTYPE_DISKCHANGE	EQU	3	; dos telling us of a disk change
MTYPE_TIMER		EQU	4	; we got a timer tick
MTYPE_CLOSEDOWN		EQU	5	; <unimplemented>
MTYPE_IOPROC		EQU	6	; <unimplemented>
MTYPE_APPWINDOW		EQU	7	; msg from an app window
MTYPE_APPICON		EQU	8	; msg from an app icon
MTYPE_APPMENUITEM	EQU	9	; msg from an app menuitem
MTYPE_COPYEXIT		EQU	10	; exit message from copy process
MTYPE_ICONPUT		EQU	11	; msg from PutDiskObject in icon.library

* workbench does different complement modes for its gadgets.
* It supports separate images, complement mode, and backfill mode.
* The first two are identical to intuitions GADGIMAGE and GADGHCOMP.
* backfill is similar to GADGHCOMP, but the region outside of the
* image (which normally would be color three when complemented)
* is flood-filled to color zero.
*
GADGBACKFILL		EQU	$0001

* if an icon does not really live anywhere, set its current position
* to here
*
NO_ICON_POSITION	EQU	($80000000)


* workbench now is a library.  this is it's name
WORKBENCH_NAME	MACRO
		dc.b		'workbench.library',0
		ds.w		0
		ENDM

; If you find am_Version >= AM_VERSION, you now this structure has
; at least the fields defined in this version of the include file
AM_VERSION	EQU	1

 STRUCTURE AppMessage,0
	STRUCT am_Message,MN_SIZE	; standard message structure
	UWORD am_Type			; message type
	ULONG am_UserData		; application specific
	ULONG am_ID			; application definable ID
	LONG am_NumArgs			; # of elements in arglist
	APTR am_ArgList			; the arguements themselves
	UWORD am_Version		; will be AM_VERSION
	UWORD am_Class			; message class
	WORD am_MouseX			; mouse x position of event
	WORD am_MouseY			; mount y position of event
	ULONG am_Seconds		; current system clock time
	ULONG am_Micros			; current system clock time
	STRUCT am_Reserved,8		; avoid recompilation
	LABEL AppMessage_SIZEOF


*
* The following structures are private.  These are just stub
* structures for code compatibility...
*
 STRUCTURE AppWindow,0
	STRUCT aw_PRIVATE,0
	LABEL AppWindow_SIZEOF

 STRUCTURE AppIcon,0
 	STRUCT ai_PRIVATE,0
	LABEL AppIcon_SIZEOF

 STRUCTURE AppMenuItem,0
	STRUCT ami_PRIVATE,0
	LABEL AppMenuItem_SIZEOF


	ENDC	; WORKBENCH_WORKBENCH_I

