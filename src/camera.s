
.include "camera.h"
.include "common/synthetic.inc"
.include "common/registers.inc"
.include "common/structure.inc"

.include "entity.h"
.include "gameloop.h"
.include "random.h"
.include "entities/player.h"
.include "entities/platforms.h"

.module Camera

CONFIG CAMERA_TOP_MARGIN, 64
CONFIG MIN_PLATFORM_SPACING, 10
CONFIG MAX_PLATFORM_SPACING, 60

CONFIG JUMP_DIFFICULT_THRESHOLD, 200

CONFIG SCROLL_SPEED_START,	$00700
CONFIG SCROLL_SPEED_DELTA,	$00007


WRAP_DROP_HEIGHT = $1000
WRAP_Y_POSITION  = Camera::STARTING_YOFFSET - WRAP_DROP_HEIGHT


.segment "WRAM7E"
	xPos:			.res 2
	yPos:			.res 2

	;; Fractional part of yPos
	yPosFractional:		.res 2

	;; A slowly incrementing velocity of the camera (auto-scroll)
	yVelocity:		.res 4

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
	STZ	yPosFractional

	LDA	#.loword(SCROLL_SPEED_START)
	STA	yVelocity
	LDA	#.hiword(SCROLL_SPEED_START)
	STA	yVelocity + 2

	; Create the initial platforms
	LDA	#.loword(PlatformEntities::FirstPlatformEntity)
	JSR	Entity::NewPlatformEntity

	STY	previousPlatform


	LDA	#Camera::STARTING_YOFFSET + PlatformEntities::FIRST_START_Y - (MAX_PLATFORM_SPACING / 2)
	STA	nextPlatformSpawnYpos

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine ProcessFrame

tmp_prevYpos	= tmp1

	; Wrap camera (and all entities) if necessary
	LDA	yPos
	CMP	#WRAP_Y_POSITION
	IF_LT
		JSR	WrapCamera
	ENDIF

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
	ELSE
		; Else, autoscroll
		;
		; yVelocity += SCROLL_SPEED_DELTA
		; yPos:yPosFractional -= yVelocity

		LDA	#.loword(SCROLL_SPEED_DELTA)
		CLC
		ADC	yVelocity
		STA	yVelocity
		IF_C_SET
			INC	yVelocity + 2
		ENDIF

		SEC
		LDA	yPosFractional
		SBC	yVelocity
		STA	yPosFractional

		LDA	yPos
		SBC	yVelocity + 2
		STA	yPos
	ENDIF

	; increase score by how much the frame moved
	; A = yPos
	RSB	tmp_prevYpos

	CLC
	ADC	GameLoop::score
	STA	GameLoop::score
	IF_C_SET
		INC	GameLoop::score + 2
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

	; Select and spawn random platform
	LDA	#PlatformSelectionTable_count
	JSR	Random::Rnd_U16A
	ASL
	TAX

	LDA	f:PlatformSelectionTable, X
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

		LDA	#.loword(PlatformEntities::SmallPlatformEntity)

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


; Moves all of the entities down WRAP_DROP_HEIGHT pixels
; Prevents overflow bug
.A16
.I16
.routine WrapCamera
	LDA	Entity::player + EntityStruct::yPos + 1
	CLC
	ADC	#WRAP_DROP_HEIGHT
	STA	Entity::player + EntityStruct::yPos + 1

	LDA	Entity::platformEntityLList
	IF_NOT_ZERO
		REPEAT
			TCD

			LDA	z:EntityStruct::yPos + 1
			CLC
			ADC	#WRAP_DROP_HEIGHT
			STA	z:EntityStruct::yPos + 1

			LDA	z:EntityStruct::nextPtr
		UNTIL_ZERO
	ENDIF

	LDA	nextPlatformSpawnYpos
	CLC
	ADC	#WRAP_DROP_HEIGHT
	STA	nextPlatformSpawnYpos

	LDA	yPos
	CLC
	ADC	#WRAP_DROP_HEIGHT
	STA	yPos

	RTS
.endroutine


.segment "BANK1"

PlatformSelectionTable:
	.addr	PlatformEntities::HugePlatformEntity
	.addr	PlatformEntities::LargePlatformEntity
	.addr	PlatformEntities::MediumPlatformEntity
	.addr	PlatformEntities::SmallPlatformEntity

PlatformSelectionTable_count = (* - PlatformSelectionTable) / 2

.endmodule

