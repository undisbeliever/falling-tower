
.include "metasprite.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/synthetic.inc"

.setcpu "65816"

.segment "WRAM7E"
	dma_vramAddress:	.res 2


.code


.routine TransferTileBuffer
	PHP
	PHD
	PHB

	SEP	#$20
.A8
	LDA	#$80
	PHA
	PHB

	REP	#$30
.A16
.I16
	LDA	#$4300
	TCD

	JSR	_TransferTiles

	PLB
	PLD
	PLP
	RTS
.endroutine


; DP = $4300
; DB = $80
.A16
.I8
.routine VBlank

	LDX	MetaSprite::updateOamBufferOnZero
	IF_ZERO
		STZ	OAMADD

		LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG | (.lobyte(OAMDATA) << 8)
		STA	z:<DMAP0	; also sets BBAD0

		LDA	#.loword(MetaSprite::oamBuffer)
		STA	z:<A1T0
		LDX	#.bankbyte(MetaSprite::oamBuffer)
		STX	z:<A1B0

		LDA	#MetaSprite::oamBuffer_size
		STA	z:<DAS0

		LDX	#MDMAEN_DMA0
		STX	MDMAEN

		STX	MetaSprite::updateOamBufferOnZero
	ENDIF

	LDX	MetaSprite::updatePaletteBufferOnZero
	IF_ZERO
		LDX	#128
		STX	CGADD

		LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG | (.lobyte(CGDATA) << 8)
		STA	z:<DMAP0	; also sets BBAD0

		LDA	#.loword(MetaSprite::paletteBuffer)
		STA	z:<A1T0
		LDX	#.bankbyte(MetaSprite::paletteBuffer)
		STX	z:<A1B0

		LDA	#MetaSprite::paletteBuffer_size
		STA	z:<DAS0

		LDX	#MDMAEN_DMA0
		STX	MDMAEN

		STX	MetaSprite::updatePaletteBufferOnZero
	ENDIF

::_TransferTiles:
	LDA	dmaTableIndex
	IF_NOT_ZERO
		LDX	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
		STX	a:VMAIN

		REP	#$30
.A16
.I16
		TAX

		LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
		.repeat 8, i
			STA	z:<DMAP0 + i * 16	; also sets BBAD0
		.endrepeat

		PEA     $80 << 8 | dmaTableBank
		PLB

		REPEAT
			DEX
			DEX
			PHX

			LDA	f:dmaTable::vramAddress, X
			STA	f:VMADD
			STA	f:dma_vramAddress

			LDA	f:dmaTable::tablePtr, X
			TAY

			LDA	a:0 + MetaSprite__DmaTable::transferType, Y
			AND	#$E
			TAX
			JMP	(.loword(TransferTable), X)
ReturnFromTranfer:

.A8
			REP	#$30
.A16
.I16
			PLX
		UNTIL_ZERO

		PLB

		STZ	dmaTableIndex

		SEP	#$10
.I8
	ENDIF

	RTS




; Copies `nTiles` of data from MetaSprite__DmaTable into DMA registers and activates them
; DB = dmaTableBank
; DP = $4300
; Y = address of MetaSprite__DmaTable
; dma_vramAddress = vram word address
.macro _Transfer_Tiles nTiles
	.proc .ident(.sprintf("Tranfer%iTiles", nTiles))
.A16
.I16
		.repeat nTiles, i
			LDA	a:0 + MetaSprite__DmaTable::address + i * 3, Y
			STA	z:<A1T0 + i * 16
		.endrepeat

		LDA	#64
		.repeat nTiles, i
			STA	z:<DAS0 + i * 16
		.endrepeat

		SEP	#$20
.A8
		.repeat nTiles, i
			LDA	a:0 + MetaSprite__DmaTable::address + i * 3 + 2, Y
			STA	z:<A1B0 + i * 16
		.endrepeat

		LDA	#(1 << (nTiles)) - 1
		STA	f:MDMAEN


		; Bottom half of tiles

		.if nTiles <> 8
			; Calculate address of second half of row
			; not needed when loading 8 tiles
			REP	#$30
.A16
			LDA	f:dma_vramAddress
			; Rows are always even aligned, thus this works
			ORA	#16 * 16
			STA	f:VMADD
.A8
			SEP	#$20
		.endif

		; DASxH is always 0 after a transfer
		; Addresses are already set correctly

		LDA	#64
		.repeat nTiles, i
			STA	z:<DAS0L + i * 16
		.endrepeat

		LDA	#(1 << (nTiles)) - 1
		STA	f:MDMAEN

		JMP	ReturnFromTranfer
	.endproc
.endmacro


.rodata
TransferTable:
	.repeat 8, t
		.addr .ident(.sprintf("Tranfer%iTiles", t + 1))
	.endrepeat

.code

.repeat 8, t
	_Transfer_Tiles t + 1
.endrepeat

.endroutine

