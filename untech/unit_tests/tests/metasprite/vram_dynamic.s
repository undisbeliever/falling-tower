; Unit test Metasprite dynamic VRAM allocations

.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "metasprite/metasprite.h"

.include "tests/tests.h"
.include "tests/metasprite/metasprite.h"
.include "tests/metasprite/_test_data.h"

.setcpu "65816"

.import MetaSprite__dmaTableIndex
.import MetaSprite__dmaTable_vramAddress
.import MetaSprite__dmaTable_tablePtr

.module UnitTest_MetaSprite_Fixed_Tileset

	UnitTestHeader MetaSprite_Fixed_Tileset
		UnitTest	Upload_OneTile
		UnitTest	Upload_TwoTiles
		UnitTest	Upload_OneRow
		UnitTest	Upload_TwoRows
		UnitTest	Upload_UniqueSlotsTest
		UnitTest	Upload_OverflowTiles
		UnitTest	Upload_OverflowRows
		UnitTest	Upload_RowsTilesSeperate1
		UnitTest	Upload_RowsTilesSeperate2
		UnitTest	SetFrame_OneTile
		UnitTest	SetFrame_TwoTiles
		UnitTest	SetFrame_OneRow
		UnitTest	SetFrame_TwoRows
		UnitTest	SetFrameSameTiles_OneTile
		UnitTest	SetFrameSameTiles_TwoTiles
		UnitTest	SetFrameSameTiles_OneRow
		UnitTest	SetFrameSameTiles_TwoRows
		UnitTest	RemoveTileset_OneTile
		UnitTest	RemoveTileset_TwoTiles
		UnitTest	RemoveTileset_OneRow
		UnitTest	RemoveTileset_TwoRows
		UnitTest	RemoveTileset_DoubleFree
		UnitTest	CheckDynamicFixed_Tiles
		UnitTest	CheckDynamicFixed_Rows
	EndUnitTestHeader


.segment "SHADOW"

.code

.define Data UnitTest_MetaSprite_Data


.A8
.I16
.proc Upload_OneTile
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	LDX	#.loword(Data::Tileset_Dynamic_OneTile_0_DMA0)
	JSR	_UploadDynamicSingleAndTest

	RTS
.endproc


.A8
.I16
.proc Upload_TwoTiles
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoTiles
	LDX	#.loword(Data::Tileset_Dynamic_TwoTiles_0_DMA0)
	LDY	#.loword(Data::Tileset_Dynamic_TwoTiles_0_DMA1)
	JSR	_UploadDynamicDualAndTest

	RTS
.endproc


.A8
.I16
.proc Upload_OneRow
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_OneRow
	LDX	#.loword(Data::Tileset_Dynamic_OneRow_0_DMA0)
	JSR	_UploadDynamicSingleAndTest

	RTS
.endproc


.A8
.I16
.proc Upload_TwoRows
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoRows
	LDX	#.loword(Data::Tileset_Dynamic_TwoRows_0_DMA0)
	LDY	#.loword(Data::Tileset_Dynamic_TwoRows_0_DMA1)
	JSR	_UploadDynamicDualAndTest

	RTS
.endproc


.A8
.I16
.proc Upload_UniqueSlotsTest
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillTileSlots
	BCC	Failure

	JSR	_FillRowSlots
	BCC	Failure

	; Test all entities have unique tilesets
	LDA	#.loword(entities)
	REPEAT
		TCD

		REPEAT
			CLC
			ADC	#.sizeof(ExampleEntity)

			TAX
			LDY	a:ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset, X
			CPY	z:ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset
			BEQ	Failure

			CMP	#entities + (N_FILLED_SLOT_ENTITIES - 1) * .sizeof(ExampleEntity)
		UNTIL_GE

		TDC
		CLC
		ADC	#.sizeof(ExampleEntity)
		CMP	#entities + (N_FILLED_SLOT_ENTITIES - 1) * .sizeof(ExampleEntity)
	UNTIL_GE

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc Upload_OverflowTiles
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillTileSlots
	BCC	Failure

	; Try and fail to load tiles

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	JSR	_InitAndActivateFrame0
	BCS	Failure		; This should return false

	; Test vram set flag clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoTiles
	JSR	_InitAndActivateFrame0
	BCS	Failure		; This should return false

	; Test vram set flag clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc Upload_OverflowRows
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillRowSlots
	BCC	Failure

	; Try and fail to load tiles

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_OneRow
	JSR	_InitAndActivateFrame0
	BCS	Failure		; This should return false

	; Test vram set flag clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoRows
	JSR	_InitAndActivateFrame0
	BCS	Failure		; This should return false

	; Test vram set flag clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc

;; Test that the rows and tiles are separate
.A8
.I16
.proc	Upload_RowsTilesSeperate1
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillTileSlots
	BCC	Failure

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoRows
	LDX	#.loword(Data::Tileset_Dynamic_TwoRows_0_DMA0)
	LDY	#.loword(Data::Tileset_Dynamic_TwoRows_0_DMA1)
	JSR	_UploadDynamicDualAndTest

	; pass through
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc	Upload_RowsTilesSeperate2
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillRowSlots
	BCC	Failure

	; Try and fail to load tiles
	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoTiles
	LDX	#.loword(Data::Tileset_Dynamic_TwoTiles_0_DMA0)
	LDY	#.loword(Data::Tileset_Dynamic_TwoTiles_0_DMA1)
	JSR	_UploadDynamicDualAndTest

	; pass through
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc SetFrameSameTiles_OneTile
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	JSR	_InitAndActivateFrame0
	BCC	Failure

	; Frame 2 uses same tileset as frame 0
	; Test that the dma buffer was not updated

	STZ	MetaSprite__dmaTableIndex

	LDA	#2
	JSR	MetaSprite::SetFrame
	BCC	Failure

	LDA	MetaSprite__dmaTableIndex
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc SetFrameSameTiles_TwoTiles
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoTiles
	JSR	_InitAndActivateFrame0
	BCC	Failure

	; Frame 2 uses same tileset as frame 0
	; Test that the dma buffer was not updated

	STZ	MetaSprite__dmaTableIndex

	LDA	#2
	JSR	MetaSprite::SetFrame
	BCC	Failure

	LDA	MetaSprite__dmaTableIndex
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc SetFrameSameTiles_OneRow
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_OneRow
	JSR	_InitAndActivateFrame0
	BCC	Failure

	; Frame 2 uses same tileset as frame 0
	; Test that the dma buffer was not updated

	STZ	MetaSprite__dmaTableIndex

	LDA	#2
	JSR	MetaSprite::SetFrame
	BCC	Failure

	LDA	MetaSprite__dmaTableIndex
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc SetFrameSameTiles_TwoRows
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoRows
	JSR	_InitAndActivateFrame0
	BCC	Failure

	; Frame 2 uses same tileset as frame 0
	; Test that the dma buffer was not updated

	STZ	MetaSprite__dmaTableIndex

	LDA	#2
	JSR	MetaSprite::SetFrame
	BCC	Failure

	LDA	MetaSprite__dmaTableIndex
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc SetFrame_OneTile
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	JSR	_InitAndActivateFrame0
	BCC	Failure

	; Test that the dma buffer was updated
	STZ	MetaSprite__dmaTableIndex

	LDA	#1
	JSR	MetaSprite::SetFrame
	BCC	Failure

	LDA	MetaSprite__dmaTableIndex
	CMP	#2
	BNE	Failure

	LDA	#.loword(Data::Tileset_Dynamic_OneTile_1_DMA0)
	CMP	MetaSprite__dmaTable_tablePtr
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc SetFrame_TwoTiles
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoTiles
	JSR	_InitAndActivateFrame0
	BCC	Failure

	; Test that the dma buffer was updated
	STZ	MetaSprite__dmaTableIndex

	LDA	#1
	JSR	MetaSprite::SetFrame
	BCC	Failure

	LDA	MetaSprite__dmaTableIndex
	CMP	#4
	BNE	Failure

	LDA	#.loword(Data::Tileset_Dynamic_TwoTiles_1_DMA0)
	CMP	MetaSprite__dmaTable_tablePtr
	BNE	Failure

	LDA	#.loword(Data::Tileset_Dynamic_TwoTiles_1_DMA1)
	CMP	MetaSprite__dmaTable_tablePtr + 2
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc SetFrame_OneRow
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_OneRow
	JSR	_InitAndActivateFrame0
	BCC	Failure

	; Test that the dma buffer was updated
	STZ	MetaSprite__dmaTableIndex

	LDA	#1
	JSR	MetaSprite::SetFrame
	BCC	Failure

	LDA	MetaSprite__dmaTableIndex
	CMP	#2
	BNE	Failure

	LDA	#.loword(Data::Tileset_Dynamic_OneRow_1_DMA0)
	CMP	MetaSprite__dmaTable_tablePtr
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc SetFrame_TwoRows
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#UnitTest_MetaSprite::entities
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoRows
	JSR	_InitAndActivateFrame0
	BCC	Failure

	; Test that the dma buffer was updated
	STZ	MetaSprite__dmaTableIndex

	LDA	#1
	JSR	MetaSprite::SetFrame
	BCC	Failure

	LDA	MetaSprite__dmaTableIndex
	CMP	#4
	BNE	Failure

	LDA	#.loword(Data::Tileset_Dynamic_TwoRows_1_DMA0)
	CMP	MetaSprite__dmaTable_tablePtr
	BNE	Failure

	LDA	#.loword(Data::Tileset_Dynamic_TwoRows_1_DMA1)
	CMP	MetaSprite__dmaTable_tablePtr + 2
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc RemoveTileset_OneTile
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillTileSlots
	BCC	Failure


	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	JSR	_InitAndActivateFrame0
	BCS	Failure			; This should fail


	; Remove a single tile
	LDA	#entity_OneTile
	TCD
	JSR	MetaSprite::Deactivate

	; test vram status flags are clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure


	; Trying to create a double tile should fail
	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoTiles
	JSR	_InitAndActivateFrame0
	BCS	Failure			; This should fail


	; Remove a second single tile
	LDA	#entity_OneTile + .sizeof(ExampleEntity)
	TCD
	JSR	MetaSprite::Deactivate

	; test vram status flags are clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure

	; Trying to create a double tile will now succeed
	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoTiles
	LDX	#.loword(Data::Tileset_Dynamic_TwoTiles_0_DMA0)
	LDY	#.loword(Data::Tileset_Dynamic_TwoTiles_0_DMA1)
	JSR	_UploadDynamicDualAndTest
	BCC	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc RemoveTileset_TwoTiles
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillTileSlots
	BCC	Failure

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	JSR	_InitAndActivateFrame0
	BCS	Failure			; This should fail


	; Remove a double tile
	LDA	#entity_TwoTiles
	TCD
	JSR	MetaSprite::Deactivate

	; test vram status flags are clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure

	; Now we can make 2 tiles

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	LDX	#.loword(Data::Tileset_Dynamic_OneTile_0_DMA0)
	JSR	_UploadDynamicSingleAndTest
	BCC	Failure

	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	LDX	#.loword(Data::Tileset_Dynamic_OneTile_0_DMA0)
	JSR	_UploadDynamicSingleAndTest
	BCC	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc RemoveTileset_OneRow
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillRowSlots
	BCC	Failure

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_OneRow
	JSR	_InitAndActivateFrame0
	BCS	Failure			; This should fail


	; Remove a single tile
	LDA	#entity_OneRow
	TCD
	JSR	MetaSprite::Deactivate

	; test vram status flags are clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure


	; Trying to create a double tile should fail
	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoRows
	JSR	_InitAndActivateFrame0
	BCS	Failure			; This should fail


	; Remove a second single tile
	LDA	#entity_OneRow + .sizeof(ExampleEntity)
	TCD
	JSR	MetaSprite::Deactivate

	; test vram status flags are clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure

	; Trying to create a double tile will now succeed
	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_TwoRows
	LDX	#.loword(Data::Tileset_Dynamic_TwoRows_0_DMA0)
	LDY	#.loword(Data::Tileset_Dynamic_TwoRows_0_DMA1)
	JSR	_UploadDynamicDualAndTest
	BCC	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc RemoveTileset_TwoRows
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillRowSlots
	BCC	Failure

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_OneRow
	JSR	_InitAndActivateFrame0
	BCS	Failure			; This should fail


	; Remove a two-row entity
	LDA	#entity_TwoRows
	TCD
	JSR	MetaSprite::Deactivate

	; test vram status flags are clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure

	; Now we can add 2 tiles

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_OneRow
	LDX	#.loword(Data::Tileset_Dynamic_OneRow_0_DMA0)
	JSR	_UploadDynamicSingleAndTest
	BCC	Failure

	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Dynamic_OneRow
	LDX	#.loword(Data::Tileset_Dynamic_OneRow_0_DMA0)
	JSR	_UploadDynamicSingleAndTest
	BCC	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc RemoveTileset_DoubleFree
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillTileSlots
	BCC	Failure

	; Remove a single tile
	LDA	#entity_OneTile
	TCD
	JSR	MetaSprite::Deactivate

	; test vram status flags are clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure


	; Double free
	JSR	MetaSprite::Deactivate


	; Make sure we can only upload one tile
	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	LDX	#.loword(Data::Tileset_Dynamic_OneTile_0_DMA0)
	JSR	_UploadDynamicSingleAndTest
	BCC	Failure


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Dynamic_OneTile
	LDX	#.loword(Data::Tileset_Dynamic_OneTile_0_DMA0)
	JSR	_UploadDynamicSingleAndTest
	BCS	Failure		; This should return false

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc CheckDynamicFixed_Tiles
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillTileSlots
	BCC	Failure

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Fixed_OneTile_1
	JSR	_InitAndActivateFrame0
	BCS	Failure			; This should fail


	; Remove a one block entity
	LDA	#entity_OneTile
	TCD
	JSR	MetaSprite::Deactivate


	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Fixed_OneTile_1
	JSR	_InitAndActivateFrame0
	BCC	Failure


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Fixed_TwoTiles_1
	JSR	_InitAndActivateFrame0
	BCS	Failure		; This should fail


	; Remove a two block entity
	LDA	#entity_TwoTiles
	TCD
	JSR	MetaSprite::Deactivate


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Fixed_TwoTiles_1
	JSR	_InitAndActivateFrame0
	BCC	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


.A8
.I16
.proc CheckDynamicFixed_Rows
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	_FillRowSlots
	BCC	Failure

	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Fixed_OneRow_1
	JSR	_InitAndActivateFrame0
	BCS	Failure			; This should fail


	; Remove a one block entity
	LDA	#entity_OneRow
	TCD
	JSR	MetaSprite::Deactivate


	LDA	#entity_Overflow
	TCD
	LDA	#Data::FrameSets::Fixed_OneRow_1
	JSR	_InitAndActivateFrame0
	BCC	Failure


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Fixed_TwoRows_1
	JSR	_InitAndActivateFrame0
	BCS	Failure		; This should fail


	; Remove a two block entity
	LDA	#entity_TwoRows
	TCD
	JSR	MetaSprite::Deactivate


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Fixed_TwoRows_1
	JSR	_InitAndActivateFrame0
	BCC	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc



; IN
;  A - frameset
; DP - the entity
; OUT:
;  c set if MetaSprite__Activate returns true
.A16
.I16
.proc _InitAndActivateFrame0
	LDY	#0
	JSR	MetaSprite::Init
	LDA	#0
	JSR	MetaSprite::SetFrame
	JMP	MetaSprite::Activate
.endproc


; IN:
;  A - frameset
;  X - dmaTable1
;  DP- the entity
; OUT:
;  c set if successful and table matches
.A16
.I16
.proc _UploadDynamicSingleAndTest
tmp_index	:= tmp5
tmp_table0	:= tmp6

	STX	tmp_table0

	LDX	MetaSprite__dmaTableIndex
	STX	tmp_index


	; IN : A, DP
	JSR	_InitAndActivateFrame0
	BCC	Failure


	LDA	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	AND	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	CMP	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	BNE	Failure


	; Test that the dma table has been updated
	LDX	MetaSprite__dmaTableIndex
	DEX
	DEX

	CPX	tmp_index
	BNE	Failure

	LDA	MetaSprite__dmaTable_tablePtr, X
	CMP	tmp_table0
	BNE	Failure

	; Test that the VRAM address is correct
	LDA	z:ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset
	AND	#OAM_CHARATTR_CHAR_MASK
	ASL
	ASL
	ASL
	ASL
	; carry clear
	ADC	#METASPRITE_VRAM_WORD_ADDRESS

	CMP	MetaSprite__dmaTable_vramAddress, X
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


; IN:
;  A - frameset
;  X - dmaTable1
;  Y - dmaTable2
;  DP- the entity
; OUT:
;  c set if successful and table matches
.proc _UploadDynamicDualAndTest
tmp_index	:= tmp4
tmp_table0	:= tmp5
tmp_table1	:= tmp6

	STX	tmp_table0
	STY	tmp_table1

	LDX	MetaSprite__dmaTableIndex
	STX	tmp_index


	; IN : A, DP
	JSR	_InitAndActivateFrame0
	BCC	Failure

	LDA	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	AND	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	CMP	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	BNE	Failure

	; Test that the dma table has been updated twice

	LDX	MetaSprite__dmaTableIndex
	DEX
	DEX
	DEX
	DEX

	CPX	tmp_index
	BNE	Failure

	LDA	MetaSprite__dmaTable_tablePtr, X
	CMP	tmp_table0
	BNE	Failure

	LDA	MetaSprite__dmaTable_tablePtr + 2, X
	CMP	tmp_table1
	BNE	Failure


	; Test that the VRAM address is correct
	LDA	z:ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset
	AND	#OAM_CHARATTR_CHAR_MASK
	ASL
	ASL
	ASL
	ASL
	; carry clear
	ADC	#METASPRITE_VRAM_WORD_ADDRESS

	CMP	MetaSprite__dmaTable_vramAddress, X
	BNE	Failure


	LDA	z:ExampleEntity::metasprite + MetaSpriteStruct::blockTwoCharAttrOffset
	AND	#OAM_CHARATTR_CHAR_MASK
	ASL
	ASL
	ASL
	ASL
	; carry clear
	ADC	#METASPRITE_VRAM_WORD_ADDRESS

	CMP	MetaSprite__dmaTable_vramAddress + 2, X
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc



;; Will fill the tile slots
;; With 4 single and 5 dual metaSprites
;;
;; The tilesets used MUST NOT already exist in the system
;;
;; entities(0) - entities(3) are OneTile
;; entities(4) - entities(9) are TwoTiles

.A16
.I16
.proc _FillTileSlots
	nSingle = 4
	nDual = 6
	nEntities = nSingle + nDual
	.assert METASPRITE_VRAM_TILE_SLOTS = nSingle + nDual * 2, error, "Bad Values"

	.assert entity_TwoTiles = entity_OneTile + .sizeof(ExampleEntity) * nSingle, error, "Bad Variable"

	LDA	#entity_OneTile

	REPEAT
		TCD
		LDA	#Data::FrameSets::Dynamic_OneTile
		LDX	#.loword(Data::Tileset_Dynamic_OneTile_0_DMA0)
		JSR	_UploadDynamicSingleAndTest
		IF_C_CLEAR
			; C clear
			RTS
		ENDIF

		; prevent buffer overruns
		STZ	MetaSprite__dmaTableIndex

		TDC
		CLC
		ADC	#.sizeof(ExampleEntity)
		CMP	#entity_TwoTiles
	UNTIL_EQ

	REPEAT
		TCD
		LDA	#Data::FrameSets::Dynamic_TwoTiles
		LDX	#.loword(Data::Tileset_Dynamic_TwoTiles_0_DMA0)
		LDY	#.loword(Data::Tileset_Dynamic_TwoTiles_0_DMA1)
		JSR	_UploadDynamicDualAndTest
		IF_C_CLEAR
			; C clear
			RTS
		ENDIF

		; prevent buffer overruns
		STZ	MetaSprite__dmaTableIndex

		TDC
		CLC
		ADC	#.sizeof(ExampleEntity)
		CMP	#entity_OneTile + .sizeof(ExampleEntity) * nEntities
	UNTIL_EQ

	SEC
	RTS
.endproc



;; Will fill all the row slots
;; With 2 single and 7 dual metaSprites
;;
;; The tilesets used MUST NOT already exist in the system
;;
;; entities(10) - entities(13) are OneRow
;; entities(14) - entities(18) are TwoRows
.A16
.I16
.proc _FillRowSlots
	nSingle = 4
	nDual = 5
	nEntities = nSingle + nDual
	.assert METASPRITE_VRAM_ROW_SLOTS = nSingle + nDual * 2, error, "Bad Values"

	.assert entity_OneRow = entity_OneTile + .sizeof(ExampleEntity) * _FillTileSlots::nEntities, error, "Bad Variable"
	.assert entity_TwoRows = entity_OneRow + .sizeof(ExampleEntity) * nSingle, error, "Bad Variable"
	.assert entity_Overflow = entity_TwoRows + .sizeof(ExampleEntity) * nDual, error, "Bad Variable"


	LDA	#entity_OneRow

	REPEAT
		TCD
		LDA	#Data::FrameSets::Dynamic_OneRow
		LDX	#.loword(Data::Tileset_Dynamic_OneRow_0_DMA0)
		JSR	_UploadDynamicSingleAndTest
		IF_C_CLEAR
			; C clear
			RTS
		ENDIF

		; prevent buffer overruns
		STZ	MetaSprite__dmaTableIndex

		TDC
		CLC
		ADC	#.sizeof(ExampleEntity)
		CMP	#entity_TwoRows
	UNTIL_EQ

	REPEAT
		TCD
		LDA	#Data::FrameSets::Dynamic_TwoRows
		LDX	#.loword(Data::Tileset_Dynamic_TwoRows_0_DMA0)
		LDY	#.loword(Data::Tileset_Dynamic_TwoRows_0_DMA1)
		JSR	_UploadDynamicDualAndTest
		IF_C_CLEAR
			; C clear
			RTS
		ENDIF

		; prevent buffer overruns
		STZ	MetaSprite__dmaTableIndex

		TDC
		CLC
		ADC	#.sizeof(ExampleEntity)
		CMP	#entity_OneRow + .sizeof(ExampleEntity) * nEntities
	UNTIL_EQ

	SEC
	RTS
.endproc


entities = UnitTest_MetaSprite::entities

entity_OneTile = UnitTest_MetaSprite::entities
entity_TwoTiles = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 4
entity_OneRow = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 10
entity_TwoRows = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 14
entity_Overflow = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 19
entity_Overflow2 = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 20

N_FILLED_SLOT_ENTITIES = 19

.assert N_ENTITIES >= 21, error, "Not Enough entities"

.endmodule

; vim: set ft=asm:

