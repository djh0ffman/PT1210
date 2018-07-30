	IFND UTILITY_TAGITEM_I
UTILITY_TAGITEM_I SET	1
**
**	$VER: tagitem.i 39.1 (20.01.92)
**	Includes Release 39.108
**
**	Extended specification mechanism
**
**	(C) Copyright 1989-1992 Commodore-Amiga Inc.
**	All Rights Reserved
**

;---------------------------------------------------------------------------

	IFND EXEC_TYPES_I
	INCLUDE "exec/types.i"
	ENDC

;---------------------------------------------------------------------------

; Tags are a general mechanism of extensible data arrays for parameter
; specification and property inquiry. In practice, tags are used in arrays,
; or chain of arrays.

   STRUCTURE TagItem,0
	ULONG	ti_Tag		; identifies the type of the data
	ULONG	ti_Data		; type-specific data
   LABEL ti_SIZEOF

; constants for Tag.ti_Tag, system tag values
TAG_DONE   equ 0  ; terminates array of TagItems. ti_Data unused
TAG_END	   equ 0  ; synonym for TAG_DONE
TAG_IGNORE equ 1  ; ignore this item, not end of array
TAG_MORE   equ 2  ; ti_Data is pointer to another array of TagItems
		  ; note that this tag terminates the current array
TAG_SKIP   equ 3  ; skip this and the next ti_Data items

; Indication of user tag, OR this in with user tag values */
TAG_USER   equ $80000000  ; differentiates user tags from system tags

; NOTE: Until further notice, tag bits 16-30 are RESERVED and should be zero.
;	Also, the value (TAG_USER | 0) should never be used as a tag value.
;

;---------------------------------------------------------------------------

; Tag filter logic specifiers for use with FilterTagItems()
TAGFILTER_AND equ 0	; exclude everything but filter hits
TAGFILTER_NOT equ 1	; exclude only filter hits

;---------------------------------------------------------------------------

; Mapping types for use with MapTags()
MAP_REMOVE_NOT_FOUND equ 0	; remove tags that aren't in mapList
MAP_KEEP_NOT_FOUND   equ 1	; keep tags that aren't in mapList

;---------------------------------------------------------------------------

; Merging types for use with MergeTagItems() */
MERGE_OR_LIST_1   equ 0	; list 1's item is preferred
MERGE_OR_LIST_2   equ 1	; list 2's item is preferred
MERGE_AND_LIST_1  equ 2	; item must appear in both lists
MERGE_AND_LIST_2  equ 3	; item must appear in both lists
MERGE_NOT_LIST_1  equ 4	; item must not appear in list 1
MERGE_NOT_LIST_2  equ 5 ; item must not appear in list 2
MERGE_XOR	  equ 6	; item must appear in only one list

;---------------------------------------------------------------------------

	ENDC	; UTILITY_TAGITEM_I
