
.include "metasprite.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/synthetic.inc"

.setcpu "65816"

; ::TODO dynamic tilesets::
; ::TODO dynamic-fixed tilesets::

.assert METASPRITE_VRAM_TILE_SLOTS .mod 8 = 0, error, "METASPRITE_VRAM_TILE_SLOTS must be divisible by 8"
.assert METASPRITE_VRAM_TILE_SLOTS / 8 + METASPRITE_VRAM_ROW_SLOTS <= 16, error, "Only 16 VRAM rows can be allocated to MetaSprite Module"

.assert METASPRITE_VRAM_TILE_SLOTS + METASPRITE_VRAM_ROW_SLOTS < (2 << 6), error, "Too many VRAM slots"



.segment "WRAM7E"
	;; Table that conatains the address/refence count of each vram slot
	;; Array of structures
	.proc vramSlots
		;; address of tileset in METASPRITE_TILESET_BLOCK bank
		tileset:	.res (METASPRITE_VRAM_TILE_SLOTS + METASPRITE_VRAM_ROW_SLOTS) * 2

		;; number of tiles tileset is used (if any).
		;; This is $FFFF if slot is the second half of a two-block tileset
		;; This is $FFFF if the slot belongs to a dynamic metasprite tile.
		;; If this is 0 is the slot is unused
		count:		.res (METASPRITE_VRAM_TILE_SLOTS + METASPRITE_VRAM_ROW_SLOTS) * 2

		;; If this is the first slot of a *two-block* style
		;;	then it points to the index of the second slot.
		;; If this is the second slot of a *two-block* style
		;;	then it is $FFFF
		;; If this slot does not have a second half (one-block style)
		;;	then it is $FFFF
		pair:		.res (METASPRITE_VRAM_TILE_SLOTS + METASPRITE_VRAM_ROW_SLOTS) * 2
	.endproc

	vramSlots_TilesOffset = 0
	vramSlots_RowsOffset = METASPRITE_VRAM_TILE_SLOTS * 2


	.proc	dmaTable
		vramAddress:	.res	METASPRITE_DMA_TABLE_COUNT * 2
		tablePtr:	.res	METASPRITE_DMA_TABLE_COUNT * 2
	.endproc

.segment "SHADOW"
	dmaTableIndex:		.res 2


dmaTable_vramAddress := dmaTable::vramAddress
dmaTable_tablePtr := dmaTable::tablePtr
.exportlabel dmaTableIndex
.exportlabel dmaTable_vramAddress
.exportlabel dmaTable_tablePtr


.segment "BANK1"
TileSlots_CharAttrOffsets:
	.repeat METASPRITE_VRAM_TILE_SLOTS, i
		.word (i / 8) * 32 + (i & 7) * 2
	.endrepeat
	.repeat METASPRITE_VRAM_ROW_SLOTS, i
		.word (METASPRITE_VRAM_TILE_SLOTS / 8 + i) * 32
	.endrepeat


TileSlots_VramAddresses:
	.repeat METASPRITE_VRAM_TILE_SLOTS, i
		.word METASPRITE_VRAM_WORD_ADDRESS + ((i / 8) * 32 + (i & 7) * 2) * 16
	.endrepeat
	.repeat METASPRITE_VRAM_ROW_SLOTS, i
		.word METASPRITE_VRAM_WORD_ADDRESS + (METASPRITE_VRAM_TILE_SLOTS / 8 + i) * 32 * 16
	.endrepeat


.code


; DB = $7E
.A16
.I16
.macro Reset__Vram
	.assert .asize = 16, error, "Bad asize"
	.assert .isize = 16, error, "Bad isize"

	LDA	#$FFFF
	LDX	#.sizeof(vramSlots::tileset) - 2
	REPEAT
		STZ	vramSlots::tileset, X
		STZ	vramSlots::count, X
		STA	vramSlots::pair, X
		DEX
		DEX
	UNTIL_MINUS

	STZ	dmaTableIndex
.endmacro


