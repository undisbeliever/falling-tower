
.include "camera.h"
.include "common/synthetic.inc"
.include "common/registers.inc"
.include "common/structure.inc"

.include "entity.h"
.include "entities/player.h"
.include "entities/platform.h"

.module Camera

CONFIG CAMERA_TOP_MARGIN, 64


.segment "WRAM7E"
	xPos:		.res 2
	yPos:		.res 2


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

	.repeat 10, i
		LDA	#.loword(PlatformEntity)
		LDY	#i * 20 + Camera::STARTING_YOFFSET
		JSR	Entity::NewPlatformEntity
	.endrepeat

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine ProcessFrame

	LDA	Entity::player + PlayerEntityStruct::yPos + 1
	SEC
	SBC	#CAMERA_TOP_MARGIN

	CMP	yPos
	IF_LT
		STA	yPos
	ENDIF

	RTS
.endroutine

.endmodule

