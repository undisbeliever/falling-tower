; Unit test Metasprite Palette allocations

.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "metasprite/metasprite.h"

.include "tests/tests.h"
.include "tests/static-random.inc"
.include "tests/metasprite/metasprite.h"

.setcpu "65816"

entity0 := UnitTest_MetaSprite::entities
entity1 := UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 1
entity2 := UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 2
entity3 := UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 3
entity4 := UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 4
entity5 := UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 5
entity6 := UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 6
entity7 := UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 7
entity8 := UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 8
entity9 := UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 9
entity10:= UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 10

MetaSprite__RemovePalette := MetaSprite::Deactivate

.module UnitTest_MetaSprite_Palette

	UnitTestHeader MetaSprite_Palette
		UnitTest	SetPaletteAddress
		UnitTest	SetPaletteAddress_Duplicat
		UnitTest	SetPaletteAddress_Overflow
		UnitTest	SetPaletteAddress_NULL
		UnitTest	RemovePalette
		UnitTest	RemovePalette_DoubleFree
		UnitTest	ReloadPalettes
	EndUnitTestHeader


.segment "SHADOW"

.code

.routine SetPaletteAddress
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#1
	TSB	MetaSprite::updatePaletteBufferOnZero

	JSR	_Load8Palettes
	BCC	Failure

	; Test palette buffer update request is sent
	LDA	MetaSprite::updatePaletteBufferOnZero
	AND	#$00FF
	BNE	Failure

	; Test that palette data is in paletteBuffer
	.repeat 8, i
		LDY	#.ident(.sprintf("entity%i", i))
		LDX	#.loword(.ident(.sprintf("Palette%i", i)))
		JSR	_CheckPalette
		BCC	Failure
	.endrepeat

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.routine SetPaletteAddress_Duplicat
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_Load8Palettes
	BCC	Failure

	; Reset buffer update request
	LDA	#1
	TSB	MetaSprite::updatePaletteBufferOnZero

	; Load an existing palette (Palette 3) into a new entity

	LDA	#entity9
	TCD
	LDA	#.loword(Palette3)
	JSR	MetaSprite::SetPaletteAddress
	BCC	Failure

	; Load an existing palette (Palette 4) into a new entity

	LDA	#entity10
	TCD
	LDA	#.loword(Palette4)
	JSR	MetaSprite::SetPaletteAddress
	BCC	Failure


	; Check that the buffer update request has not been sent
	LDA	MetaSprite::updatePaletteBufferOnZero
	AND	#$00FF
	BEQ	Failure

	; Check that the metasprites point to the right palettes

	LDY	#entity9
	LDX	#.loword(Palette3)
	JSR	_CheckPalette
	BCC	Failure

	LDY	#entity10
	LDX	#.loword(Palette4)
	JSR	_CheckPalette
	BCC	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.routine SetPaletteAddress_Overflow
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_Load8Palettes
	BCC	Failure

	; Try to load a 9th palette

	LDA	#entity8
	TCD
	LDA	#.loword(Palette8)
	JSR	MetaSprite::SetPaletteAddress

	; But it can't so we can finally return a carry clear
	BCS	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.routine SetPaletteAddress_NULL
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_Load8Palettes
	BCC	Failure

	LDA	#entity0
	TCD
	LDA	#0
	JSR	MetaSprite::SetPaletteAddress
	; This will return false
	BCS	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.routine RemovePalette
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_Load8Palettes
	BCC	Failure

	; Free entity 0
	LDA	#entity0
	TCD
	JSR	MetaSprite__RemovePalette

	; Now the 9th palette will load successfully
	LDA	#entity8
	TCD
	LDA	#.loword(Palette8)
	JSR	MetaSprite::SetPaletteAddress
	BCC	Failure

	LDY	#entity8
	LDX	#.loword(Palette8)
	JSR	_CheckPalette
	BCC	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.routine RemovePalette_DoubleFree
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_Load8Palettes
	BCC	Failure

	; Free entity 0 twice
	LDA	#entity0
	TCD
	JSR	MetaSprite__RemovePalette
	JSR	MetaSprite__RemovePalette

	; Now the 9th palette will load successfully
	LDA	#entity8
	TCD
	LDA	#.loword(Palette8)
	JSR	MetaSprite::SetPaletteAddress
	BCC	Failure

	; Test that the palette status flag is now empty
	LDA	#METASPRITE_STATUS_PALETTE_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BEQ	Failure

	LDY	#entity8
	LDX	#.loword(Palette8)
	JSR	_CheckPalette
	BCC	Failure

	; Test that the palette status flag is still empty
	LDA	#METASPRITE_STATUS_PALETTE_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BEQ	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.routine ReloadPalettes
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_Load8Palettes
	BCC	Failure

	; Dirty palette buffer
	LDX	#MetaSprite::paletteBuffer_size - 2
	REPEAT
		DEC
		STA	a:.loword(MetaSprite::paletteBuffer), X
		DEX
		DEX
	UNTIL_ZERO

	LDA	#1
	TSB	MetaSprite::updatePaletteBufferOnZero


	JSR	MetaSprite::ReloadPalettes


	; Test palette buffer update request is sent
	LDA	MetaSprite::updatePaletteBufferOnZero
	AND	#$00FF
	BNE	Failure

	; Test that palette data is in paletteBuffer
	.repeat 8, i
		LDY	#.ident(.sprintf("entity%i", i))
		LDX	#.loword(.ident(.sprintf("Palette%i", i)))
		JSR	_CheckPalette
		BCC	Failure
	.endrepeat

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


; Loads 8 palettes to entities 0-7
.A16
.I16
.routine _Load8Palettes
	.repeat 8, i
		LDA	#.ident(.sprintf("entity%i", i))
		TCD
		LDA	#.loword(.ident(.sprintf("Palette%i", i)))
		JSR	MetaSprite::SetPaletteAddress
		BCC	Failure
	.endrepeat

	SEC
Failure:
	RTS
.endroutine



; IN: Y address of entity
; IN: X address of buffer
; OUT: c set if palette exits in palete buffer in given location
.A16
.I16
.routine _CheckPalette
tmp_counter := tmp6
	; check palette is set
	LDA	#METASPRITE_STATUS_PALETTE_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BEQ	Failure

	; Y = (entity->charAttrOffset & OAM_CHARATTR_PALETTE_MASK) * 32 / 512 + 2
	LDA	a:0 + ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset, Y
	AND	#OAM_CHARATTR_PALETTE_MASK
	LSR
	LSR
	LSR
	LSR
	INC
	INC
	TAY

	LDA	#15
	STA	tmp_counter
	REPEAT
		LDA	f:paletteBankOffset, X
		CMP	MetaSprite::paletteBuffer, Y
		BNE	Failure

		INY
		INY
		INX
		INX

		DEC	tmp_counter
	UNTIL_ZERO

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.segment METASPRITE_PALETTE_DATA_BLOCK
.assert .loword(Palette0) <> 0, error, "Bad value"

paletteBankOffset := .bankbyte(*) << 16

; 9 random palettes
.repeat 9, i
	.proc .ident(.sprintf("Palette%i", i))
		.repeat	15
			STATIC_RANDOM_MIN_MAX rng, 0, $7FFF
			.word	rng
		.endrepeat
	.endproc
.endrepeat

.endmodule

; vim: set ft=asm:

