
.include "platform.h"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "entity.h"
.include "random.h"
.include "entity-physics.h"

.include "resources/metasprites.h"

.setcpu "65816"

.module PlatformEntity

HUGE_WIDTH	= 48
LARGE_WIDTH	= 40
MEDIUM_WIDTH	= 32
SMALL_WIDTH	= 24

FIRST_START_X	= (256 - HUGE_WIDTH) / 2
FIRST_START_Y	= 200

.rodata

.proc PlatformEntity
	;; INPUT: Y: starting y location
	.addr	Init
	.addr	ProcessFrame
.endproc
.export PlatformEntity

.proc FirstPlatformEntity
	.addr	FirstInit
	.addr	ProcessFrame
.endproc
.export FirstPlatformEntity

.define PES PlatformEntityStruct

.code

; DP = player
; DB = $7E
; IN: Y = yPos
.A16
.I16
.routine Init
	; Given yPos
	STZ	z:PES::yPos
	STY	z:PES::yPos + 1

	; Random X pos
	LDA	#256 - HUGE_WIDTH
	JSR	Random::Rnd_U16A

	STZ	z:PES::xPos
	STA	z:PES::xPos + 1


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
.routine FirstInit
	LDA	#FIRST_START_X
	STZ	z:PES::xPos
	STA	z:PES::xPos + 1

	LDA	#FIRST_START_Y
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

