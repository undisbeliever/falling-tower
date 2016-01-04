
.include "gameloop.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "common/incdec.inc"

.include "common/console.h"
.include "common/ppu.h"

.include "camera.h"
.include "controller.h"
.include "entity.h"
.include "random.h"
.include "vram.h"

.include "resources/font.h"


.setcpu "65816"

.module GameLoop

.segment "SHADOW"
	state:		.res 2

.segment "WRAM7E"
	score:		.res 4

	; Address of the console cursor
	scoreCursor:	.res 2


.exportlabel state
.exportlabel score

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

	; Load font tiles and palettes
	LDX	#VRAM::ConsoleTiles
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


	LDA	#TM_BG3 | TM_OBJ
	STA	TM

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	LDA	#$0F
	STA	INIDISP
.endmacro


; DB = $80
.A8
.I16
.routine PlayGame

	SetupScreen

	JSR	Console::Init

	; Have text in front of everything else
	LDA	#TILEMAP_ORDER_FLAG >> 8
	TSB	Console::tilemapOffset + 1


	PEA	$807E
	PLB			; $7E

	REP	#$30
.A16

	LDX	Console::cursor
	STX	scoreCursor

	STZ	score
	STZ	score + 2

	JSR	Entity::Init

	JSR	Camera::Init


	REPEAT
Continue:
	STZ	state
		REPEAT
			JSR	WaitFrame

			JSR	Random::AddJoypadEntropy

			; Print score
			LDA	#0
			TCD

			SEP	#$20
.A8
			LDX	scoreCursor
			STX	Console::cursor

			LDXY	score
			JSR	Console::PrintInt_U32XY

			REP	#$30
.A16

			; Process frame

			JSR	Entity::ProcessFrame
			JSR	Camera::ProcessFrame
			JSR	Entity::RenderFrame

			; Handle pausing the game
			LDA	Controller::pressed
			IF_BIT	#JOY_START
				LDX	#GameState::PAUSED
				STX	state
			ENDIF

			LDX	state
			.assert GameState::PLAYING = 0, error, "Bad Code"
		UNTIL_NOT_ZERO

		JMP	(.loword(GameStateTable), X)
	FOREVER

End:

	PLB			; $80
	SEP	#$20
.A8
	RTS
.endroutine


;; These functions are called when the game state changes
;; They will jump to either `PlayGame::Continue` or `PlayGame::End` upon completion.
.rodata
.proc GameStateTable
	.addr	PlayGame::Continue	; PLAYING
	.addr	GameOver		; GAME_OVER
	.addr	Paused			; PAUSED
.endproc

.code


;; Pause the game until start is pressed
.A16
.I16
.routine Paused
	SEP	#$20
.A8
	JSR	Console::NewLine
	CPrintString	"PAUSED"

	REP	#$30
.A16

	; Loop until start pressed
	REPEAT
		JSR	WaitFrame

		LDA	Controller::pressed
		AND	#JOY_START
	UNTIL_NOT_ZERO

	JSR	Console::Clear

	JMP	PlayGame::Continue
.endroutine


;; Show game over message
.A16
.I16
.routine GameOver
	SEP	#$20
.A8
	JSR	Console::NewLine
	CPrintString	"GAME OVER - PRESS START"

	REP	#$30
.A16

	; Loop until start pressed
	REPEAT
		JSR	WaitFrame

		LDA	Controller::pressed
		AND	#JOY_START
	UNTIL_NOT_ZERO

	JMP	PlayGame::End
.endroutine


.A16
.I16
.routine WaitFrame
	; Some game copiers inject IRQ, so I have to test if it was a VBlank interrupt

.import frameCounter
	LDA	frameCounter
	REPEAT
		WAI
		CMP	frameCounter
	UNTIL_NE

	JMP	Controller::Update
.endroutine

.endmodule

; vim: set ft=asm:

