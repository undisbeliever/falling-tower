
.include "camera.h"
.include "common/synthetic.inc"
.include "common/registers.inc"
.include "common/structure.inc"

.include "entity.h"
.include "entities/player.h"
.include "entities/platform.h"

.module Camera

CONFIG CAMERA_TOP_MARGIN, 64
CONFIG STARTING_PLATFORM_SPACING, 20


.segment "WRAM7E"
	xPos:		.res 2
	yPos:		.res 2


	; The next yPos in which a platform spawns
	nextPlatformSpawnYpos:	.res	2


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

	LDA	#Camera::STARTING_YOFFSET + PlatformEntity::FIRST_START_Y - STARTING_PLATFORM_SPACING
	STA	nextPlatformSpawnYpos

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine ProcessFrame
	; Check to see if another platform needs spawning in the spawn window
	LDA	yPos
	SBC	#STARTING_PLATFORM_SPACING
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
	ENDIF

	RTS
.endroutine



; Spawns the next platform
; Sets nextPlatformSpawnYpos to the appropriate value
; DP = $7E
.A16
.I16
.routine SpawnNextPlatform
	; ::TODO random platform types::
	LDA	#.loword(PlatformEntity)
	LDY	nextPlatformSpawnYpos

	JSR	Entity::NewPlatformEntity

	; Generate next placement
	; ::TODO randomize::
	; ::TODO make spacing wider::
	LDA	nextPlatformSpawnYpos
	SEC
	SBC	#STARTING_PLATFORM_SPACING
	STA	nextPlatformSpawnYpos

	RTS
.endroutine

.endmodule

