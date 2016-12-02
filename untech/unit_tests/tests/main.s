; Unit tests

.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "common/console.h"
.include "common/ppu.h"

.include "font.h"

.import RunTests

.setcpu "65816"

.scope VRAM
	BG1_MAP   = $0000
	BG1_TILES = $1000
	BG1_SIZE  = BGXSC_SIZE_32X32

	SCREEN_MODE = 0
.endscope



.code


.macro SetupScreen
	.assert .asize = 8, error, "Bad .asize"
	.assert .isize = 16, error, "Bad .isize"

	STZ	NMITIMEN

	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#VRAM::SCREEN_MODE
	STA	BGMODE

	SetVramBaseAndSize VRAM

	; Load tiles and palettes

	LDX	#VRAM::BG1_TILES
	STX	VMADD

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	LDA	#.bankbyte(Font::Tiles)
	STA	A1B0

	LDX	#.loword(Font::Tiles)
	STX	A1T0

	LDX	#Font::Tiles_size
	STX	DAS0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN


	; Load palette
	STZ	CGADD

	LDX	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_WRITE_TWICE | (.lobyte(CGDATA) << 8)
	STX	DMAP0			; also sets BBAD0

	LDA	#.bankbyte(Font::Palettes)
	STA	A1B0

	LDX	#.loword(Font::Palettes)
	STX	A1T0

	LDX	#Font::Palettes_size
	STX	DAS0

	LDA	#MDMAEN_DMA0
	STA	MDMAEN



	LDA	#TM_BG1
	STA	TM

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	LDA	#$0F
	STA	INIDISP
.endmacro



.routine VBlank
	; Save state
	REP #$30
	PHA
	PHB
	PHD
	PHX
	PHY

	.assert .bankbyte(*) & $7F < $30, error, "bad DB"
	PHK
	PLB

	REP	#$30
	SEP	#$10
.A16
.I8
	; Reset NMI Flag.
	LDY	RDNMI

	; Copy console buffer to BG

	.assert VRAM::BG1_MAP = 0, error, "Bad Code"
	STZ	VMADD

	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
	STA	DMAP0			; also sets BBAD0

	LDY	#.bankbyte(Console::buffer)
	STY	A1B0

	LDA	#.loword(Console::buffer)
	STA	A1T0

	LDA	#Console::buffer_size
	STA	DAS0

	LDY	#MDMAEN_DMA0
	STY	MDMAEN

	; Load State
	REP	#$30
	PLY
	PLX
	PLD
	PLB
	PLA

	RTI
.endroutine

.routine BreakHandler
	RTI
.endroutine

.routine CopHandler
	RTI
.endroutine

.routine IrqHandler
	RTI
.endroutine



.routine Main
	REP	#$30
	SEP	#$20
.A8
.I16
	SetupScreen

	REPEAT
		JSR	RunTests

		; Wait 1 second
		LDA	#FPS
		REPEAT
			WAI
			DEC
		UNTIL_ZERO
	FOREVER
.endroutine


; vim: set ft=asm:

