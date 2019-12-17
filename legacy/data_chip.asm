
** GFX data for chip ram


; When linking with amiga-gcc, we need to use the
; magic section name '.data_chip' to get a chip RAM data hunk.
		section .data_chip,data_c

_cCopper	dc.w	$83df,$fffe
		dc.w	bplcon0,$2200	; set as 1 bp display
		dc.w	bplcon1,$0000	; set scroll 0
		dc.w	bpl1mod,-40
		dc.w	bpl2mod,0
_col1		dc.w	color,$000
		dc.w	color+2,$fff
		dc.w	color+4,$111
		dc.w	color+6,$111


_cScopeSpace	dc.w	bplpt,$0
		dc.w	bplpt+2,$0



_cpat		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0

		dc.w	$85df,$fffe
		dc.w	bpl1mod,0

_cScope		dc.w	bplpt,$0
		dc.w	bplpt+2,$0


		; high lighter!
_pathide1	dc.w	$8401,$fffe,$184,$111
		dc.w	$8B01,$fffe,$184,$222
		dc.w	$9201,$fffe,$184,$333
		dc.w	$9901,$fffe,$184,$444
		dc.w	$A001,$fffe,$184,$555
		dc.w	$A701,$fffe,$184,$666
		dc.w	$AE01,$fffe,$184,$777
		dc.w	$B501,$fffe,$184,$888
		dc.w	$BC01,$fffe,$184,$999
		dc.w	$C301,$fffe,$184,$aaa
		dc.w	$C901,$fffe,$180,$00f

_cscreen	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bpl1mod,-40

		dc.w	$D001,$fffe,$180,$000


		dc.w	$D801,$fffe,$184,$aaa
		dc.w	$DF01,$fffe,$184,$999
		dc.w	$E601,$fffe,$184,$888
		dc.w	$ED01,$fffe,$184,$777
		dc.w	$F401,$fffe,$184,$666
		dc.w	$FB01,$fffe,$184,$555,$ffdf,$fffe
		dc.w	$0201,$fffe,$184,$444
		dc.w	$0901,$fffe,$184,$333
		dc.w	$1001,$fffe,$184,$222
		dc.w	$1701,$fffe,$184,$111
		dc.w	$1E01,$fffe,$184,$111
		dc.w	$2501,$fffe,$184,$111

                dc.w    $ffff,$fffe
                dc.w    $ffff,$fffe




;-----------------------------------------------------
; HUD copper list!!!!!!!
;-----------------------------------------------------

_hud_cop	dc.w	bplcon0,$5200	; set as 1 bp display
		dc.w	bplcon1,$0000	; set scroll 0
;		dc.w	bplcon2,7<<3
		dc.w	bpl1mod,(4*40)
		dc.w	bpl2mod,(4*40)
		dc.w	ddfstrt,$38	; datafetch start stop
		dc.w	ddfstop,$d0
		dc.w	diwstrt,$2c81	; window start stop
		dc.w	diwstop,$2cc1

_hud_sprites	dc.w	sprpt,0
		dc.w	sprpt+2,0
		dc.w	sprpt+4,0
		dc.w	sprpt+6,0
		dc.w	sprpt+8,0
		dc.w	sprpt+10,0
		dc.w	sprpt+12,0
		dc.w	sprpt+14,0
		dc.w	sprpt+16,0
		dc.w	sprpt+18,0
		dc.w	sprpt+20,0
		dc.w	sprpt+22,0
		dc.w	sprpt+24,0
		dc.w	sprpt+26,0
		dc.w	sprpt+28,0
		dc.w	sprpt+30,0




_hud_planes	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
		dc.w	bplpt+8,$0
		dc.w	bplpt+10,$0
		dc.w	bplpt+12,$0
		dc.w	bplpt+14,$0
		dc.w	bplpt+16,$0
		dc.w	bplpt+18,$0

		include "gfx/hud.asm"

		; pattern pos planes
		dc.w	$6adf,$fffe
		dc.w	bpl1mod,-40
		dc.w	bpl2mod,-40
		dc.w	bplcon0,$1100
		; sprite colours
		dc.w	$1a2,$f81
		dc.w	$1a4,$f81

		dc.w	$1aa,$f81
		dc.w	$1ac,$f81

		dc.w	$182,$bbb
_grid_planes1c	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	$6bdf,$fffe
_grid_planes1	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	$6edf,$fffe


		dc.w	bplcon0,$3100

_track_plane	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
		dc.w	bplpt+8,$0
		dc.w	bplpt+10,$0

		dc.w	$180,$000
		dc.w	$182,$143
_track_flash	dc.w	$184,$1fc
		dc.w	$186,$1fc
_cue_flash	dc.w	$188,$811
		dc.w	$18a,$811
		dc.w	$18c,$f11
		dc.w	$18e,$f11

		dc.w	$76df,$fffe
		dc.w	bplcon0,$1100
		dc.w	$182,$bbb
_grid_planes2	dc.w	bplpt,$0
		dc.w	bplpt+2,$2
		dc.w	$79df,$fffe
_grid_planes2c	dc.w	bplpt,$0
		dc.w	bplpt+2,$2


		; track mute planes
		dc.w	$7adf,$fffe
		dc.w	bplcon0,$3100

_track_planes	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
		dc.w	bplpt+8,$0
		dc.w	bplpt+10,$0

		dc.w	bpl1mod,(2*40)
		dc.w	bpl2mod,(2*40)

;		track palette
	include "gfx/track-header.asm"

; time to jump?

;		dc.w	$83df,$fffe

		dc.w	copjmp2,0

		dc.w    $ffff,$fffe
                dc.w    $ffff,$fffe

		; **************************************
		; selecta copper
		; **************************************

_select_cop	dc.w	$83df,$fffe
		dc.w	bplcon0,$2100
_select_planes	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
		dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
		dc.w	bpl1mod,40
		dc.w	bpl2mod,40

		include "gfx/select-window.asm"

		dc.w	$8edf,$fffe
		dc.w	bplcon0,$3100
		dc.w	bplcon1,$0040
		dc.w	bpl1mod,-40
		dc.w	bpl2mod,0

_filla_planes	dc.w	bplpt,$0
		dc.w	bplpt+2,$0
_dir_planes	dc.w	bplpt+4,$0
		dc.w	bplpt+6,$0
_fillb_planes	dc.w	bplpt+8,$0
		dc.w	bplpt+10,$0

		dc.w	$184,$fff
		dc.w	$188,$000

_selectaline
		dc.w	$9101,$fffe,$188,$000,$9601,$fffe,$188,$000
		dc.w	$9801,$fffe,$188,$000,$9d01,$fffe,$188,$000
		dc.w	$9f01,$fffe,$188,$000,$a401,$fffe,$188,$000
		dc.w	$a601,$fffe,$188,$000,$ab01,$fffe,$188,$000
		dc.w	$ad01,$fffe,$188,$000,$b201,$fffe,$188,$000
		dc.w	$b401,$fffe,$188,$000,$b901,$fffe,$188,$000
		dc.w	$bb01,$fffe,$188,$000,$c001,$fffe,$188,$000
		dc.w	$c201,$fffe,$188,$000,$c701,$fffe,$188,$000
		dc.w	$c901,$fffe,$188,$000,$ce01,$fffe,$188,$000
		dc.w	$d001,$fffe,$188,$000,$d501,$fffe,$188,$000
		dc.w	$d701,$fffe,$188,$000,$dc01,$fffe,$188,$000
		dc.w	$de01,$fffe,$188,$000,$e301,$fffe,$188,$000
		dc.w	$e501,$fffe,$188,$000,$ea01,$fffe,$188,$000
		dc.w	$ec01,$fffe,$188,$000,$f101,$fffe,$188,$000
		dc.w	$f301,$fffe,$188,$000,$f801,$fffe,$188,$000
		dc.w	$fa01,$fffe,$188,$000,$ff01,$fffe,$188,$000

		; Special instruction for waiting beyond line 255
		dc.w	$ffdf,$fffe

		dc.w	$0101,$fffe,$188,$000,$0601,$fffe,$188,$000
		dc.w	$0801,$fffe,$188,$000,$0d01,$fffe,$188,$000
		dc.w	$0f01,$fffe,$188,$000,$1401,$fffe,$188,$000
		dc.w	$1601,$fffe,$188,$000,$1b01,$fffe,$188,$000
		dc.w	$1d01,$fffe,$188,$000,$2201,$fffe,$188,$000

		dc.w	$2401,$fffe
		dc.w	$188,$333
		dc.w	$2501,$fffe
		dc.w	bplcon0,$0100

		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

_cSwitch	dc.w	$8f01,$fffe
_cSelect	dc.w	$8f01,$fffe
		dc.w	$188,$00f
_cSwitch2	dc.w	$188,$00f
_cSelect2	dc.w	$9601,$fffe
		dc.w	$188,$000


_cSwitch3	dc.w	$ffdf,$fffe
		dc.w	$2401,$fffe
		dc.w	$188,$333

		dc.w	$2501,$fffe
		dc.w	bplcon0,$0100


		dc.w	$ffff,$fffe
		dc.w	$ffff,$fffe

_spritelefttop	dc.w	$6c00,$6f00
				dc.w	%1110000000000000,%0000000000000000
				dc.w	%1100000000000000,%0000000000000000
				dc.w	%1000000000000000,%0000000000000000

_spriterighttop	dc.w	$6c00,$6f00
				dc.w	%0000000000000111,%0000000000000000
				dc.w	%0000000000000011,%0000000000000000
				dc.w	%0000000000000001,%0000000000000000


_spriteleftbot	dc.w	$7700,$7a00
				dc.w	%1000000000000000,%0000000000000000
				dc.w	%1100000000000000,%0000000000000000
				dc.w	%1110000000000000,%0000000000000000

_spriterightbot	dc.w	$7700,$7a00
				dc.w	%0000000000000001,%0000000000000000
				dc.w	%0000000000000011,%0000000000000000
				dc.w	%0000000000000111,%0000000000000000


_spriteblank	dc.w	0,0

_spritelist		dc.l	_spritelefttop
				dc.l	_spriterighttop
				dc.l	_spriteleftbot
				dc.l	_spriterightbot
				dc.l	_spriteblank
				dc.l	_spriteblank
				dc.l	_spriteblank
				dc.l	_spriteblank


				; hud gfx
_hud			incbin	"gfx/hud.raw"
				include "gfx/hud_chip.asm"

_trackoff		incbin	"gfx/track-header-off.raw"
_trackon		incbin	"gfx/track-header-on.raw"
_font_digi		incbin	"gfx/font-digi-large.raw"
_select			incbin	"gfx/select-window.raw"
_selectfilla	dc.b	$80
				dcb.b	40-2,0
				dc.b	$01
_selectfillb	dc.b	$7f
				dcb.b	40-2,$ff
				dc.b	$fe

_track_fill	dcb.b	40,$ff
_track_pos	dcb.b	40,$00
_track_cue	dcb.b	40,$00


_song_grid	dcb.b	40,$aa
_song_grid_clr	dcb.b	40,$00
		; track area
_track		dcb.b	40*9*3



; Another magic section name '.bss_chip' to get a chip RAM BSS hunk.
	section .bss_chip,bss_c

_basepattern	ds.b	40*PT_LineHeight

_pattern1_start	ds.b	40*PT_LineHeight*PT_Offset
_pattern1		ds.b	40*PT_LineHeight*64
				ds.b	40*PT_LineHeight*3
_pattern2_start	ds.b	40*PT_LineHeight*PT_Offset
_pattern2		ds.b	40*PT_LineHeight*64
				ds.b	40*PT_LineHeight*13


_pScope1		ds.b	40*PT_LineHeight*10
_pScope2		ds.b	40*PT_LineHeight*10

_Sample		dcb.b	$100,0

		even
