
.include "metasprite.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/synthetic.inc"

.setcpu "65816"

.assert METASPRITE_VRAM_TILE_SLOTS .mod 8 = 0, error, "METASPRITE_VRAM_TILE_SLOTS must be divisible by 8"
.assert METASPRITE_VRAM_TILE_SLOTS / 8 + METASPRITE_VRAM_ROW_SLOTS <= 16, error, "Only 16 VRAM rows can be allocated to MetaSprite Module"

.assert METASPRITE_VRAM_TILE_SLOTS + METASPRITE_VRAM_ROW_SLOTS < (2 << 6), error, "Too many VRAM slots"


	;; State data for the allocation/deallocation of VRAM slots.
	;;
	;; Slots 0 - `METASPRITE_VRAM_TILE_SLOTS - 1` are for a VRAM tile
	;; Slots `METASPRITE_VRAM_TILE_SLOTS` onwards are for a VRAM ROW
	;;
	;; This data exists in 4 states:
	;;	1) A single linked list holding the free slots
	;;	2) Not part of a linked list (used in dynamic tilesets)
	;;	3) A double linked list for fixed tilesets (it makes removing easier)
	;;	4) Second half of a dual tileset. (not part of a linked list, linked by `vramSlots::pair`)
	;;
	;; This data is interlaced within the unused words of the `xposBuffer` in order to save space.
	;;
	;; To save RAM the index of the slot used is encoded in the MetaSprite status byte.
	;; As the slots are separated by 4 bytes, the formula to convert them is:
	;;
	;;	slot index = status & METASPRITE_VRAM_TILE_SLOTS << 1
	;;
	.scope vramSlots
		SectionSize = (METASPRITE_VRAM_TILE_SLOTS + METASPRITE_VRAM_ROW_SLOTS) * 2 * 2
		.assert SectionSize < 256, error, "Too many VRAM slots"

		;; the number of bytes between slot(n+1) & slot(n)
		SlotMemoryIncrement = 4

		;; All row slots have an index grater than this.
		;; Used to separate tile from row slots on deallocation/init.
		RowSlotIndexGE = METASPRITE_VRAM_TILE_SLOTS * 2 * 2

		;; Index of the next slot
		;; This value is NOT set if a dynamic tileset or the second
		;;	half of a dual slot.
		;; (byte index, >= $80 is NULL)
		next		= _VramSlotsBlock + SectionSize * 0

		;; Index of the previous next slot
		;; This value is ONLY set in the fixed tileset list
		;; (byte index, >= $80 is NULL)
		prev		= _VramSlotsBlock + SectionSize * 0 + 1

		;; address of tileset in METASPRITE_TILESET_BLOCK bank
		tileset		= _VramSlotsBlock + SectionSize * 1

		;; Number of times the slot is used
		;; (uint8)
		count		= _VramSlotsBlock + SectionSize * 2

		;; Points the second slot (if in a two slot type)
		;; (byte index, >= $80 is NULL)
		pair		= _VramSlotsBlock + SectionSize * 2 + 1

		.assert count + SectionSize < xposBuffer_End, error, "Not enough free memory in xposBuffer for slots"

		;; The charAttr data that belongs to the given slot
		;; (word - ROM)
		CharAttrOffset = TileSlots_ROM_DATA

		;; The vram address of the slot
		;; (word - ROM)
		VramAddresses = TileSlots_ROM_DATA + 2
	.endscope


.segment "WRAM7E"
	.scope vramSlotList
		;; One Tiles fixed tileset vram slot list index
		;; $80 if list is empty
		;; (byte index)
		oneFixedTileList:	.res 1

		;; Two Tiles fixed tileset vram slot list index
		;; $80 if list is empty
		;; (byte index)
		twoFixedTilesList:	.res 1

		;; One Rows fixed tileset vram slot list index
		;; $80 if list is empty
		;; (byte index)
		oneFixedRowList:	.res 1

		;; Two Rows fixed tileset vram slot list index
		;; $80 if list is empty
		;; (byte index)
		twoFixedRowsList:	.res 1

		;; Index of the unallocated tile slot
		;; $80 if list is empty
		;; (byte index)
		freeTiles:	.res 1

		;; Index of the unallocated tile slot
		;; $80 if list is empty
		;; (byte index)
		freeRows:	.res 1
	.endscope

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
TileSlots_ROM_DATA:
	; Tiles
	.repeat METASPRITE_VRAM_TILE_SLOTS, i
		; CharAttrOffsets
		.word (i / 8) * 32 + (i & 7) * 2
		; VramAddresses
		.word METASPRITE_VRAM_WORD_ADDRESS + ((i / 8) * 32 + (i & 7) * 2) * 16
	.endrepeat

	; Rows
	.repeat METASPRITE_VRAM_ROW_SLOTS, i
		; CharAttrOffsets
		.word (METASPRITE_VRAM_TILE_SLOTS / 8 + i) * 32
		; VramAddresses
		.word METASPRITE_VRAM_WORD_ADDRESS + (METASPRITE_VRAM_TILE_SLOTS / 8 + i) * 32 * 16
	.endrepeat
.code


;; ASSUMES: xPosBuffer reset to 0 by Reset__Render
;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
.macro Reset__Vram
	.assert .asize = 16, error, "Bad asize"
	.assert .isize = 16, error, "Bad isize"

	SEP	#$30
.A8
.I8
	; Generate free lists
	LDA	#vramSlots::SlotMemoryIncrement
	LDX	#0

	CLC
	REPEAT
		STA	vramSlots::next, X
		TAX
		; Carry clear from branch
		ADC	#vramSlots::SlotMemoryIncrement
		CMP	#vramSlots::SectionSize
	UNTIL_GE

	; terminate the end of the lists
	LDA	#$80
	STA	vramSlots::next + vramSlots::RowSlotIndexGE - 4
	STA	vramSlots::next + vramSlots::SectionSize - 4

	; Reset the slot lists
	STA	vramSlotList::oneFixedTileList
	STA	vramSlotList::twoFixedTilesList
	STA	vramSlotList::oneFixedRowList
	STA	vramSlotList::twoFixedRowsList


	STZ	vramSlotList::freeTiles
	LDA	#vramSlots::RowSlotIndexGE
	STA	vramSlotList::freeRows

	REP	#$30
.A16
.I16
	STZ	dmaTableIndex
.endmacro



;; Removes the tileset from the slots
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
	.local DeleteNode

	LDA	z:MSDP::status
	IF_BIT	#METASPRITE_STATUS_VRAM_SET_FLAG

		SEP	#$30
.A8
.I8
		JSR	_RemoveVramSlot

		REP	#$30
.I16
.A16
	ENDIF
.endmacro


;; Removes the VRAM slot reference
;; SHOULD NOT BE CALLED DIRECTLY
;;
;; REQUIES: 8 bit A, 8 bit Index, DB = $7E
;; ASSUMES: METASPRITE_STATUS_VRAM_INDEX_MASK SET
;;
;; INPUT:
;;	DP: MetaSpriteStruct address - MetaSpriteDpOffset
.A8
.I8
.routine _RemoveVramSlot
	; metasprite already has a slot allocated
	; check if tileset has changed
	AND	#METASPRITE_STATUS_VRAM_INDEX_MASK
	ASL
	TAX

