
.include "platforms.h"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "camera.h"
.include "entity.h"
.include "random.h"
.include "entity-physics.h"

.include "resources/metasprites.h"

.setcpu "65816"

.module PlatformEntities

HUGE_WIDTH	= PlatformEntities::HUGE_WIDTH
LARGE_WIDTH	= PlatformEntities::LARGE_WIDTH
MEDIUM_WIDTH	= PlatformEntities::MEDIUM_WIDTH
SMALL_WIDTH	= PlatformEntities::SMALL_WIDTH

FIRST_START_X	= PlatformEntities::FIRST_START_X
FIRST_START_Y	= PlatformEntities::FIRST_START_Y

.rodata

.proc HugePlatformEntity
	.addr	Init_Huge
	.addr	ProcessFrame
	.addr	EntityTouchPlatform
	.addr	EntityLeavePlatform
.endproc
.exportlabel HugePlatformEntity

.proc LargePlatformEntity
	.addr	Init_Large
	.addr	ProcessFrame
	.addr	EntityTouchPlatform
	.addr	EntityLeavePlatform
.endproc
.exportlabel LargePlatformEntity

.proc MediumPlatformEntity
	.addr	Init_Medium
	.addr	ProcessFrame
	.addr	EntityTouchPlatform
	.addr	EntityLeavePlatform
.endproc
.exportlabel MediumPlatformEntity

.proc SmallPlatformEntity
	.addr	Init_Small
	.addr	ProcessFrame
	.addr	EntityTouchPlatform
	.addr	EntityLeavePlatform
.endproc
.exportlabel SmallPlatformEntity

.proc FirstPlatformEntity
	.addr	FirstInit
	.addr	ProcessFrame
	.addr	EntityTouchPlatform
	.addr	EntityLeavePlatform
.endproc
.exportlabel FirstPlatformEntity


.define PES PlatformEntityStruct


.code

; DP = player
; DB = $7E
; IN: Y = yPos
.A16
.I16
.routine Init_Huge
	LDA	#HUGE_WIDTH
	LDX	#MetaSprites::Platforms::Frames::platform_huge

	BRA	_Init
.endroutine

; DP = player
; DB = $7E
; IN: Y = yPos
.A16
.I16
.routine Init_Large
	LDA	#LARGE_WIDTH
	LDX	#MetaSprites::Platforms::Frames::platform_large

	BRA	_Init
.endroutine

; DP = player
; DB = $7E
; IN: Y = yPos
.A16
.I16
.routine Init_Medium
	LDA	#MEDIUM_WIDTH
	LDX	#MetaSprites::Platforms::Frames::platform_medium

	BRA	_Init
.endroutine

; DP = player
; DB = $7E
; IN: Y = yPos
.A16
.I16
.routine Init_Small
	LDA	#SMALL_WIDTH
	LDX	#MetaSprites::Platforms::Frames::platform_small

	.assert * = _Init, error, "Bad flow"
.endroutine


; DP = player
; DB = $7E
; IN: Y = yPos
; IN: A = platform width
; IN: X = frame Id
.A16
.I16
.routine _Init

	PHX

	; Given yPos
	STZ	z:PES::yPos
	STY	z:PES::yPos + 1

	; Random X pos
	RSB	#256
	JSR	Random::Rnd_U16A

	CLC
	ADC	Camera::xPos

	STZ	z:PES::xPos
	STA	z:PES::xPos + 1

	STZ	z:PES::xVecl
	STZ	z:PES::yVecl

	; Reset platform state
	STZ	z:PES::standingOnPlatform

	LDA	#MetaSprites::Platforms::frameSetId
	LDY	#0
	JSR	MetaSprite::Init

	PLA
	JSR	MetaSprite::SetFrame

	RTS
.endroutine

; DP = player
; DB = $7E
.A16
.I16
.routine FirstInit
	LDA	#FIRST_START_X + Camera::STARTING_XOFFSET
	STZ	z:PES::xPos
	STA	z:PES::xPos + 1

	LDA	#FIRST_START_Y + Camera::STARTING_YOFFSET
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
	LDA	z:PES::yPos + 1
	SEC
	SBC	#Camera::WINDOW_HEIGHT
	CMP	Camera::yPos
	IF_GE
		; Player off-screen - kill it
		CLC
		RTS
	ENDIF

	JMP	EntityPhysics::ProcessEntityPhyicsWithoutGravity
.endroutine


; DP = platform
; DB = $7E
;  Y = address of entity that touched platform
;  A = tileCollisionHitbox address
.A16
.I16
.routine EntityTouchPlatform
	; Entity is only on platform IF:
	;	- the tch bottom is above the platform's yPos line
	;	- the player is falling

	TAX

	LDA	a:EntityStruct::yVecl, Y
	IF_PLUS
		; Test to make sure that the entity was above the platform
		; before physics processing before placing it on the platform

		LDA	Entity::previousYpos
		SEC
		SBC	z:EntityStruct::yPos + 1
		CLC
		ADC	Entity::tch_top
		CLC
		ADC	Entity::tch_height

		CMP	z:PES::yPos + 1
		IF_LT
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

