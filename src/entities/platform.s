
.include "platform.h"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "entity.h"
.include "entity-physics.h"

.include "resources/metasprites.h"

.setcpu "65816"

.module PlatformEntity

.rodata

.proc PlatformEntity
	.addr	Init
	.addr	ProcessFrame
.endproc
.export PlatformEntity


.define PES PlatformEntityStruct

.code

; DP = player
; DB = $7E
.A16
.I16
.routine Init
	; ::DEBUG example starting location::
	LDA	#96
	STZ	z:PES::xPos
	STA	z:PES::xPos + 1

	LDA	#200
	STZ	z:PES::yPos
	STA	z:PES::yPos + 1

	STZ	z:PES::xVecl
	STZ	z:PES::yVecl

	LDA	#MetaSprites::Platforms::frameSetId
	LDY	#0
	JSR	MetaSprite::Init

	LDA	#MetaSprites::Platforms::Frames::platform_huge

	JSR	MetaSprite::SetFrame

	RTS
.endroutine



; DP = player
; DB = $7E
.A16
.I16
.routine ProcessFrame
	JSR	EntityPhysics::ProcessEntityPhyicsWithoutGravity

	RTS
.endroutine

.endmodule

; vim: set ft=asm:

