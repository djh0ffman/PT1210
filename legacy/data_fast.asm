
** GFX data for public memory

	section gfxdata_cpu,data

_font_big	incbin	"gfx/font-big_fix.raw"
_font_small	incbin	"gfx/font-small_fix.raw"
_font_digi2	incbin	"gfx/font-digi3.raw"
_kb		incbin	"gfx/kb.raw"
_bpm		incbin	"gfx/bpm.raw"

mi_MaxFileCount	= 500
mi_FileCount	dc.w	0
mi_FileList	dcb.b	mi_Sizeof*mi_MaxFileCount
		dc.l	0


filehd	dc.l	0

fldlock	dc.l	0
dosbase	dc.l	0
doslib	dc.b	"dos.library",0
	even
folder	dc.b	"",0
	even

	CNOP	0,4
fib	dcb.b	300,0
