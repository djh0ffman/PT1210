	IFND DOS_STDIO_I
DOS_STDIO_I	EQU	1
**
**	$VER: stdio.i 37.2 (01.11.91)
**	Includes Release 39.108
**
**	ANSI-like stdio defines for dos buffered I/O
**
**	(C) Copyright 1989-1992 Commodore-Amiga, Inc.
**	    All Rights Reserved
**


* types for SetVBuf()
BUF_LINE	EQU	0	; flush on \n, etc
BUF_FULL	EQU	1	; never flush except when needed
BUF_NONE	EQU	2	; no buffering

* EOF return value
ENDSTREAMCH	EQU	-1

	ENDC	; DOS_STDIO_I

