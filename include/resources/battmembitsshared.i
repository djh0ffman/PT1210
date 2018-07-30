	IFND	RESOURCES_BATTMEMSHARED_I
RESOURCES_BATTMEMBITSSHARED_I	SET	1
**
**	$VER: battmembitsshared.i 39.1 (13.01.92)
**	Includes Release 39.108
**
**	BattMem shared specific bit definitions.
**
**	(C) Copyright 1989-1992 Commodore-Amiga Inc.
**		All Rights Reserved
**


*
* Shared bits in the battery-backedup ram.
*
*	Bits 64 and above
*

*
* SHARED_AMNESIA
*
*		The battery-backedup memory has had a memory loss.
*		This bit is used as a flag that the user should be
*		notified that all battery-backed bit have been
*		reset and that some attention is required. Zero
*		indicates that a memory loss has occured.
*

BATTMEM_SHARED_AMNESIA_ADDR	EQU	64
BATTMEM_SHARED_AMNESIA_LEN	EQU	1


*
* SCSI_HOST_ID
*
*		a 3 bit field (0-7) that is stored in complemented form
*		(this is so that default value of 0 really means 7)
*		It's used to set the A3000 controllers SCSI ID (on reset)
*

BATTMEM_SCSI_HOST_ID_ADDR	EQU	65
BATTMEM_SCSI_HOST_ID_LEN	EQU	3


*
* SCSI_SYNC_XFER
*
*		determines if the driver should initiate synchronous
*		transfer requests or leave it to the drive to send the
*		first request.  This supports drives that crash or
*		otherwise get confused when presented with a sync xfer
*		message.  Default=0=sync xfer not initiated.
*

BATTMEM_SCSI_SYNC_XFER_ADDR	EQU	68
BATTMEM_SCSI_SYNC_XFER_LEN	EQU	1

	ENDC	; RESOURCES_BATTMEMSHARED_I
