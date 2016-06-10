
.include "common/config.inc"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"

.setcpu "65816"

.import Main
.import __STACK_TOP
.export ResetHandler


CONFIG RESET_DB, $80
.assert (RESET_DB & $7E) < $3F, error, "RESET_DB must access registers"


.module Reset

;; Memory location contains a zero word.
;; From SNES Header (which has 7 consecutive zero bytes)
zeroWord = $00FFB6


.code


::ResetHandler:
.routine ResetSNES
	SEI
	CLC
	XCE				; Switch to native mode

	REP	#$38			; 16 bit A, 16 bit Index, Decimal mode off

.I16
	LDX	#__STACK_TOP
	TXS				; Setup stack (top of Shadow RAM)

	LDA	#$0000
	TCD				; Setup Direct Page = $0000

	SEP	#$20
.A8

	; Set Data Bank

	LDA	#RESET_DB
	PHA
	PLB

	; Clear the WRAM
	; Setup DMA Channel 0 for WRAM
	LDX	#0
	STX	WMADDL
	STZ	WMADDH

	LDY	#DMAP_DIRECTION_TO_PPU | DMAP_ADDRESS_FIXED | DMAP_TRANSFER_1REG | (.lobyte(WMDATA) << 8)
	STY	DMAP0			; also sets BBAD0

	; X = 0
	STX	DAS0

	.assert .bankbyte(zeroWord) = 0, error, "Bad zeroWord"
	LDX	#zeroWord
	STX	A1T0
	STZ	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	; DSA0 is 0, no need to set it again
	STA	MDMAEN


	JSR	ClearVRAM
	JSR	ClearOAM
	JSR	ClearCGRAM
	JSR	ResetRegisters
	JML	Main
.endroutine


.routine ResetRegisters
	PHP
	PHD

	REP	#$30
.A16
	LDA	#$2100
	TCD

	SEP	#$30
.A8
.I8

	; Disable All interrupts
	; Prevent interruptions
	STZ	<NMITIMEN

	; Disable HDMA
	STZ	<HDMAEN

	LDA	#INIDISP_FORCE
	STA	<INIDISP		; Force Screen Blank

	STZ	<OBSEL

	; Registers $2105 - $210C
	; BG settings and VRAM base addresses
	LDX	#$210C - $2105
	REPEAT
		STZ	$05, X
		DEX
	UNTIL_MINUS

	; Registers $210D - $2114
	; BG Scroll Locations - Write twice
	LDX	#$2114 - $210D
	REPEAT
		STZ	$0D, X
		STZ	$0D, X
		DEX
	UNTIL_MINUS

	; Skipping Mode 7 as any programmer using that mode
	; will set those registers anyway.

	; Increment VRAM by 1 word on reading/writing the high byte of VRAM
	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	<VMAIN

	; Registers $2123 - $2133
	; Window Settings, BG/OBJ designation, Color Math, Screen Mode
	; All disabled
	LDX	#$2133 - $2123
	REPEAT
		STZ	$23, X
		DEX
	UNTIL_MINUS

	; ROM access time to slow
	STZ	<MEMSEL

	PLD
	PLP
	RTS
.endroutine



; ROUTINE Transfers 0x10000 0 bytes to VRAM
.A8
.I16
.routine ClearVRAM
	LDA	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STA	VMAIN

	LDX	#0
	STX	VMADD

	LDY	#DMAP_DIRECTION_TO_PPU | DMAP_ADDRESS_FIXED | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
	STY	DMAP0			; also sets BBAD0

	; X = 0
	STX	DAS0

	.assert .bankbyte(zeroWord) = 0, error, "Bad zeroWord"
	LDX	#zeroWord
	STX	A1T0
	STZ	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS
.endroutine



.A8
.I16
.routine ClearCGRAM
	STZ	CGADD

	LDY	#DMAP_DIRECTION_TO_PPU | DMAP_ADDRESS_FIXED | DMAP_TRANSFER_1REG | (.lobyte(CGDATA) << 8)
	STY	DMAP0			; also sets BBAD0

	LDX	#256 * 2
	STX	DAS0

	.assert .bankbyte(zeroWord) = 0, error, "Bad zeroWord"
	LDX	#zeroWord
	STX	A1T0
	STZ	A1B0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN

	RTS
.endroutine


.routine ClearOAM
	PHP
	PHD

	REP	#$30
.A16
	LDA	#$2100
	TCD

	SEP	#$30
.A8
.I8
	STZ	<OAMADDL
	STZ	<OAMADDH

	LDX	#$80
	LDY	#240

	LDA	#128
	REPEAT
		STX	<OAMDATA	; X
		STY	<OAMDATA	; Y
		STZ	<OAMDATA
		STZ	<OAMDATA	; Character + Flags

		DEC
	UNTIL_ZERO

	LDA	#%01010101
	LDX	#128
	REPEAT
		STA	<OAMDATA	; Data table
		DEX
	UNTIL_ZERO

	PLD
	PLP
	RTS
.endroutine

.endmodule

