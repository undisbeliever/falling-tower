
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
	.addr	EntityTouchPlatform
	.addr	EntityLeavePlatform
.endproc
.export PlatformEntity

.proc FirstPlatformEntity
	.addr	FirstInit
	.addr	ProcessFrame
	.addr	EntityTouchPlatform
	.addr	EntityLeavePlatform
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

	STZ	z:PES::xVecl
	STZ	z:PES::yVecl

	; Reset platform state
	STZ	z:PES::standingOnPlatform

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


; DP = platform
; DB = $7E
;  A = address of entity that touched platform
;  Y = tileCollisionHitbox address
.A16
.I16
.routine EntityTouchPlatform
	; Entity is only on platform IF:
	;	- the tch bottom is above the platform's yPos line
	;	- the player is falling

	TYX
	TAY

	LDA	a:EntityStruct::yVecl, Y
	IF_PLUS
		LDA	Entity::tch_top
		CLC
		ADC	Entity::tch_height

		CMP	z:PES::yPos + 1
		IF_GE
			LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::yOffset, X
			AND	#$00FF
			SEC
			SBC	#MetaSprite::POSITION_OFFSET
			CLC
			ADC	z:PES::yPos + 1

			SEC
			SBC	Entity::tch_height
			SEC
			SBC	Entity::tch_yOffset

			STA	a:EntityStruct::yPos + 1, Y


			LDA	#0
			STA	a:EntityStruct::yVecl, Y


			SEP	#$20
.A8
			LDA	z:EntityStruct::yPos
			STA	a:EntityStruct::yPos, Y

			REP	#$20
.A16

			TDC
			STA	a:EntityStruct::standingOnPlatform, Y
		ENDIF
	ENDIF

	RTS
.endroutine



; DP = platform
; DB = $7E
;  Y = address of entity that was previously on the platform
.routine EntityLeavePlatform
	TYX
	STZ	a:EntityStruct::standingOnPlatform, X

	RTS
.endroutine

.endmodule

.segment METASPRITE_TILE_COLLISION_HITBOXES_BLOCK
	tileCollisionDataOffset = .bankbyte(*) << 16

; vim: set ft=asm:

