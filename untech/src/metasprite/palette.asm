
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
	;; Table that conatains the address/refence count of each palette
	;; used by the MetaSprite engine
	;; Array of structures
	.proc paletteSlots
		ptr:		.res N_PALETTE_SLOTS * 2
		count:		.res N_PALETTE_SLOTS * 2
	.endproc

	;; The sprite palette buffer
	; ::TODO should move to different class;
	paletteBuffer:		.res N_PALETTE_SLOTS * 32


.code


; DB = $7E
.A16
.I16
.macro Init__Palette
	LDX	#(N_PALETTE_SLOTS - 1) * 2
	REPEAT
		STZ	paletteSlots::ptr, X
		STZ	paletteSlots::count, X
		DEX
		DEX
	UNTIL_MINUS

	LDA	#1
	TSB	updatePaletteBufferOnZero
.endmacro


; DP: MetaSpriteStruct address - MetaSpriteDpOffset
; DB: $7E
.A16
.I16
.routine RemovePalette
	; Decrement counter

	BIT	z:MSDP::status - 1
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "BIT optimisation"
	IF_N_SET
		; luckally palette bits match the palette slot index
		LDA	z:MSDP::blockOneCharAttrOffset + 1
		AND	#OAM_ATTR_PALETTE_MASK
		TAX

		LDA	paletteSlots::count, X
		DEC
		IF_MINUS
			LDA	#0
		ENDIF
		STA	paletteSlots::count, X

		LDA	#METASPRITE_STATUS_PALETTE_SET_FLAG
		TRB	z:MSDP::status
	ENDIF

Return:
	RTS
.endroutine


; A: Palette address
; DP: MetaSpriteStruct address - MetaSpriteDpOffset
; OUT: carry set if succeeded
; DB: $7E
.A16
.I16
.routine SetPaletteAddress

tmp_palettePtr	:= tmp1
tmp_slotIndex	:= tmp2
firstFreeSlot	:= tmp3

	BIT	z:MSDP::status - 1
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "BIT optimisation"
	IF_N_SET
		TAY

		; MS already has a palette
		; Check if the palette has changed
		; If address has changed, decrement reference count
		; If address if equal, just return true

		; luckally palette bits match the palette slot index
		LDA	z:MSDP::blockOneCharAttrOffset + 1
		AND	#OAM_ATTR_PALETTE_MASK
		TAX

		TYA
		CMP	paletteSlots::ptr, X
		BRA	Return		; C set

		; Palette has changed, decrement counter
		LDA	paletteSlots::count, X
		DEC
		IF_MINUS
			LDA	#0
		ENDIF
		STA	paletteSlots::count, X

		TYA
	ENDIF

	CMP	#0
	BEQ	ReturnFalse

	STA	tmp_palettePtr

	; Search for an duplicate/free palette slot
	LDX	#$8000
	STX	firstFreeSlot

	LDX	#(N_PALETTE_SLOTS - 1) * 2
	REPEAT
		CMP	paletteSlots::ptr, X
		IF_EQ
			INC	paletteSlots::count, X
			STX	tmp_slotIndex
			BRA	DuplicateSlotFound	; C is set
		ENDIF

		LDY	paletteSlots::count, X
		IF_ZERO
			STX	firstFreeSlot
		ENDIF

		DEX
		DEX
	UNTIL_MINUS

	LDX	firstFreeSlot
	IF_MINUS
		; Could not find slot
ReturnFalse:
		CLC
Return:
		RTS
	ENDIF

	; First time palette is used in slot

	LDA	#1
	STA	paletteSlots::count, X
	LDA	tmp_palettePtr
	STA	paletteSlots::ptr, X


CopyPalette:
	; tmp_palettePtr = palette address
	; X = slot table index

	STX	tmp_slotIndex
	TXA
	ASL
	ASL
	ASL
	ASL
	ADC	#.loword(paletteBuffer + 2)
	TAY

	LDX	tmp_palettePtr

	LDA	#15 * 2 - 1
	MVN	$7E, paletteDataBank		; ca65 uses dest,src


; Update charAttrOffset bits
	SEP	#$20
.A8
	STZ	updatePaletteBufferOnZero

DuplicateSlotFound:
	SEP	#$21
.A8
	; Carry Set
	; (c never changed by AND or ORA)

	; Set palette bits in offsets
	; luckally palette bits match the palette slot index
	; tmp_slotIndex always <= 7 * 2

	LDA	z:MSDP::blockOneCharAttrOffset + 1
	AND	#.lobyte(~OAM_ATTR_PALETTE_MASK)
	ORA	tmp_slotIndex
	STA	z:MSDP::blockOneCharAttrOffset + 1

	LDA	z:MSDP::blockTwoCharAttrOffset + 1
	AND	#.lobyte(~OAM_ATTR_PALETTE_MASK)
	ORA	tmp_slotIndex
	STA	z:MSDP::blockTwoCharAttrOffset + 1

	LDA	#METASPRITE_STATUS_PALETTE_SET_FLAG
	TSB	z:MSDP::status

	REP	#$20
.A16
	; C Set
	RTS
.endroutine



; DP: MetaSpriteStruct address - MetaSpriteDpOffset
; DB: $7E
; Return: A - palette address
;	zero: set if no metasprite has no palette
.A16
.I16
.routine GetPaletteAddress

	BIT	z:MSDP::status - 1
	.assert METASPRITE_STATUS_PALETTE_SET_FLAG = $80, error, "BIT optimisation"
	IF_N_CLEAR
		LDA	#0
		RTS
	ENDIF

	; luckally palette bits match the palette slot index
	LDA	z:MSDP::blockOneCharAttrOffset + 1
	AND	#OAM_ATTR_PALETTE_MASK
	TAX

	LDA	paletteSlots::ptr, X
	RTS
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
		LDA	paletteSlots::ptr, X
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

