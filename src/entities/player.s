
.include "player.h"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "entity.h"
.include "entity-physics.h"

.include "resources/metasprites.h"

.setcpu "65816"

.module PlayerEntity

.rodata

.proc PlayerEntity
	.addr	Init
	.addr	ProcessFrame
.endproc
.export PlayerEntity


.define PES PlayerEntityStruct

.code

; DP = player
; DB = $7E
.A16
.I16
.routine Init
	; ::DEBUG example starting location::
	LDA	#120
	STZ	z:PES::xPos
	STA	z:PES::xPos + 1

	LDA	#8
	STZ	z:PES::yPos
	STA	z:PES::yPos + 1

	STZ	z:PES::xVecl
	STZ	z:PES::yVecl

	LDA	#MetaSprites::Player::frameSetId
	LDY	#0
	JSR	MetaSprite::Init

	LDA	#MetaSprites::Player::Frames::stand_right
	JSR	MetaSprite::SetFrame

	RTS
.endroutine



; DP = player
; DB = $7E
.A16
.I16
.routine ProcessFrame
	JSR	EntityPhysics::ProcessEntityPhyicsWithGravity

	RTS
.endroutine

.endmodule

; vim: set ft=asm:

