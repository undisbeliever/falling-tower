
.include "metasprite.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/synthetic.inc"

.setcpu "65816"

.module MetaSprite

.define MSDP MetaSpriteDpOffset + MetaSpriteStruct


.include "palette.asm"
.include "render.asm"
.include "vram.asm"
.include "dma.asm"


; DB = $7E
.A16
.I16
.routine Reset
	Reset__Render
	Reset__Palette
	Reset__Vram

	RTS
.endroutine


; A = FrameSet Id
; Y = palette Id
; DB = $7E
; DP: MetaSpriteStruct address - MetaSpriteDpOffset
.A16
.I16
.routine Init
	STZ	z:MSDP::status
	STZ	z:MSDP::currentFrame

	; Determine FrameSet address
	CMP	#.loword(MetaSpriteFrameSetTable_end - MetaSpriteFrameSetTable) / 2
	IF_GE
		LDA	#0
	ENDIF

	ASL
	TAX
	LDA	f:MetaSpriteFrameSetTable, X
	STA	z:MSDP::frameSet
	TAX

	SEP	#$20
.A8

	; Determine Palette address
	TYA
	CMP	f:frameSetOffset + MetaSprite__FrameSet::nPalettes, X
	IF_GE
		LDA	#0
	ENDIF
.A16
	REP	#$30
	AND	#$00FF
	ASL
	; Carry Clear
	ADC	f:frameSetOffset + MetaSprite__FrameSet::paletteList, X
	TAX
	LDA	f:paletteListOffset, X
	STA	z:MSDP::palette
	RTS
.endroutine


; DB = $7E
; DP: MetaSpriteStruct address - MetaSpriteDpOffset
.A16
.I16
.routine Activate
	LDA	z:MSDP::palette
	JSR	SetPaletteAddress

::_Activate_AfterPalette:
	LDX	z:MSDP::frameSet
	LDA	f:frameSetOffset + MetaSprite__FrameSet::tilesetLifestyle, X
	AND	#%110
	TAX
	JMP	(.loword(FunctionTable), X)

.rodata
FunctionTable:
	.addr	Activate_FixedTileset
	.addr	Activate_Dynamic
	.addr	Activate_DynamicFixed
	.addr	Activate_Dynamic
.code

Activate_Dynamic:
Activate_DynamicFixed:
	; ::TODO implement::
	RTS
.endroutine



; DB = $7E
; DP: MetaSpriteStruct address - MetaSpriteDpOffset
.A16
.I16
.routine Deactivate
	RemovePalette
	RemoveTileset
.endroutine


; A = Frame Id
; DB = $7E
; DP: MetaSpriteStruct address - MetaSpriteDpOffset
.A16
.I16
.routine SetFrame
	LDX	z:MSDP::frameSet
	BEQ	Failure

	SEP	#$20
.A8
	CMP	f:frameSetOffset + MetaSprite__FrameSet::nFrames, X
	REP	#$20
.A16
	BGE	Failure

	AND	#$00FF
	ASL
	ADC	f:frameSetOffset + MetaSprite__FrameSet::frameList, X
	TAX
	LDA	f:frameListOffset, X

	STA	z:MSDP::currentFrame
	BEQ	Success

	.assert METASPRITE_STATUS_DYNAMIC_TILESET_FLAG = $40, error, "bad code"
	BIT	z:MSDP::status - 1
	IF_V_SET
		; ::TODO handle dynamic tilesets::
		STP
	ENDIF

	; If Dynamic Tileset flag is not set then
	;	1) The metasprite is unallocated
	; or	2) The metasprite uses a fixed tileset
	; either way no uploads are needed

Success:
	SEC
	CLC

Failure:
	CLC
Return:
	RTS
.endroutine

.assert .loword(MetaSpriteFrameSetTable) > 0, lderror, "MetaSpriteFrameSetTable cannot be NULL"


.segment METASPRITE_FRAMESET_DATA_BLOCK
	frameSetOffset = .bankbyte(*) << 16

.segment METASPRITE_FRAME_LIST_BLOCK
	frameListOffset = .bankbyte(*) << 16

.segment METASPRITE_PALETTE_LIST_BLOCK
	paletteListOffset = .bankbyte(*) << 16

.segment METASPRITE_FRAME_DATA_BLOCK
	frameDataOffset = .bankbyte(*) << 16

.segment METASPRITE_FRAME_OBJECTS_BLOCK
	fobjDataOffset	= .bankbyte(*) << 16

.segment METASPRITE_PALETTE_DATA_BLOCK
	paletteDataBank = .bankbyte(*)

.segment METASPRITE_TILESET_BLOCK
	tilesetBankOffset = .bankbyte(*) << 16

.segment METASPRITE_DMA_TABLE_BLOCK
	dmaTableBank = .bankbyte(*)

.endmodule