;; Removes the tileset from the slots
;;
;; Because of the onderflow check in count this routine
;; can be used on both tileset types.
;;
;; Should not be called directly.
;;
;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
;;
;; INPUT:
;;	DP: MetaSpriteStruct address - MetaSpriteDpOffset
.A16
.I16
.macro RemoveTileset
	LDA	z:MSDP::status
	LSR
	IF_C_SET
		; metasprite already has a slot allocated
		; check if tileset has changed
		ASL
		AND	#METASPRITE_STATUS_VRAM_INDEX_MASK
		TAY

		; tileset has changed, decrement counter
		; do not need to decrement counter of second slot as counter is only
		; used in first slot

		LDA	vramSlots::count, Y
		DEC
		IF_MINUS
			LDA	#0
		ENDIF
		STA	vramSlots::count, Y
		IF_ZERO
			LDX	vramSlots::pair, Y
			IF_PLUS
				; slot has a second block, clear that as well
				STA	vramSlots::count, X
			ENDIF
		ENDIF

		; slot has been deallocated, remember that
		LDA	#METASPRITE_STATUS_VRAM_INDEX_MASK | METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
		TRB	z:MSDP::status
	ENDIF
.endmacro


;; A hook for unit testing Init Fixed Tileset
;;
;; IN:
;;	DP: MetaSpriteStruct address - MetaSpriteDpOffset
;;	A: tileset address
;;
;; OUTPUT:
;;	C set if succeesful
.exportlabel UploadFixedTileset


;; Uploads (if necessary) a fixed metasprite tileset into VRAM.
;;
;; A fixed tileset is one that does not change throughout the
;; life of the frameSet that the metasprite belongs to. Because
;; of this we can scan though all the slots in order to detect
;; duplicates.
;;
;; This routine should only be called by Activate.
;;
;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
;;
;; INPUT:
;;	DP: MetaSpriteStruct address - MetaSpriteDpOffset
;;
;; OUTPUT:
;;	C set if succeesful
.A16
.I16
.routine Activate_FixedTileset
tmp_tileset	:= tmp1
tmp_firstFreeSlot  := tmp2
tmp_secondFreeSlot := tmp3
tmp_firstSlot	:= tmp4
tmp_secondSlot	:= tmp5

	LDX	z:MSDP::frameSet
	LDA	f:frameSetOffset + MetaSprite__FrameSet::tileset, X

::UploadFixedTileset:
	STA	tmp_tileset

	LDA	z:MSDP::status
	LSR
	IF_C_SET
		; metasprite already has a slot allocated
		; check if tileset has changed
		ASL
		AND	#METASPRITE_STATUS_VRAM_INDEX_MASK
		TAY

		LDA	vramSlots::tileset, Y
		CMP	tmp_tileset
		BEQ	Return		; C set


		; tileset has changed, decrement counter
		; do not need to decrement counter of second slot as counter is only
		; used in first slot

		LDA	vramSlots::count, Y
		DEC
		IF_MINUS
			LDA	#0
		ENDIF
		STA	vramSlots::count, Y
		IF_ZERO
			STA	vramSlots::tileset, Y
			LDX	vramSlots::pair, Y
			IF_PLUS
				; slot has a second block, clear that as well
				STA	vramSlots::count, X
			ENDIF
		ENDIF

		LDA	#METASPRITE_STATUS_VRAM_INDEX_MASK | METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
		TRB	z:MSDP::status
	ENDIF


	; As there are 4 different tileset types, we need 4 different
	; searches.
	LDX	tmp_tileset
	LDA	f:tilesetBankOffset + MetaSprite__Tileset::type, X
	AND	#3
	ASL
	TAX
	JMP	(.loword(SetTilesetTypeTable), X)

ReturnFalse:
	CLC
Return:
	RTS


.rodata
SetTilesetTypeTable:
	.assert MetaSprite__Tileset_Type::TWO_VRAM_ROWS = 3, error, "Bad Table"

	; Must match MetaSprite__Tileset_Type
	.addr	Process_OneTile
	.addr	Process_TwoTiles
	.addr	Process_OneRow
	.addr	Process_TwoRows

.code

; IN: tmp_tileset = tileset to find
; OUT:
;	C clear if no slots available
;	branch to OneBlock_TilesetFound if duplicate found (X = slot address)
;	branch to OneBlock_EmptySlot if empty slot found (X = slot address)
.A16
.I16
.proc Process_OneTile
	.assert vramSlots_TilesOffset = 0, error, "Bad Offset"

	LDA	tmp_tileset

	LDY	#$8000	; firstFreeSlot
	STY	tmp_firstFreeSlot

	LDX	#(METASPRITE_VRAM_TILE_SLOTS - 1) * 2
	REPEAT
		CMP	vramSlots::tileset, X
		BEQ	OneBlock_TilesetFound

		LDY	vramSlots::count, X
		IF_ZERO
			STX	tmp_firstFreeSlot
		ENDIF

		DEX
		DEX
	UNTIL_MINUS

	LDX	tmp_firstFreeSlot
	BPL	OneBlock_EmptySlot

	CLC
	RTS

.endproc


; IN: tmp_tileset = tileset to find
; OUT:
;	C clear if no slots available
;	branch to OneBlock_TilesetFound if duplicate found (X = slot address)
;	branch to OneBlock_EmptySlot if empty slot found (X = slot address)
.A16
.I16
.proc Process_OneRow
	LDA	tmp_tileset

	LDY	#$8000	; firstFreeSlot
	STY	tmp_firstFreeSlot

	LDX	#(METASPRITE_VRAM_ROW_SLOTS - 1) * 2
	REPEAT
		CMP	vramSlots_RowsOffset + vramSlots::tileset, X
		IF_EQ
			TXA
			; C set
			ADC	#vramSlots_RowsOffset - 1
			TAX
			BRA	OneBlock_TilesetFound
		ENDIF

		LDY	vramSlots_RowsOffset + vramSlots::count, X
		IF_ZERO
			STX	tmp_firstFreeSlot
			TXY
		ENDIF

		DEX
		DEX
	UNTIL_MINUS

	CLC
	LDA	tmp_firstFreeSlot
	IF_MINUS
		; carry clear
		RTS
	ENDIF

	; carry clear
	ADC	#vramSlots_RowsOffset
	TAX

	.assert * = OneBlock_EmptySlot, error, "Bad Flow"
.endproc


; Prep tileset to load into VRAM
; X = slot
.A16
.I16
OneBlock_EmptySlot:
	PHX

	; Add to tileset DMA table
	; ::SHOULDO add vblank timing check::

	; Check if table has overflowed
	LDY	dmaTableIndex
	CPY	#METASPRITE_DMA_TABLE_COUNT * 2
	IF_GE
		CLC
		RTS
	ENDIF

	LDA	f:TileSlots_VramAddresses, X
	STA	dmaTable::vramAddress, Y

	LDX	tmp_tileset
	LDA	f:tilesetBankOffset + MetaSprite__Tileset::dmaTable0, X
	STA	dmaTable::tablePtr, Y

	INY
	INY
	STY	dmaTableIndex

	PLX

	; Save tileset to slot
	LDA	tmp_tileset
	STA	vramSlots::tileset, X
	LDA	#$FFFF
	STA	vramSlots::pair, X


; X = slot
OneBlock_TilesetFound:
	; Set offsets
	LDA	z:MSDP::blockOneCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:TileSlots_CharAttrOffsets, X
	STA	z:MSDP::blockOneCharAttrOffset

	SEP	#$20
.A8
	; Increment slot counter and update status

	INC	vramSlots::count, X

	LDA	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "Bad assumption"
	ASL
	IF_C_SET
		TXA
		ORA	#METASPRITE_STATUS_PALETTE_SET_FLAG | METASPRITE_STATUS_VRAM_SET_FLAG
	ELSE
		TXA
		ORA	#METASPRITE_STATUS_VRAM_SET_FLAG
	ENDIF
	STA	z:MSDP::status

	REP	#$30
.A16
	SEC
	RTS




; IN: tmp_tileset = tileset to find
; OUT:
;	C clear if no slots available
;	branch to TwoBlocks_TilesetFound if duplicate found (X = slot1 address, Y = slot2 address)
;	branch to TwoBlocks_EmptySlot if empty slot found (X = slot1 address, Y = slot2 address)
.A16
.I16
.proc Process_TwoRows
	; Search to see if tileset already in VRAM

	LDY	#$8000	; firstFreeSlot
	STY	tmp_secondFreeSlot

	LDX	#(METASPRITE_VRAM_ROW_SLOTS - 1) * 2
	REPEAT
		LDA	vramSlots_RowsOffset + vramSlots::tileset, X
		CMP	tmp_tileset
		IF_EQ
			LDY	vramSlots_RowsOffset + vramSlots::pair, X
			TXA
			; c set
			ADC	#vramSlots_RowsOffset - 1
			TAX
			JMP	TwoBlocks_TilesetFound
		ENDIF

		LDA	vramSlots_RowsOffset + vramSlots::count, X
		IF_ZERO
			STY	tmp_secondFreeSlot
			TXY
		ENDIF

		DEX
		DEX
	UNTIL_MINUS

	; No duplicates found
	LDA	tmp_secondFreeSlot
	IF_PLUS
		; both slots are free, order doesn't matter
		CLC
		ADC	#vramSlots_RowsOffset
		TAX

		TYA
		CLC
		ADC	#vramSlots_RowsOffset
		TAY
		BRA	TwoBlocks_EmptySlot
	ENDIF

	CLC
	RTS
.endproc


; IN: tmp_tileset = tileset to find
; OUT:
;	C clear if no slots available
;	branch to TwoBlocks_TilesetFound if duplicate found (X = slot1 address, Y = slot2 address)
;	branch to TwoBlocks_EmptySlot if empty slot found (X = slot1 address, Y = slot2 address)
.A16
.I16
.proc Process_TwoTiles
	.assert vramSlots_TilesOffset = 0, error, "Bad Offset"

	LDY	#$8000	; firstFreeSlot
	STY	tmp_secondFreeSlot

	LDX	#(METASPRITE_VRAM_TILE_SLOTS - 1) * 2
	REPEAT
		LDA	vramSlots::tileset, X
		CMP	tmp_tileset
		IF_EQ
			LDY	vramSlots::pair, X
			BRA	TwoBlocks_TilesetFound
		ENDIF

		LDA	vramSlots::count, X
		IF_ZERO
			STY	tmp_secondFreeSlot
			TXY
		ENDIF

		DEX
		DEX
	UNTIL_MINUS


	LDX	tmp_secondFreeSlot
	IF_MINUS
		; both slots are free, order doesn't matter
		CLC
		RTS
	ENDIF

	.assert * = TwoBlocks_EmptySlot, error, "Bad Flow"
.endproc


; X = first slot
; Y = second slot
TwoBlocks_EmptySlot:
	STX	tmp_firstSlot
	STY	tmp_secondSlot


	; Transfer to DMA
	; ::SHOULDO add vblank timing check::

	; Check if table has overflowed
	LDY	dmaTableIndex
	CPY	#METASPRITE_DMA_TABLE_COUNT * 2 - 2
	IF_GE
		CLC
		RTS
	ENDIF

	LDA	f:TileSlots_VramAddresses, X
	STA	dmaTable::vramAddress, Y

	LDX	tmp_tileset
	LDA	f:tilesetBankOffset + MetaSprite__Tileset::dmaTable0, X
	STA	dmaTable::tablePtr, Y

	INY
	INY

	LDX	tmp_secondSlot
	LDA	f:TileSlots_VramAddresses, X
	STA	dmaTable::vramAddress, Y

	LDX	tmp_tileset
	LDA	f:tilesetBankOffset + MetaSprite__Tileset::dmaTable1, X
	STA	dmaTable::tablePtr, Y

	INY
	INY
	STY	dmaTableIndex


	; Save tileset to slot
	LDX	tmp_firstSlot
	LDY	tmp_secondSlot

	LDA	tmp_tileset
	STA	vramSlots::tileset, X
	STA	vramSlots::tileset, Y

	TYA
	STA	vramSlots::pair, X
	LDA	#$FFFF
	STA	vramSlots::pair, Y
	STA	vramSlots::count, Y		; ensure count is not 0



TwoBlocks_TilesetFound:
	PHX
	TYX
	LDA	MSDP::blockTwoCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:TileSlots_CharAttrOffsets, X
	STA	MSDP::blockTwoCharAttrOffset

	PLX
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:TileSlots_CharAttrOffsets, X
	STA	MSDP::blockOneCharAttrOffset


	SEP	#$20
.A8
	; Increment slot counter and update status
	; Don't update the second slots count, that is always $FFFF
	INC	vramSlots::count, X

	LDA	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "Bad assumption"
	ASL
	IF_C_SET
		TXA
		ORA	#METASPRITE_STATUS_PALETTE_SET_FLAG | METASPRITE_STATUS_VRAM_SET_FLAG
	ELSE
		TXA
		ORA	#METASPRITE_STATUS_VRAM_SET_FLAG
	ENDIF
	STA	z:MSDP::status

	REP	#$30
.A16
	SEC
	RTS

.endroutine

