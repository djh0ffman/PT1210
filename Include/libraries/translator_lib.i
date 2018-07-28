_LVOTranslate	EQU	-30

CALLTRANS	MACRO
	move.l	_TranslatorBase,a6
	jsr	_LVO\1(a6)
	ENDM

TRANSNAME	MACRO
	dc.b	'translator.library',0
	ENDM
