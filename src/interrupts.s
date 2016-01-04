
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "common/console.h"
.include "metasprite/metasprite.h"

.include "vram.h"
.include "gameloop.h"

.setcpu "65816"

.segment "SHADOW"
	frameCounter:	.res 2

.export frameCounter

.code


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
	LDA	#$4300
	TCD

	; Reset NMI Flag.
	LDY	RDNMI

	; Copy console buffer to BG
	LDX	#VMAIN_INCREMENT_HIGH | VMAIN_INCREMENT_1
	STX	a:VMAIN

	.assert VRAM::ConsoleMap = 0, error, "Bad Code"
	STZ	VMADD

	LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_2REGS | (.lobyte(VMDATA) << 8)
	STA	z:<DMAP0		; also sets BBAD0

	LDY	#.bankbyte(Console::buffer)
	STY	z:<A1B0

	LDA	#.loword(Console::buffer)
	STA	z:<A1T0

	LDA	#Console::buffer_size
	STA	z:<DAS0

	LDY	#MDMAEN_DMA0
	STY	MDMAEN


	JSR	MetaSprite::VBlank


	INC	frameCounter

	; Ensure Joypad can be read
	LDA	#HVJOY_AUTOJOY
	REPEAT
		BIT	HVJOY
	UNTIL_ZERO


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

; vim: set ft=asm:

