	IFND	XPK_XPK_I
XPK_XPK_I	SET	1

**
**	$VER: xpk/xpk.i 4.18 (28.10.1998) by SDI
**
**	(C) Copyright 1991-1998 by 
**          Urban Dominik Mueller, Bryan Ford,
**          Christian Schneider, Christian von Roques
**	    Dirk Stöcker
**	    All Rights Reserved
**

	IFND	EXEC_TYPES_I
	INCLUDE	"exec/types.i"
	ENDC

	IFND	EXEC_LIBRARIES_I
	INCLUDE	"exec/libraries.i"
	ENDC

	IFND	UTILITY_TAGITEMS_I
	INCLUDE "utility/tagitem.i"
	ENDC

	IFND	UTILITY_HOOKS_I
	INCLUDE	"utility/hooks.i"
	ENDC

XPKNAME		MACRO
		DC.B  'xpkmaster.library',0
		ENDM

******************************************************************************
*
*      The packing/unpacking tags
*
*

XPK_TagBase	 EQU	(TAG_USER+'XP')

* Caller must supply ONE of these to tell Xpk#?ackFile where to get data from *
XPK_InName	 EQU	(XPK_TagBase+$01) ; Name of a single data file
XPK_InFH	 EQU	(XPK_TagBase+$02) ; File handle - read from current position
XPK_InBuf	 EQU	(XPK_TagBase+$03) ; Unblocked buffer - must also supply InLen
XPK_InHook	 EQU	(XPK_TagBase+$04) ; Callback Hook to get input data
				     	  ; Must also supply InLen, when hook
				          ; cannot do! (not for XPK unpacking)

* Caller must supply ONE of these to tell Xpk#?ack where to send data to *
XPK_OutName	 EQU	(XPK_TagBase+$10) ; Write (or overwrite) this data file
XPK_OutFH	 EQU	(XPK_TagBase+$11) ; File handle - write from current position on
XPK_OutBuf	 EQU	(XPK_TagBase+$12) ; Unblocked buffer - must also supply OutBufLen
XPK_GetOutBuf	 EQU	(XPK_TagBase+$13) ; Master allocates OutBuf - ti_Data points to buffer pointer
XPK_OutHook	 EQU	(XPK_TagBase+$14) ; Callback Hook to get output buffers

* Other tags for Pack/Unpack *
XPK_InLen	 EQU	(XPK_TagBase+$20) ; len of data in input buffer
XPK_OutBufLen	 EQU	(XPK_TagBase+$21) ; len of output buffer
XPK_GetOutLen	 EQU	(XPK_TagBase+$22) ; ti_Data points to long to receive OutLen
XPK_GetOutBufLen EQU	(XPK_TagBase+$23) ; ti_Data points to long to receive OutBufLen
XPK_Password	 EQU	(XPK_TagBase+$24) ; password for de/encoding
XPK_GetError	 EQU	(XPK_TagBase+$25) ; !!! obsolete !!!
XPK_OutMemType	 EQU	(XPK_TagBase+$26) ; Memory type for output buffer
XPK_PassThru	 EQU	(XPK_TagBase+$27) ; Bool: Pass through unrecognized formats
XPK_StepDown	 EQU	(XPK_TagBase+$28) ; Bool: Step down pack method if necessary
XPK_ChunkHook	 EQU	(XPK_TagBase+$29) ; Call this Hook between chunks
XPK_PackMethod	 EQU	(XPK_TagBase+$2a) ; Do a FindMethod before packing
XPK_ChunkSize	 EQU	(XPK_TagBase+$2b) ; Chunk size to try to pack with
XPK_PackMode	 EQU	(XPK_TagBase+$2c) ; Packing mode for sublib to use
XPK_NoClobber	 EQU	(XPK_TagBase+$2d) ; Don't overwrite existing files
XPK_Ignore	 EQU	(XPK_TagBase+$2e) ; Skip this tag
XPK_TaskPri	 EQU	(XPK_TagBase+$2f) ; Change priority for (un)packing
XPK_FileName	 EQU	(XPK_TagBase+$30) ; File name in progress report
XPK_ShortError	 EQU	(XPK_TagBase+$31) ; Output short error messages
XPK_PackersQuery EQU	(XPK_TagBase+$32) ; Query available packers
XPK_PackerQuery	 EQU	(XPK_TagBase+$33) ; Query properties of a packer
XPK_ModeQuery	 EQU	(XPK_TagBase+$34) ; Query properties of packmode
XPK_LossyOK	 EQU	(XPK_TagBase+$35) ; Lossy packing permitted? (FALSE)
XPK_NoCRC	 EQU	(XPK_TagBase+$36) ; Ignore checksum
* tags added for xfdmaster support (version 4 revision 25) *
XPK_Key16	 EQU	(XPK_TagBase+$37) ; 16 bit key (unpack only)
XPK_Key32	 EQU	(XPK_TagBase+$38) ; 32 bit key (unpack only)
* tag added to support seek (version 5) *
XPK_NeedSeek	 EQU	(XPK_TagBase+$39) ; turn on Seek function usage

* preference depending tags added for version 4 - their default value
* may depend on preferences, see <xpk/xpkprefs.i> for more info

XPK_UseXfdMaster EQU	(XPK_TagBase+$40) ; Use xfdmaster.library (FALSE)
XPK_UseExternals EQU	(XPK_TagBase+$41) ; Use packers in extern dir (TRUE)
XPK_PassRequest  EQU	(XPK_TagBase+$42) ; automatic password req. ? (FALSE)
XPK_Preferences  EQU	(XPK_TagBase+$43) ; use prefs semaphore ? (TRUE)
XPK_ChunkReport  EQU	(XPK_TagBase+$44) ; automatic chunk report ? (FALSE)

* tags XTAG(0x50) to XTAG(0x6F) are for XpkPassRequest -- see below

XPK_MARGIN	EQU	256	* Safety margin for output buffer

**************************************************************************
*
*     Message passed to InHook and OutHook
*
*

 STRUCTURE	XpkIOMsg,0
	ULONG	xiom_Type		; Read/Write/Alloc/Free/Abort
	APTR	xiom_Ptr		; The mem area to read from/write to
	LONG	xiom_Size		; The size of the read/write
	LONG	xiom_IOError		; The IoErr() that occurred
	LONG	xiom_Reserved		; Reserved for future use
	LONG	xiom_Private1		; Hook specific, will be set to 0 by
	LONG	xiom_Private2		; master library before first use
	LONG	xiom_Private3		;
	LONG	xiom_Private4		;
	LABEL	xiom_SIZEOF

* The values for XpkIoMsg->Type *
XIO_READ	EQU	1
XIO_WRITE	EQU	2
XIO_FREE	EQU	3
XIO_ABORT	EQU	4
XIO_GETBUF	EQU	5
XIO_SEEK	EQU	6
XIO_TOTSIZE	EQU	7

******************************************************************************
*
*
*   The progress report interface
*
*
 STRUCTURE	XpkProgress,0
	LONG	xp_Type		; Type of report: start/cont/end/abort
	APTR	xp_PackerName	; Brief name of packer being used
	APTR	xp_PackerLongName ; Descriptive name of packer being used
	APTR	xp_Activity	; Packing/unpacking message
	APTR	xp_FileName	; Name of file being processed, if available
	LONG	xp_CCur		; Amount of packed data already processed
	LONG	xp_UCur		; Amount of unpacked data already processed
	LONG	xp_ULen		; Amount of unpacked data in file
	LONG	xp_CF		; Compression factor so far
	LONG	xp_Done		; Percentage done already
	LONG	xp_Speed	; Bytes per second, from beginning of stream
	STRUCT	xp_Reserved,8*4	; For future use
	LABEL	xp_SIZEOF

XPKPROG_START	EQU	1
XPKPROG_MID	EQU	2
XPKPROG_END	EQU	3

*****************************************************************************
*
*
*       The file info block
*
*
 STRUCTURE	XpkFib,0
	LONG	xf_Type		; Unpacked, packed, archive?
	LONG	xf_ULen		; Uncompressed length
	LONG	xf_CLen		; Compressed length
	LONG	xf_NLen		; Next chunk len
	LONG	xf_UCur		; Uncompressed bytes so far
	LONG	xf_CCur		; Compressed bytes so far
	LONG	xf_ID		; 4 letter ID of packer
	STRUCT	xf_Packer,6	; 4 letter name of packer
	WORD	xf_SubVersion	; Required sublib version
	WORD	xf_MasVersion	; Required masterlib version
	LONG	xf_Flags	; Password?
	STRUCT	xf_Head,16	; First 16 bytes of orig. file
	LONG	xf_Ratio	; Compression ratio
	STRUCT	xf_Reserved,8*4	; For future use
	LABEL	xf_SIZEOF

XPKTYPE_UNPACKED  EQU	0       ; Not packed
XPKTYPE_PACKED	  EQU	1       ; Packed file
XPKTYPE_ARCHIVE   EQU	2       ; Archive

XPKFLAGS_PASSWORD EQU	$00000001	; Password needed
XPKFLAGS_SEEK	  EQU	$00000002	; Chunks are independent
XPKFLAGS_NONSTD   EQU	$00000004       ; Nonstandard file format
* defines added for xfdmaster support (version 4 revision 25) *
XPKFLAGS_KEY16	  EQU	$00000008	; 16 bit key - for decrunching
XPKFLAGS_KEY32	  EQU	$00000010	; 32 bit key - for decrunching

******************************************************************************
*
*       The error messages
*
*

XPKERR_OK		EQU	0
XPKERR_NOFUNC		EQU	-1	; This function not implemented		
XPKERR_NOFILES		EQU	-2	; No files allowed for this function		
XPKERR_IOERRIN		EQU	-3	; Input error happened, look at Result2	
XPKERR_IOERROUT		EQU	-4	; Output error happened, look at Result2	
XPKERR_CHECKSUM		EQU	-5	; Check sum test failed			
XPKERR_VERSION		EQU	-6	; Packed file's version newer than lib's	
XPKERR_NOMEM		EQU	-7	; Out of memory				
XPKERR_LIBINUSE		EQU	-8	; For not-reentrant libraries		
XPKERR_WRONGFORM	EQU	-9	; Was not packed with this library		
XPKERR_SMALLBUF		EQU	-10	; Output buffer too small			
XPKERR_LARGEBUF		EQU	-11	; Input buffer too large			
XPKERR_WRONGMODE	EQU	-12	; This packing mode not supported		
XPKERR_NEEDPASSWD	EQU	-13	; Password needed for decoding this file	
XPKERR_CORRUPTPKD 	EQU	-14	; Packed file is corrupt			
XPKERR_MISSINGLIB 	EQU	-15	; Required library is missing		
XPKERR_BADPARAMS 	EQU	-16	; Caller's TagList was screwed up      	
XPKERR_EXPANSION	EQU	-17	; Would have caused data expansion 		
XPKERR_NOMETHOD   	EQU	-18	; Can't find requested method          	
XPKERR_ABORTED    	EQU	-19	; Operation aborted by user            	
XPKERR_TRUNCATED	EQU	-20	; Input file is truncated			
XPKERR_WRONGCPU   	EQU	-21	; Better CPU required for this library	
XPKERR_PACKED     	EQU	-22	; Data are already XPacked			
XPKERR_NOTPACKED  	EQU	-23	; Data not packed				
XPKERR_FILEEXISTS 	EQU	-24	; File already exists			
XPKERR_OLDMASTLIB 	EQU	-25	; Master library too old			
XPKERR_OLDSUBLIB  	EQU	-26	; Sub library too old			
XPKERR_NOCRYPT    	EQU	-27	; Cannot encrypt				
XPKERR_NOINFO     	EQU	-28	; Can't get info on that packer		
XPKERR_LOSSY		EQU	-29	; This compression method is lossy		
XPKERR_NOHARDWARE	EQU	-30	; Compression hardware required		
XPKERR_BADHARDWARE	EQU	-31	; Compression hardware failed		
XPKERR_WRONGPW    	EQU	-32	; Password was wrong				
XPKERR_UNKNOWN		EQU	-33	; unknown error cause
XPKERR_REQTIMEOUT	EQU	-34	; password request reached time out	*/

XPKERRMSGSIZE		EQU	80	; Maximum size of an error message		

*****************************************************************************
*
*
*     The XpkQuery() call
*
*

 STRUCTURE XpkPackerInfo,0
	STRUCT  xpi_Name,24         ; Brief name of the packer
	STRUCT  xpi_LongName,32     ; Full name of the packer
	STRUCT  xpi_Description,80  ; One line description of packer
	LONG    xpi_Flags           ; Defined below
	LONG    xpi_MaxChunk        ; Max input chunk size for packing
	LONG    xpi_DefChunk        ; Default packing chunk size
	UWORD   xpi_DefMode         ; Default mode on 0..100 scale
	LABEL   xpi_SIZEOF

XPKIF_PK_CHUNK   EQU	$00000001   ; Library supplies chunk packing
XPKIF_PK_STREAM  EQU	$00000002   ; Library supplies stream packing
XPKIF_PK_ARCHIVE EQU	$00000004   ; Library supplies archive packing
XPKIF_UP_CHUNK   EQU	$00000008   ; Library supplies chunk unpacking
XPKIF_UP_STREAM  EQU	$00000010   ; Library supplies stream unpacking
XPKIF_UP_ARCHIVE EQU	$00000020   ; Library supplies archive unpacking
XPKIF_HOOKIO     EQU	$00000080   ; Uses full Hook I/O
XPKIF_CHECKING   EQU	$00000400   ; Does its own data checking
XPKIF_PREREADHDR EQU	$00000800   ; Unpacker pre-reads the next chunkhdr
XPKIF_ENCRYPTION EQU	$00002000   ; Sub library supports encryption
XPKIF_NEEDPASSWD EQU	$00004000   ; Sub library requires encryption
XPKIF_MODES      EQU	$00008000   ; Sub library has different XpkMode's
XPKIF_LOSSY      EQU	$00010000   ; Sub library does lossy compression
XPKIF_NOSEEK	 EQU	$00020000   ; unpacker does not support seeking

 STRUCTURE XpkMode,0
	APTR    xm_Next          ; Chain to next descriptor for ModeDesc list
	ULONG   xm_Upto          ; Maximum efficiency handled by this mode
	ULONG   xm_Flags         ; Defined below
	ULONG   xm_PackMemory    ; Extra memory required during packing
	ULONG   xm_UnpackMemory  ; Extra memory during unpacking
	ULONG   xm_PackSpeed     ; Approx packing speed in K per second
	ULONG   xm_UnpackSpeed   ; Approx unpacking speed in K per second
	UWORD   xm_Ratio         ; CF in 0.1%
	UWORD   xm_ChunkSize     ; Desired chunk size in K (!!) for this mode
	STRUCT  xm_Description,10; 8 character mode description
	LABEL   xm_SIZEOF

XPKMF_A3000SPEED EQU $00000001	; Timings on old test environment, obsolete
XPKMF_PK_NOCPU   EQU $00000002	; Packing not heavily CPU dependent
XPKMF_UP_NOCPU   EQU $00000004	; Unpacking... (i.e. hardware modes)

MAXPACKERS	EQU	100

 STRUCTURE XpkPackerList,0
	ULONG	xpl_NumPackers
	STRUCT	xpl_Packer,MAXPACKERS*6
	LABEL	xpl_SIZEOF

*****************************************************************************
*
*
*     The XpkSeek() call (library version 5)
*
*

XPKSEEK_BEGINNING	EQU	-1
XPKSEEK_CURRENT		EQU	0
XPKSEEK_END		EQU	1

*****************************************************************************
*
*
*     The XpkPassRequest() call (library version 4)
*
*

XPK_PassChars	  EQU	(XPK_TagBase+$50) ; which chars should be used
XPK_PasswordBuf	  EQU	(XPK_TagBase+$51) ; buffer to write password to
XPK_PassBufSize	  EQU	(XPK_TagBase+$52) ; size of password buffer
XPK_Key16BitPtr	  EQU	(XPK_TagBase+$53) ; pointer to UWORD var for key data
XPK_Key32BitPtr	  EQU	(XPK_TagBase+$54) ; pointer to ULONG var for key data
XPK_PubScreen	  EQU	(XPK_TagBase+$55) ; pointer to struct Screen
XPK_PassTitle	  EQU	(XPK_TagBase+$56) ; Text shown in Screen title
XPK_TimeOut	  EQU	(XPK_TagBase+$57) ; Timeout time of requester in seconds
* request position and verify tags (version 4 revision 25) *
XPK_PassWinLeft	  EQU	(XPK_TagBase+$58) ; distance from left screen border
XPK_PassWinTop	  EQU	(XPK_TagBase+$59) ; distance form top screen border
XPK_PassWinWidth  EQU	(XPK_TagBase+$5A) ; width of requester window
XPK_PassWinHeight EQU	(XPK_TagBase+$5B) ; height of requester window
XPK_PassCenter    EQU	(XPK_TagBase+$5C) ; Left and Top are used as center coords
XPK_PassVerify	  EQU   (XPK_TagBase+$5D) ; force user to verify password

* XPKPASSFF defines for XPK_PassChars. Do not use. Use XPKPASSFLG defines *

XPKPASSFF_30x39 	EQU	$0001 ; all numbers
XPKPASSFF_41x46		EQU	$0002 ; chars 'A' to 'F'
XPKPASSFF_61x66 	EQU	$0004 ; chars 'a' to 'f'
XPKPASSFF_47x5A		EQU	$0008 ; chars 'G' to 'Z'
XPKPASSFF_67x7A		EQU	$0010 ; chars 'g' to 'z'
XPKPASSFF_20		EQU	$0020 ; space character
XPKPASSFF_SPECIAL7BIT	EQU	$0040 ; special 7 bit chars
			; all chars 0x20 to 0x7E without above defined

XPKPASSFF_C0xDE		EQU	$0080 ; upper special chars
XPKPASSFF_DFxFF		EQU	$0100 ; lower special chars
XPKPASSFF_SPECIAL8BIT	EQU	$0200 ; special 8 bit chars
			; all chars 0xA0 to 0xBF

* Control characters (0x00 to 0x1F, 0x7F and 0x80 to 0x9F) are not
* useable. This also means carriage return, linefeed, tab stop and
* other controls are not usable.

* flags for XPK_PassChars, XPKPASSFLG_PRINTABLE is default
*
* NUMERIC	: numbers
* HEXADECIMAL	: hex numbers
* ALPHANUMERIC	: numbers and letters
* INTALPHANUM	: numbers and international letters
* ASCII7	: 7 Bit ASCII
* PRINTABLE	: all characters

XPKPASSFLG_NUMERIC	EQU	XPKPASSFF_30x39
XPKPASSFLG_HEXADECIMAL	EQU	(XPKPASSFF_30x39|XPKPASSFF_41x46|XPKPASSFF_61x66)
XPKPASSFLG_ALPHANUMERIC	EQU	(XPKPASSFLG_HEXADECIMAL|XPKPASSFF_47x5A|XPKPASSFF_67x7A)
XPKPASSFLG_INTALPHANUM	EQU	(XPKPASSFLG_ALPHANUMERIC|XPKPASSFF_C0xDE|XPKPASSFF_DFxFF)
XPKPASSFLG_ASCII7	EQU	(XPKPASSFLG_ALPHANUMERIC|XPKPASSFF_SPECIAL7BIT)
XPKPASSFLG_PRINTABLE	EQU	(XPKPASSFLG_INTALPHANUM|XPKPASSFF_SPECIAL7BIT|XPKPASSFF_SPECIAL8BIT|XPKPASSFF_20)

*****************************************************************************
*
*
*     The XpkAllocObject() call (library version 4)
*
* use this always with library version >= 4, do NO longer allocate the
* structures yourself
*
*

XPKOBJ_FIB		EQU	0 ; XpkFib structure
XPKOBJ_PACKERINFO	EQU	1 ; XpkPackerInfo structure
XPKOBJ_MODE		EQU	2 ; XpkMode structure
XPKOBJ_PACKERLIST	EQU	3 ; XpkPackerList structure

	ENDC
