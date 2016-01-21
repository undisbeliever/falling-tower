
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
tmp_firstSlot	:= tmp2
tmp_secondSlot	:= tmp3

	LDX	z:MSDP::frameSet
	LDA	f:frameSetOffset + MetaSprite__FrameSet::tileset, X

::UploadFixedTileset:
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
	; Add vram address to DMA table
	LDY	dmaTableIndex
	LDA	f:vramSlots::VramAddresses, X
	STA	dmaTable::vramAddress, Y


	; Calculate new offset
	LDA	z:MSDP::blockOneCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockOneCharAttrOffset


	; Store tileset for future checking
	LDA	tmp_tileset
	STA	vramSlots::tileset, X


	; Add to tileset DMA table
	; ::SHOULDO better DMA table format::

	LDY	dmaTableIndex

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
	LDY	dmaTableIndex

	; Store tileset for future checking
	LDA	tmp_tileset
	STA	vramSlots::tileset, X

	; Add vram addresses to DMA tables
	LDY	dmaTableIndex
	LDA	f:vramSlots::VramAddresses, X
	STA	dmaTable::vramAddress, Y

	; Calculate new offset for second table
	LDA	z:MSDP::blockOneCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockOneCharAttrOffset


	; Store second slot data
	LDX	tmp_secondSlot
	LDA	f:vramSlots::VramAddresses, X
	STA	dmaTable::vramAddress + 2, Y

	LDA	z:MSDP::blockTwoCharAttrOffset
	AND	#.loword(~OAM_CHARATTR_CHAR_MASK)
	ORA	f:vramSlots::CharAttrOffset, X
	STA	z:MSDP::blockTwoCharAttrOffset


	REP	#$30
.A16
.I16

	LDX	tmp_tileset
	LDA	f:tilesetBankOffset + MetaSprite__Tileset::dmaTable0, X
	STA	dmaTable::tablePtr, Y

	INY
	INY

	LDA	f:tilesetBankOffset + MetaSprite__Tileset::dmaTable1, X
	STA	dmaTable::tablePtr, Y

	INY
	INY
	STY	dmaTableIndex

	SEC
	RTS
.endproc

.endroutine

