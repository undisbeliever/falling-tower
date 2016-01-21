
.include "metasprite.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/synthetic.inc"

.setcpu "65816"

.exportlabel updatePaletteBufferOnZero
.exportlabel paletteBuffer, far


.define N_PALETTE_SLOTS 8

.segment "SHADOW"
	;; The palette buffer needs to be copied to VRAM if this is 0
	; ::TODO should move to different class;
	updatePaletteBufferOnZero: .res 1

.segment "WRAM7E"
	;; Table that contains the address/reference count of each palette
	;; used by the MetaSprite engine.
	;;
	;; Converting from slot index to useful values:
	;;
	;;  OAM Palette ID = slot index / 2
	;;  Palette Buffer Offset = slot index * 16
	;;
	;; Double Linked List Array of structures
	.proc paletteSlots
		;; the number of bytes between slot(n+1) & slot(n)
		SlotMemoryIncreament = 2

		;; next item in the list
		;; (byte index, >= $80 is null)
		next:		.res N_PALETTE_SLOTS * 2

		;; previous item in the list.
		;; NOT set when in free list
		;; (byte index, >= $80 is NULL)
		prev = next - 1

		;; address of the palette in `METASPRITE_PALETTE_DATA_BLOCK` 
		;; (word address)
		paletteAddress:	.res N_PALETTE_SLOTS * 2

		;; Number of times the palette is used
		;; (byte)
		count:		.res N_PALETTE_SLOTS * 2
	.endproc

	.scope paletteSlotList
		;; The first slot in the used list
		;; (byte index, >= $80 is NULL)
		first:		.res 1

		;; The next free slot in the list
		;; (byte index, >= $80 is NULL)
		free:		.res 1
	.endscope

	;; The sprite palette buffer
	; ::TODO should move to different module:
	paletteBuffer:		.res N_PALETTE_SLOTS * 32


.code


; DB = $7E
.A16
.I16
.macro Reset__Palette
	.assert .asize = 16, error, "Bad asize"
	.assert .isize = 16, error, "Bad isize"

	SEP	#$30
.A8
.I8
	LDA	#paletteSlots::SlotMemoryIncreament
	LDX	#0

	CLC
	REPEAT
		STA	paletteSlots::next, X
		TAX

		; Carry clear from branch
		ADC	#paletteSlots::SlotMemoryIncreament
		CMP	#N_PALETTE_SLOTS * paletteSlots::SlotMemoryIncreament
	UNTIL_GE

	; Terminate end of list
	LDA	#$80
	STA	paletteSlots::next + paletteSlots::SlotMemoryIncreament * (N_PALETTE_SLOTS - 1)

	; Reset slot lists
	STA	paletteSlotList::first
	STZ	paletteSlotList::free

	; A = nonzero
	STA	updatePaletteBufferOnZero

	REP	#$30
.A16
.I16
.endmacro


; DP: MetaSpriteStruct address - MetaSpriteDpOffset
; DB: $7E
; Does not reset MSDP::palette
.A16
.I16
.macro RemovePalette
	; Decrement counter

	SEP	#$30
.A8
.I8
	BIT	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "BIT optimisation"
	IF_N_SET
		; luckily palette bits match the palette slot index
		LDA	z:MSDP::blockOneCharAttrOffset + 1
		AND	#OAM_ATTR_PALETTE_MASK
		TAX

		DEC	paletteSlots::count, X
		IF_ZERO
			JSR	__RemovePaletteSlot
		ENDIF

		LDA	#METASPRITE_STATUS_PALETTE_SET_FLAG
		TRB	z:MSDP::status
	ENDIF

	REP	#$30
.A16
.I16
.endmacro


;; moves palette slot from used list and into free list
;; IN: X = slot index
.A8
.I8
.proc __RemovePaletteSlot
	; remove from used list
	;
	; if current.prev is NULL:
	;	list.first = current.next
	; else:
	;	current.prev.next = current.next
	;
	; if current.next:
	;	current.next.prev = current.next

	LDY	paletteSlots::prev, X
	IF_MINUS
		; first item in list
		LDA	paletteSlots::next, X
		STA	paletteSlotList::first, Y
	ELSE
		; in middle of list
		; Y = current.prev
		LDA	paletteSlots::next, X
		STA	paletteSlots::next, Y
	ENDIF

	; A = current.next
	TAY
	IF_PLUS
		LDA	paletteSlots::prev, X
		STA	paletteSlots::prev, Y
	ENDIF

	; Add to current free list
	;
	; tmp = list.free
	; list.free = current
	; current.next = tmp

	LDA	paletteSlotList::free
	STX	paletteSlotList::free

	STA	paletteSlots::next, X

	RTS
.endproc



SetPalette_Failure:
	CLC
	RTS

; A: Palette Id
; DP: MetaSpriteStruct address - MetaSpriteDpOffset
; OUT: carry set if succeeded
; DB: $7E
.A16
.I16
.routine SetPalette
	LDX	z:MSDP::frameSet
	BEQ	SetPalette_Failure

	SEP	#$20
.A8
	CMP	f:frameSetOffset + MetaSprite__FrameSet::nPalettes, X
	REP	#$20
.A16
	BGE	SetPalette_Failure

	AND	#$00FF
	ASL
	; Carry clear
	ADC	f:frameSetOffset + MetaSprite__FrameSet::paletteList, X
	TAX
	LDA	f:paletteListOffset, X

	.assert * = SetPaletteAddress, error, "Bad Flow"
.endroutine



; A: Palette address
; DP: MetaSpriteStruct address - MetaSpriteDpOffset
; OUT: carry set if succeeded
; DB: $7E
.A16
.I16
.routine SetPaletteAddress

tmp_slotIndex	:= tmp1

	STA	z:MSDP::palette
	CMP	#0
	BEQ	ReturnFalse

	SEP	#$10
.I8

	LDY	z:MSDP::status
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "Bad code"
	IF_N_SET
		; MS already has a palette
		; Check if the palette has changed
		; If address has changed, decrement reference count
		; If address if equal, just return true

		; luckally palette bits match the palette slot index
		LDA	z:MSDP::blockOneCharAttrOffset + 1
		AND	#OAM_ATTR_PALETTE_MASK
		TAX

		STA	z:MSDP::palette
		CMP	paletteSlots::paletteAddress, X
		IF_EQ
			; Return true
			REP	#$30
			; C set by CMP
			RTS
		ENDIF

		; Palette has changed, decrement counter
		DEC	paletteSlots::count, X
		IF_MINUS
			SEP	#$20
.A8
			JSR __RemovePaletteSlot

			REP	#$20
.A16
		ENDIF

		LDA	z:MSDP::palette
	ENDIF


	; Search for an duplicate/free palette slot
	; A = palette address

	LDX	paletteSlotList::first
	IF_PLUS
		REPEAT
			CMP	paletteSlots::paletteAddress, X
			BEQ	Found_X

			LDY	paletteSlots::next, X
			BMI	BREAK_LABEL

			CMP	paletteSlots::paletteAddress, Y
			BEQ	Found_Y

			LDX	paletteSlots::next, Y
		UNTIL_MINUS
	ENDIF

	; No duplicates found

	LDX	paletteSlotList::free
	IF_MINUS
ReturnFalse:
		REP	#$31
		; 16 bit A, 16 bit Index, Carry clear
		RTS
	ENDIF


	; New slot
	; Remove from free list, insert into used list

	STX	tmp_slotIndex

	; current->address = metasprite->palette
	; current->count = 1
	;
	; current->prev = NULL
	; current->next = paletteList.first
	; current->next->prev = current
	; paletteList.first = current

	; A = palette address
	STA	paletteSlots::paletteAddress, X

	LDA	#1
	STA	paletteSlots::count, X

	SEP	#$20
.A8

	LDA	#$80
	STA	paletteSlots::prev, X

	LDY	paletteSlots::next, X
	STY	paletteSlotList::free

	LDA	paletteSlotList::first
	STA	paletteSlots::next, X

	TAY
	TXA
	STA	paletteSlots::prev, Y
	STA	paletteSlotList::first

	REP	#$30
.A16
.I16
CopyPalette:
	; X = slot table index

	STX	tmp_slotIndex
	TXA
	ASL
	ASL
	ASL
	ASL
	ADC	#.loword(paletteBuffer + 2)
	TAY

	; ::SHOULDO replace with DMA::

	LDX	z:MSDP::palette
	LDA	#15 * 2 - 1
	MVN	$7E, paletteDataBank		; ca65 uses dest,src


; Update charAttrOffset bits
	SEP	#$20
.A8
	STZ	updatePaletteBufferOnZero


SetMetaSpriteState:
	; A slot is found with the correct palette
	; Update metasprite state

	SEP	#$31
.A8
.I8
	; Carry Set
	; (c never changed by AND or ORA or TSB)

	; Set palette bits in offsets
	; luckally palette bits match the palette slot index
	; slotIndex always <= 7 * 2

	LDA	z:MSDP::blockOneCharAttrOffset + 1
	AND	#.hibyte(~OAM_ATTR_PALETTE_MASK)
	ORA	tmp_slotIndex
	STA	z:MSDP::blockOneCharAttrOffset + 1

	LDA	z:MSDP::blockTwoCharAttrOffset + 1
	AND	#.hibyte(~OAM_ATTR_PALETTE_MASK)
	ORA	tmp_slotIndex
	STA	z:MSDP::blockTwoCharAttrOffset + 1

	LDA	#METASPRITE_STATUS_PALETTE_SET_FLAG
	TSB	z:MSDP::status

	REP	#$30
.A16
.I16
	; C Set
	RTS


Found_Y:
	TYX
Found_X:
	STX	tmp_slotIndex
	BRA	SetMetaSpriteState
.endroutine



; DB: $7E
.A16
.I16
.routine ReloadPalettes

slotIndex	:= tmp1
bufferAddress	:= tmp2

	LDY	#.loword(paletteBuffer) + (N_PALETTE_SLOTS - 1) * 32 + 2

	LDX	#(N_PALETTE_SLOTS - 1) * 2
	REPEAT
		LDA	paletteSlots::count, X
		BEQ	Skip
		LDA	paletteSlots::paletteAddress, X
		BEQ	Skip

			STX	slotIndex
			STY	bufferAddress

			TAX
			LDA	#15 * 2 - 1
			MVN	$7E, paletteDataBank	; ca65 uses dest,src

			LDX	slotIndex
			LDY	bufferAddress

Skip:
		TYA
		SUB	#16 * 2
		TAY

		DEX
		DEX
	UNTIL_MINUS

	SEP	#$20
.A8
	STZ	updatePaletteBufferOnZero

	REP	#$20
.A16

	RTS
.endroutine

