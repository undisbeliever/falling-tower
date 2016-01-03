
.include "camera.h"
.include "common/synthetic.inc"
.include "common/registers.inc"
.include "common/structure.inc"

.include "entity.h"
.include "gameloop.h"
.include "random.h"
.include "entities/player.h"
.include "entities/platform.h"

.module Camera

CONFIG CAMERA_TOP_MARGIN, 64
CONFIG MIN_PLATFORM_SPACING, 10
CONFIG MAX_PLATFORM_SPACING, 60

CONFIG JUMP_DIFFICULT_THRESHOLD, 200


.segment "WRAM7E"
	xPos:			.res 2
	yPos:			.res 2

	; The next yPos in which a platform spawns
	nextPlatformSpawnYpos:	.res 2
	previousPlatform:	.res 2

	tmp1:			.res 2
	tmp2:			.res 2


.exportlabel xPos
.exportlabel yPos

.code


; DB = $7E
.A16
.I16
.routine Init
	LDA	#Camera::STARTING_XOFFSET
	STA	xPos

	LDA	#Camera::STARTING_YOFFSET
	STA	yPos

	; Create the initial platforms
	LDA	#.loword(FirstPlatformEntity)
	JSR	Entity::NewPlatformEntity

	STY	previousPlatform


	LDA	#Camera::STARTING_YOFFSET + PlatformEntity::FIRST_START_Y - (MAX_PLATFORM_SPACING / 2)
	STA	nextPlatformSpawnYpos

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine ProcessFrame

tmp_prevYpos	= tmp1

	; Check to see if another platform needs spawning in the spawn window
	LDA	yPos
	STA	tmp_prevYpos

	SBC	#MAX_PLATFORM_SPACING
	CMP	nextPlatformSpawnYpos
	IF_LT
		JSR	SpawnNextPlatform
	ENDIF

	; Move the window if necessary
	LDA	Entity::player + PlayerEntityStruct::yPos + 1
	SEC
	SBC	#CAMERA_TOP_MARGIN

	CMP	yPos
	IF_LT
		STA	yPos

		; increase score by how much the frame moved
		RSB	tmp_prevYpos

		CLC
		ADC	GameLoop::score
		STA	GameLoop::score
		IF_C_SET
			INC	GameLoop::score + 2
		ENDIF
	ENDIF

	RTS
.endroutine



; Spawns the next platform
; Sets nextPlatformSpawnYpos to the appropriate value
; DP = $7E
.A16
.I16
.routine SpawnNextPlatform

tmp_distance = tmp2

	; ::TODO random platform types::
	LDA	#.loword(PlatformEntity)
	LDY	nextPlatformSpawnYpos

	JSR	Entity::NewPlatformEntity


	; If the Manhattan distance between the two is too far,
	; spawn another platform on the same y pos
	LDX	previousPlatform
	LDA	a:EntityStruct::xPos + 1, X
	SEC
	SBC	a:EntityStruct::xPos + 1, Y
	IF_MINUS
		NEG
	ENDIF
	STA	tmp_distance

	LDA	a:EntityStruct::yPos + 1, X
	SEC
	SBC	a:EntityStruct::yPos + 1, Y
	CLC
	ADC	tmp_distance

	CMP	#JUMP_DIFFICULT_THRESHOLD
	IF_GE
		; Place 'helper' platform just below the one that is too far away

		LDA	nextPlatformSpawnYpos
		; C set
		ADC	#MIN_PLATFORM_SPACING - 1
		TAY

		LDA	#.loword(PlatformEntity)

		JSR	Entity::NewPlatformEntity
	ENDIF
	STY	previousPlatform


	; Generate next placement
	; Randomize location

	LDA	#MAX_PLATFORM_SPACING - MIN_PLATFORM_SPACING
	JSR	Random::Rnd_U16A
	CLC
	ADC	#MIN_PLATFORM_SPACING

	RSB	nextPlatformSpawnYpos
	STA	nextPlatformSpawnYpos

	RTS
.endroutine

.endmodule