XIndex:
	DEC	vramSlots::count, X
	IF_ZERO
		; Remove slot from fixed tileset list (if necessary)
		; fixed tileset slots have a valid prev and/or next node

		; X = current node index
		; IF INDEX is >=$80 (negative) then it is NULL

		; if current->prev is NULL:
		;	if current->next:
		;		if current is row slot:
		;			if current = vramSlotList.twoFixedRowsList.first
		;				vramSlotList.twoFixedRowsList.first = current->next
		;			else
		;				vramSlotList.oneFixedRowList.first = current->next
		;		else:
		;			if current = vramSlotList.oneFixedTileList.first
		;				vramSlotList.oneFixedTileList.first = current->next
		;			else
		;				vramSlotList.twoFixedTilesList.first = current->next
		; else:
		;	current->prev->next = current->next
		;
		; if current->next:
		;	current->next->prev = current->prev

		LDY	vramSlots::prev, X
		IF_MINUS
			LDA	vramSlots::next, X
			IF_PLUS
				; has a next node, but no previous node
				CPX	#vramSlots::RowSlotIndexGE
				IF_GE
					; row slot
					; determine which list it goes into
					CPX	vramSlotList::twoFixedRowsList
					IF_EQ
						STA	vramSlotList::twoFixedRowsList
					ELSE
						STA	vramSlotList::oneFixedRowList
					ENDIF
				ELSE
					; tile slot
					; determine which list it goes into
					CPX	vramSlotList::oneFixedTileList
					IF_EQ
						STA	vramSlotList::oneFixedTileList
					ELSE
						STA	vramSlotList::twoFixedTilesList
					ENDIF
				ENDIF
			ENDIF
		ELSE
			; has a previous node
			; Y = current->prev
			LDA	vramSlots::next, X
			STA	vramSlots::next, Y
		ENDIF

		; A = current.next
		TAY
		IF_PLUS
			LDA	vramSlots::prev, X
			STA	vramSlots::prev, Y
		ENDIF


		; Insert slot into free list
		;
		; if current is row slot:
		;	tmp = freeRows
		;	freeRows = current
		;	current->next = tmp
		; else:
		;	tmp = freeTiles
		;	freeTiles = current
		;	current->next = tmp

		CPX	#vramSlots::RowSlotIndexGE
		IF_GE
			; row slot
			LDA	vramSlotList::freeRows
			STX	vramSlotList::freeRows
		ELSE
			; tile slot
			LDA	vramSlotList::freeTiles
			STX	vramSlotList::freeTiles
		ENDIF

		STA	vramSlots::next, X


		; Check if the slot is a dual slot
		LDY	vramSlots::pair, X
		IF_PLUS
			; Insert second slot into free list
			CPY	#vramSlots::RowSlotIndexGE
			IF_GE
				; row slot
				LDA	vramSlotList::freeRows
				STY	vramSlotList::freeRows
			ELSE
				; tile slot
				LDA	vramSlotList::freeTiles
				STY	vramSlotList::freeTiles
			ENDIF

			STA	vramSlots::next, Y
		ENDIF

	ENDIF

	; slot has been deallocated, remember that
	LDA	#METASPRITE_STATUS_VRAM_INDEX_MASK | METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	TRB	z:MSDP::status

	RTS
.endroutine



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
tmp_firstSlot	:= tmp1
tmp_secondSlot	:= tmp2

	LDX	z:MSDP::currentFrame
	BEQ	ReturnFalse

	LDA	f:frameDataOffset + MetaSprite__Frame::tileset, X
	STA	tmp_tileset

	.assert METASPRITE_STATUS_VRAM_SET_FLAG = 1, error, "Bad code"
	LDA	z:MSDP::status
	LSR
	IF_C_SET
		ASL

		; metasprite already has a slot allocated
		; check if tileset has changed
		SEP	#$30
.A8
.I8
		AND	#METASPRITE_STATUS_VRAM_INDEX_MASK
		ASL
		TAX

		REP	#$20
.A16
		LDA	vramSlots::tileset, X
		CMP	tmp_tileset
		IF_EQ
			; Return true
			SEC
			REP	#$30
			RTS
		ENDIF

		; tileset has changed, remove reference
		SEP	#$20
.A8
		JSR	_RemoveVramSlot::XIndex

		REP	#$30
	ENDIF
.A16
.I16

	; As there are 4 different tileset types, we need 4 different
	; searches.
	LDX	z:MSDP::frameSet
	LDA	f:frameSetOffset + MetaSprite__FrameSet::tilesetType, X
	AND	#3 << 1
	TAX
	JMP	(.loword(TilesetSizeTable), X)

ReturnFalse:
	CLC
Return:
	RTS


.rodata
TilesetSizeTable:
	.assert MetaSprite__FrameSet_TilesetSize::TWO_VRAM_ROWS = 6, error, "Bad Table"

	; Must match MetaSprite__FrameSet_TilesetSize
	.addr	Process_OneTile
	.addr	Process_TwoTiles
	.addr	Process_OneRow
	.addr	Process_TwoRows

.code

.macro _Process_One tilesetList, freeList
	.assert .asize = 16, error, "bad asize"

	LDA	tmp_tileset

	SEP	#$10
.I8
	; Search for duplicate tilesets
	LDX	vramSlotList::tilesetList
	IF_PLUS
		REPEAT
			CMP	vramSlots::tileset, X
			BEQ	Process_One__Found_X

			LDY	vramSlots::next, X
			BMI	BREAK_LABEL

			CMP	vramSlots::tileset, Y
			BEQ	Process_One__Found_Y

			LDX	vramSlots::next, Y
		UNTIL_MINUS

	ENDIF

	LDX	vramSlotList::freeList
	BMI	Process_One__NoSlotsFound


.I8
.A16
	; Tileset not found, but a free slot exists

	; ::SHOULDO add vblank timing check::

	; Check if table has overflowed
	LDY	dmaTableIndex
	CPY	#METASPRITE_DMA_TABLE_COUNT * 2
	BGE	Process_One__NoSlotsFound

	PHX

	; Remove slot from free list
	; And insert into fixed tiles list
	;
	; current->prev = NULL
	; current->pair = NULL
	; FreeList.first = current->next
	;
	; current->next = tilesetList.first
	; current->next->prev = current
	; tilesetList.first = current
	SEP	#$30
.A8
	LDA	#$80
	STA	vramSlots::prev, X
	STA	vramSlots::pair, X

	LDY	vramSlots::next, X
	STY	vramSlotList::freeList

	LDA	vramSlotList::tilesetList
	STA	vramSlots::next, X

	TAY
	TXA

	STA	vramSlots::prev, Y
	STA	vramSlotList::tilesetList

	PLX

	BRA	Process_One__DmaTable
.endmacro


; IN: tmp_tileset = tileset to find
.A16
.I16
.proc Process_OneTile
	_Process_One oneFixedTileList, freeTiles
.endproc


.proc Process_One__NoSlotsFound
	; no free slots left
	REP	#$31
.A16
.I16
	; C clear
	RTS
.endproc


; An existing tileset was found, update state
.I8
.A16
.proc Process_One__Found_Y
	TYX
	.assert * = Process_One__Found_X, error, "Bad FLow"
.endproc


; An existing tileset was found, update state
.I8
.A16
.proc Process_One__Found_X
	; Calculate new offset
	LDA	z:MSDP::blockOneCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockOneCharAttrOffset

	SEP	#$30
.A8
.I8
	INC	vramSlots::count, X

	; update status
	LDA	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "Bad assumption"
	ASL
	IF_C_SET
		TXA
		LSR
		ORA	#METASPRITE_STATUS_PALETTE_SET_FLAG | METASPRITE_STATUS_VRAM_SET_FLAG
	ELSE
		TXA
		LSR
		ORA	#METASPRITE_STATUS_VRAM_SET_FLAG
	ENDIF

	STA	z:MSDP::status

	REP	#$30
.A16
.I16
	SEC
	RTS
.endproc


; IN: tmp_tileset = tileset to find
.A16
.I16
.proc Process_OneRow
	_Process_One oneFixedRowList, freeRows
.endproc


; Creates the DMA table for the given slots
; IN: tmp_tileset = tileset address
; IN: X = address of first slot
.A8
.I8
.proc Process_One__DmaTable
	; Increase reference count
	INC	vramSlots::count, X

	; update status
	LDA	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "Bad assumption"
	ASL
	IF_C_SET
		TXA
		LSR
		ORA	#METASPRITE_STATUS_PALETTE_SET_FLAG | METASPRITE_STATUS_VRAM_SET_FLAG
	ELSE
		TXA
		LSR
		ORA	#METASPRITE_STATUS_VRAM_SET_FLAG
	ENDIF

	STA	z:MSDP::status


	REP	#$20
.A16
	; Calculate new charattr offset
	LDA	z:MSDP::blockOneCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockOneCharAttrOffset

	JMP	SetupDmaForOneTilesetBlock
.endproc


.macro _Process_Two tilesetList, freeList
	.assert .asize = 16, error, "bad asize"

	LDA	tmp_tileset

	SEP	#$10
.I8
	; Search for duplicate tilesets
	LDX	vramSlotList::tilesetList
	IF_PLUS
		REPEAT
			CMP	vramSlots::tileset, X
			BEQ	Process_Two__Found_X

			LDY	vramSlots::next, X
			BMI	BREAK_LABEL

			CMP	vramSlots::tileset, Y
			BEQ	Process_Two__Found_Y

			LDX	vramSlots::next, Y
		UNTIL_MINUS

	ENDIF

	LDX	vramSlotList::freeList
	BMI	Process_Two__NoSlotsFound
	LDY	vramSlots::next, X
	BMI	Process_Two__NoSlotsFound


.I8
.A16
	STX	tmp_firstSlot
	STY	tmp_secondSlot

	; Tileset not found, but two free slots exist

	; ::SHOULDO add vblank timing check::

	; Check if table has overflowed
	LDA	dmaTableIndex
	CPA	#(METASPRITE_DMA_TABLE_COUNT - 1) * 2
	BGE	Process_Two__NoSlotsFound

	; Remove both slots from free list
	; Connect second slot to first slot (pair).
	; Insert first slot into fixed tiles list
	;
	; freeList = second->next
	; first->pair = second
	; first->prev = NULL
	;
	; first->next = tilesetList
	; first->next->prev = first
	; tilesetList = first

	SEP	#$20
.A8
	; X = first
	; Y = second

	LDA	vramSlots::next, Y
	STA	vramSlotList::freeList

	TYA
	STA	vramSlots::pair, X

	LDA	#$80
	STA	vramSlots::prev, X

	LDA	vramSlotList::tilesetList
	STA	vramSlots::next, X

	TAY
	TXA
	STA	vramSlots::prev, Y

	STA	vramSlotList::tilesetList

	JMP	Process_Two__DmaTable
.endmacro


; IN: tmp_tileset = tileset to find
.A16
.I16
.proc Process_TwoTiles
	_Process_Two twoFixedTilesList, freeTiles
.endproc


.proc Process_Two__NoSlotsFound
	; no free slots left
	REP	#$31
.A16
.I16
	; C clear
	RTS
.endproc


; An existing tileset was found, update state
.I8
.A16
.proc Process_Two__Found_Y
	TYX
	.assert * = Process_Two__Found_X, error, "Bad FLow"
.endproc


; An existing tileset was found, update state
.I8
.A16
.proc Process_Two__Found_X
	; Calculate new offset

	TXY

	LDA	z:MSDP::blockOneCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockOneCharAttrOffset

	LDA	vramSlots::pair, X
	TAX

	LDA	z:MSDP::blockTwoCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockTwoCharAttrOffset

	TYX

	SEP	#$30
.A8
.I8
	INC	vramSlots::count, X

	; update status
	LDA	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "Bad assumption"
	ASL
	IF_C_SET
		TXA
		LSR
		ORA	#METASPRITE_STATUS_PALETTE_SET_FLAG | METASPRITE_STATUS_VRAM_SET_FLAG
	ELSE
		TXA
		LSR
		ORA	#METASPRITE_STATUS_VRAM_SET_FLAG
	ENDIF

	STA	z:MSDP::status

	REP	#$30
.A16
.I16
	SEC
	RTS
.endproc


; IN: tmp_tileset = tileset to find
.A16
.I16
.proc Process_TwoRows
	_Process_Two twoFixedRowsList, freeRows
.endproc



; Creates the DMA table for the given slots
; IN: tmp_tileset = tileset address
; IN: tmp_firstSlot = address of first slot
; IN: tmp_secondSlot = address of second slot
.A8
.I8
.proc Process_Two__DmaTable
	LDX	tmp_firstSlot

	; Increase reference count
	INC	vramSlots::count, X

	; update status
	LDA	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "Bad assumption"
	ASL
	IF_C_SET
		TXA
		LSR
		ORA	#METASPRITE_STATUS_PALETTE_SET_FLAG | METASPRITE_STATUS_VRAM_SET_FLAG
	ELSE
		TXA
		LSR
		ORA	#METASPRITE_STATUS_VRAM_SET_FLAG
	ENDIF

	STA	z:MSDP::status


	REP	#$20
.A16
	; Calculate new charAttr Offsets
	LDX	tmp_secondSlot
	LDA	z:MSDP::blockTwoCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockTwoCharAttrOffset


	LDX	tmp_firstSlot
	LDA	z:MSDP::blockOneCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockOneCharAttrOffset


	; X = VRAM slot index
	JMP	SetupDmaForTwoTilesetBlocks
.endproc

.delmacro _Process_One
.delmacro _Process_Two
.endroutine





;; Allocates the appropriate amount of VRAM to the metasprite
;; and upload the given tileset.
;;
;; This routine should only be called by Activate
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
.routine Activate_DynamicTileset
	LDX	z:MSDP::currentFrame
	LDA	f:frameDataOffset + MetaSprite__Frame::tileset, X
	BEQ	Failure

	STA	tmp_tileset
	TAX

	.assert METASPRITE_STATUS_VRAM_SET_FLAG = 1, error, "Bad code"
	LDA	z:MSDP::status
	LSR
	IF_C_SET
		; Tiles allocated, just update them if necessary
		TXA
		JMP	SetFrame_DynamicTileset_A
	ENDIF

	; As there are 4 different tileset types, we need 4 different
	; searches.
	LDX	z:MSDP::frameSet
	LDA	f:frameSetOffset + MetaSprite__FrameSet::tilesetType, X
	AND	#3 << 1
	TAX
	JMP	(.loword(TilesetTypeTable), X)

Failure:
	CLC
	RTS

.rodata
TilesetTypeTable:
	.assert MetaSprite__FrameSet_TilesetSize::TWO_VRAM_ROWS = 6, error, "Bad Table"

	; Must match MetaSprite__FrameSet_TilesetSize
	.addr	Process_OneTile
	.addr	Process_TwoTiles
	.addr	Process_OneRow
	.addr	Process_TwoRows

.code


.macro _Process_One freeList
	SEP	#$30
.A8
.I8
	LDX	vramSlotList::freeList
	BMI	NoSlotsFound

	LDA	vramSlots::next, X
	STA	vramSlotList::freeList

	BRA	_ProcessOne_SlotFound
.endmacro


.macro _Process_Two freeList
	SEP	#$30
.A8
.I8
	LDX	vramSlotList::freeList
	BMI	NoSlotsFound
	LDY	vramSlots::next, X
	BMI	NoSlotsFound

	LDA	vramSlots::next, Y
	STA	vramSlotList::freeList

	BRA	_ProcessTwo_SlotsFound
.endmacro

.A16
.I16
.proc Process_OneTile
	_Process_One freeTiles
.endproc

.A16
.I16
.proc Process_OneRow
	_Process_One freeRows
.endproc

.A16
.I16
.proc Process_TwoTiles
	_Process_Two freeTiles
.endproc

.A16
.I16
.proc Process_TwoRows
	_Process_Two freeRows
.endproc



NoSlotsFound:
	REP	#$31
	; 16 A, 16 Index, C clear
	RTS



;; IN: X = slot
;; IN: tmp_tileset = tileset
;; REQUIRES slot removed from free list
;; OUT: calls SetupDmaForOneTilesetBlock
.A8
.I8
.proc _ProcessOne_SlotFound
	LDY	dmaTableIndex
	CPY	#METASPRITE_DMA_TABLE_COUNT * 2
	BGE	NoSlotsFound

	; ::SHOULDO add vblank overflow check::


	; Set slot as a single dynamic tileset

	LDA	#1
	STA	vramSlots::count, X

	LDA	#$80
	STA	vramSlots::next, X
	STA	vramSlots::prev, X
	STA	vramSlots::pair, X


	; update status
	LDA	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "Bad assumption"
	ASL
	IF_C_SET
		TXA
		LSR
		ORA	#METASPRITE_STATUS_PALETTE_SET_FLAG | METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	ELSE
		TXA
		LSR
		ORA	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	ENDIF

	STA	z:MSDP::status


	REP	#$20
.A16
	; Calculate new offset
	LDA	z:MSDP::blockOneCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockOneCharAttrOffset

	BRA	SetupDmaForOneTilesetBlock
.endproc



;; IN: X = slot1, Y = slot2
;; IN: tmp_tileset = tileset
;; REQUIRES: both slots removed from free list
;; OUT: calls SetupDmaForOneTilesetBlock
.A8
.I8
.proc _ProcessTwo_SlotsFound
	LDA	dmaTableIndex
	CMP	#METASPRITE_DMA_TABLE_COUNT * 2
	BGE	NoSlotsFound

	; ::SHOULDO add vblank overflow check::

	; Set slot as a dual dynamic tileset
	; X = first
	; Y = second
	TYA
	STA	vramSlots::pair, X

	LDA	#1
	STA	vramSlots::count, X

	LDA	#$80
	STA	vramSlots::next, X
	STA	vramSlots::prev, X

	; update status
	LDA	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "Bad assumption"
	ASL
	IF_C_SET
		TXA
		LSR
		ORA	#METASPRITE_STATUS_PALETTE_SET_FLAG | METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	ELSE
		TXA
		LSR
		ORA	#METASPRITE_STATUS_VRAM_SET_FLAG | METASPRITE_STATUS_DYNAMIC_TILESET_FLAG
	ENDIF

	STA	z:MSDP::status


	REP	#$20
.A16
	PHX

	; Calculate new charattr offsets
	LDA	z:MSDP::blockOneCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockOneCharAttrOffset

	TYX
	LDA	z:MSDP::blockTwoCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockTwoCharAttrOffset

	PLX

	BRA	SetupDmaForTwoTilesetBlocks
.endproc


.delmacro _Process_One
.delmacro _Process_Two
.endroutine



;; Updates the frame of a MetaSprite with a dynamic tileset
;;
;; This macro will only set `MSDP::currentFrame` only if there
;; is space in VBlank to upload the tile.
;; ::TODO think about this behaviour::
;;
;; SHOULD only be used by `metasprite.s`
;;
;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
;; ASSUMES: METASPRITE_STATUS_DYNAMIC_TILESET_FLAG is set
;;
;; INPUT:
;;	A: frame
;;	DP: MetaSpriteStruct address - MetaSpriteDpOffset
;;
;; OUTPUT: Branch to Success/Failure or RTS with C set
.A16
.I16
.macro SetFrame_DynamicTileset
	.assert .asize = 16, error, "Bad asize"
	.assert .isize = 16, error, "Bad isize"

	; Check if the tileset is the same as the previous one

	TAX
	LDA	f:frameDataOffset + MetaSprite__Frame::tileset, X
	BEQ	Failure

::SetFrame_DynamicTileset_A:
	STA	tmp_tileset

	LDA	z:MSDP::status
	AND	#METASPRITE_STATUS_VRAM_INDEX_MASK
	ASL
	TAY

	LDA	tmp_tileset
	CMP	vramSlots::tileset, Y
	IF_EQ
		; Don't need to upload tileset, return true
		STX	z:MSDP::currentFrame
		SEC
		RTS
	ENDIF


	; Check if there is space in DMA Table
	; ::SHOULDO add vblank timing check::

	; MUST NOT USE X or Y

	LDA	dmaTableIndex
	CMP	#(METASPRITE_DMA_TABLE_COUNT - 1) * 2
	BGE	Failure


	; Can upload frame to VRAM.
	; Save current frame in MSDP

	STX	z:MSDP::currentFrame


	; Setup DMA table
	LDX	z:MSDP::frameSet
	LDA	f:frameSetOffset + MetaSprite__FrameSet::tilesetType, X

	TYX
	SEP	#$10
.I8
	; X = slot
	IF_BIT	#MetaSprite__FrameSet_TilesetSize::ONE_VRAM_ROW | MetaSprite__FrameSet_TilesetSize::ONE_16_TILE
		JMP	SetupDmaForOneTilesetBlock
	ENDIF

	JMP	SetupDmaForTwoTilesetBlocks


	.assert MetaSprite__FrameSet_TilesetSize::TWO_VRAM_ROWS | MetaSprite__FrameSet_TilesetSize::TWO_16_TILES <> MetaSprite__FrameSet_TilesetSize::ONE_VRAM_ROW | MetaSprite__FrameSet_TilesetSize::ONE_16_TILE, error, "Bad assumption"
.endmacro


;; Sets up the DMA Table for VBlank transfer of a single tileset block
;;
;; Also sets the tileset address to the vram slot tileset value
;;
;; Does not check DMA Table position, that is handled by caller function
;;
;; INPUT: tmp_tileset = tileset to process
;; INPUT: X = vramSlot slot to process to
;; OUTPUT: C set, 16 bit A, 16 bit Index
.A16
.I8
.routine SetupDmaForOneTilesetBlock
	LDY	dmaTableIndex

	; Add slot vram address to DMA table
	LDA	f:vramSlots::VramAddresses, X
	STA	dmaTable::vramAddress, Y

	; Store tileset address in slot
	LDA	tmp_tileset
	STA	vramSlots::tileset, X


	; Add to tileset data to DMA table
	; ::SHOULDO better tileset data format::

AddDmaTable:
	REP	#$30
.A16
.I16
	LDX	tmp_tileset
	LDA	f:tilesetBankOffset + MetaSprite__Tileset::dmaTable0, X
	STA	dmaTable::tablePtr, Y

	INY
	INY
	STY	dmaTableIndex

	SEC
	RTS
.endroutine



;; Sets up the DMA Table for VBlank transfer for a dual block tileset.
;;
;; Also sets the tileset address to the vram slot tileset value
;;
;; Does not check DMA Table position, that is handled by caller function
;;
;; INPUT: tmp_tileset = tileset
;; INPUT: X = vramSlot
;; OUTPUT: C set, 16 bit A, 16 bit Index
.A16
.I8
.routine SetupDmaForTwoTilesetBlocks
	LDY	dmaTableIndex

	; Add slot vram addresses for DMA table
	LDA	f:vramSlots::VramAddresses, X
	STA	dmaTable::vramAddress, Y

	; Store tileset address in slot
	LDA	tmp_tileset
	STA	vramSlots::tileset, X


	; Get second slot address
	LDA	vramSlots::pair, X
	; Catch possible bug - storing two block in a one block allocation
	BMI	SetupDmaForOneTilesetBlock::AddDmaTable

	TAX
	LDA	f:vramSlots::VramAddresses, X
	STA	dmaTable::vramAddress + 2, Y


	; Add tileset data to DMA table
	; ::SHOULDO better tileset data format::

	REP	#$30
.A16
.I16
	LDX	tmp_tileset
	LDA	f:tilesetBankOffset + MetaSprite__Tileset::dmaTable0, X
	STA	dmaTable::tablePtr, Y

	INY
	INY

	LDA	f:tilesetBankOffset + MetaSprite__Tileset::dmaTable1, X
	IF_NOT_ZERO
		STA	dmaTable::tablePtr, Y
		INY
		INY
	ENDIF

	STY	dmaTableIndex

	SEC
	RTS
.endroutine

