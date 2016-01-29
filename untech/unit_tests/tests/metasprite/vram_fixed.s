; Unit test Metasprite Fixed tileset VRAM allocations

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
		UnitTest	Upload_OverflowTiles
		UnitTest	Upload_OverflowRows
		UnitTest	Upload_RowsTilesSeperate1
		UnitTest	Upload_RowsTilesSeperate2
		UnitTest	Upload_DetectDuplicate
		UnitTest	RemoveTileset_OneTile
		UnitTest	RemoveTileset_TwoTiles
		UnitTest	RemoveTileset_OneRow
		UnitTest	RemoveTileset_TwoRows
		UnitTest	RemoveTileset_DoubleFree
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
	LDA	#Data::FrameSets::Fixed_OneTile_0
	LDX	#.loword(Data::Tileset_Fixed_OneTile_0_DMA0)
	JSR	_UploadUniqueSingleAndTest

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
	LDA	#Data::FrameSets::Fixed_TwoTiles_0
	LDX	#.loword(Data::Tileset_Fixed_TwoTiles_0_DMA0)
	LDY	#.loword(Data::Tileset_Fixed_TwoTiles_0_DMA1)
	JSR	_UploadUniqueDualAndTest

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
	LDA	#Data::FrameSets::Fixed_OneRow_0
	LDX	#.loword(Data::Tileset_Fixed_OneRow_0_DMA0)
	JSR	_UploadUniqueSingleAndTest

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
	LDA	#Data::FrameSets::Fixed_TwoRows_0
	LDX	#.loword(Data::Tileset_Fixed_TwoRows_0_DMA0)
	LDY	#.loword(Data::Tileset_Fixed_TwoRows_0_DMA1)
	JSR	_UploadUniqueDualAndTest

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
	LDA	#Data::FrameSets::Fixed_OneTile_Overflow
	JSR	_UploadFixed
	BCS	Failure		; This should return false

	; Test vram set flag clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Fixed_TwoTiles_Overflow
	JSR	_UploadFixed
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
	LDA	#Data::FrameSets::Fixed_OneRow_Overflow
	JSR	_UploadFixed
	BCS	Failure		; This should return false

	; Test vram set flag clear
	LDA	#METASPRITE_STATUS_VRAM_SET_FLAG
	AND	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	BNE	Failure


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Fixed_TwoRows_Overflow
	JSR	_UploadFixed
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
	LDA	#Data::FrameSets::Fixed_TwoRows_Overflow
	LDX	#.loword(Data::Tileset_Fixed_TwoRows_Overflow_DMA0)
	LDY	#.loword(Data::Tileset_Fixed_TwoRows_Overflow_DMA1)
	JSR	_UploadUniqueDualAndTest

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
	LDA	#Data::FrameSets::Fixed_TwoTiles_Overflow
	LDX	#.loword(Data::Tileset_Fixed_TwoTiles_Overflow_DMA0)
	LDY	#.loword(Data::Tileset_Fixed_TwoTiles_Overflow_DMA1)
	JSR	_UploadUniqueDualAndTest

	; pass through
	RTS

Failure:
	CLC
	RTS
.endproc

.proc Upload_DetectDuplicate
tmp_index := tmp1

.define _ENTITY_(n) UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * n

	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	LDA	#_ENTITY_(0)
	TCD
	LDA	#Data::FrameSets::Fixed_OneTile_1
	JSR	_UploadFixed
	IF_C_CLEAR
		RTS
	ENDIF


	LDA	#_ENTITY_(2)
	TCD
	LDA	#Data::FrameSets::Fixed_TwoTiles_4
	JSR	_UploadFixed
	BCC	Failure

	LDA	#_ENTITY_(4)
	TCD
	LDA	#Data::FrameSets::Fixed_OneRow_2
	JSR	_UploadFixed
	BCC	Failure

	LDA	#_ENTITY_(6)
	TCD
	LDA	#Data::FrameSets::Fixed_TwoRows_3
	JSR	_UploadFixed
	BCC	Failure


	; Store DMA index
	LDA	MetaSprite__dmaTableIndex
	STA	tmp_index


	LDA	#_ENTITY_(1)
	TCD
	LDA	#Data::FrameSets::Fixed_OneTile_1
	JSR	_UploadFixed
	BCC	Failure

	LDA	#_ENTITY_(3)
	TCD
	LDA	#Data::FrameSets::Fixed_TwoTiles_4
	JSR	_UploadFixed
	BCC	Failure

	LDA	#_ENTITY_(5)
	TCD
	LDA	#Data::FrameSets::Fixed_OneRow_2
	JSR	_UploadFixed
	BCC	Failure

	LDA	#_ENTITY_(7)
	TCD
	LDA	#Data::FrameSets::Fixed_TwoRows_3
	JSR	_UploadFixed
	BCC	Failure


	; Test that no uploads were actually made
	LDA	MetaSprite__dmaTableIndex
	CMP	tmp_index
	BNE	Failure

	; Ensure the entities have the same charattr values
	LDA	ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset + _ENTITY_(0)
	CMP	ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset + _ENTITY_(1)
	BNE	Failure

	LDA	ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset + _ENTITY_(2)
	CMP	ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset + _ENTITY_(3)
	BNE	Failure

	LDA	ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset + _ENTITY_(4)
	CMP	ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset + _ENTITY_(5)
	BNE	Failure

	LDA	ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset + _ENTITY_(6)
	CMP	ExampleEntity::metasprite + MetaSpriteStruct::blockOneCharAttrOffset + _ENTITY_(7)
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS

.undefine _ENTITY_
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
	LDA	#Data::FrameSets::Fixed_OneTile_Overflow
	JSR	_UploadFixed
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
	LDA	#Data::FrameSets::Fixed_TwoTiles_Overflow
	JSR	_UploadFixed
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
	LDA	#Data::FrameSets::Fixed_TwoTiles_Overflow
	LDX	#.loword(Data::Tileset_Fixed_TwoTiles_Overflow_DMA0)
	LDY	#.loword(Data::Tileset_Fixed_TwoTiles_Overflow_DMA1)
	JSR	_UploadUniqueDualAndTest
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
	LDA	#Data::FrameSets::Fixed_OneTile_Overflow
	JSR	_UploadFixed
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
	LDA	#Data::FrameSets::Fixed_OneTile_Overflow
	LDX	#.loword(Data::Tileset_Fixed_OneTile_Overflow_DMA0)
	JSR	_UploadUniqueSingleAndTest
	BCC	Failure

	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Fixed_OneTile_Overflow2
	LDX	#.loword(Data::Tileset_Fixed_OneTile_Overflow2_DMA0)
	JSR	_UploadUniqueSingleAndTest
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
	LDA	#Data::FrameSets::Fixed_OneRow_Overflow
	JSR	_UploadFixed
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
	LDA	#Data::FrameSets::Fixed_TwoRows_Overflow
	JSR	_UploadFixed
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
	LDA	#Data::FrameSets::Fixed_TwoRows_Overflow
	LDX	#.loword(Data::Tileset_Fixed_TwoRows_Overflow_DMA0)
	LDY	#.loword(Data::Tileset_Fixed_TwoRows_Overflow_DMA1)
	JSR	_UploadUniqueDualAndTest
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
	LDA	#Data::FrameSets::Fixed_OneRow_Overflow
	JSR	_UploadFixed
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
	LDA	#Data::FrameSets::Fixed_OneRow_Overflow
	LDX	#.loword(Data::Tileset_Fixed_OneRow_Overflow_DMA0)
	JSR	_UploadUniqueSingleAndTest
	BCC	Failure

	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Fixed_OneRow_Overflow2
	LDX	#.loword(Data::Tileset_Fixed_OneRow_Overflow2_DMA0)
	JSR	_UploadUniqueSingleAndTest
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
	LDA	#Data::FrameSets::Fixed_OneTile_Overflow
	LDX	#.loword(Data::Tileset_Fixed_OneTile_Overflow_DMA0)
	JSR	_UploadUniqueSingleAndTest
	BCC	Failure


	LDA	#entity_Overflow2
	TCD
	LDA	#Data::FrameSets::Fixed_OneTile_Overflow2
	LDX	#.loword(Data::Tileset_Fixed_OneTile_Overflow2_DMA0)
	JSR	_UploadUniqueSingleAndTest
	BCS	Failure		; This should return false

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
.proc _UploadFixed
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
.proc _UploadUniqueSingleAndTest
tmp_index	:= tmp5
tmp_table0	:= tmp6

	STX	tmp_table0

	LDX	MetaSprite__dmaTableIndex
	STX	tmp_index


	; IN : A, DP
	JSR	_UploadFixed
	BCC	Failure


	LDA	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	AND	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	CMP	#METASPRITE_STATUS_VRAM_SET_FLAG
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
.proc _UploadUniqueDualAndTest
tmp_index	:= tmp4
tmp_table0	:= tmp5
tmp_table1	:= tmp6

	STX	tmp_table0
	STY	tmp_table1

	LDX	MetaSprite__dmaTableIndex
	STX	tmp_index


	; IN : A, DP
	JSR	_UploadFixed
	BCC	Failure

	LDA	z:ExampleEntity::metasprite + MetaSpriteStruct::status
	AND	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	CMP	#METASPRITE_STATUS_VRAM_SET_FLAG
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
;; With 2 single and 7 dual metaSprites
;;
;; The tilesets used MUST NOT already exist in the system
;;
;; entities(0) - entities(1) are OneTile
;; entities(2) - entities(8) are TwoTiles

.A16
.I16
.proc _FillTileSlots
	LDA	#entity_OneTile
	TCD
	LDA	#Data::FrameSets::Fixed_OneTile_0
	LDX	#.loword(Data::Tileset_Fixed_OneTile_0_DMA0)
	LDY	#0
	JSR	_UploadUniqueSingleAndTest
	BCC	Failure

	LDA	#entity_OneTile + .sizeof(ExampleEntity)
	TCD
	LDA	#Data::FrameSets::Fixed_OneTile_1
	LDX	#.loword(Data::Tileset_Fixed_OneTile_1_DMA0)
	LDY	#0
	JSR	_UploadUniqueSingleAndTest
	IF_C_CLEAR
Failure:
		CLC
		RTS
	ENDIF

	.repeat	7, i
		LDA	#entity_TwoTiles + .sizeof(ExampleEntity) * i
		TCD
		LDA	#Data::FrameSets::.ident(.sprintf("Fixed_TwoTiles_%i", i))
		LDX	#.loword(Data::.ident(.sprintf("Tileset_Fixed_TwoTiles_%i_DMA0", i)))
		LDY	#.loword(Data::.ident(.sprintf("Tileset_Fixed_TwoTiles_%i_DMA1", i)))
		JSR	_UploadUniqueDualAndTest
		BCC	Failure
	.endrepeat

	SEC
Return:
	RTS
.endproc



;; Will fill all the row slots
;; With 2 single and 7 dual metaSprites
;;
;; The tilesets used MUST NOT already exist in the system
;;
;; entities(9) - entities(10) are OneRow
;; entities(11) - entities(16) are TwoRows
.A16
.I16
.proc _FillRowSlots
	LDA	#entity_OneRow
	TCD
	LDA	#Data::FrameSets::Fixed_OneRow_0
	LDX	#.loword(Data::Tileset_Fixed_OneRow_0_DMA0)
	JSR	_UploadUniqueSingleAndTest
	BCC	Failure

	LDA	#entity_OneRow + .sizeof(ExampleEntity)
	TCD
	LDA	#Data::FrameSets::Fixed_OneRow_1
	LDX	#.loword(Data::Tileset_Fixed_OneRow_1_DMA0)
	JSR	_UploadUniqueSingleAndTest
	IF_C_CLEAR
Failure:
		CLC
		RTS
	ENDIF

	.repeat	6, i
		LDA	#entity_TwoRows + .sizeof(ExampleEntity) * i
		TCD
		LDA	#Data::FrameSets::.ident(.sprintf("Fixed_TwoRows_%i", i))
		LDX	#.loword(Data::.ident(.sprintf("Tileset_Fixed_TwoRows_%i_DMA0", i)))
		LDY	#.loword(Data::.ident(.sprintf("Tileset_Fixed_TwoRows_%i_DMA1", i)))
		JSR	_UploadUniqueDualAndTest
		BCC	Failure
	.endrepeat

	SEC
	RTS
.endproc

entity_OneTile = UnitTest_MetaSprite::entities
entity_TwoTiles = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 2
entity_OneRow = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 9
entity_TwoRows = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 12
entity_Overflow = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 18
entity_Overflow2 = UnitTest_MetaSprite::entities + .sizeof(ExampleEntity) * 19

.endmodule

; vim: set ft=asm:

