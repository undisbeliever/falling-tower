
.include "player.h"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "entity.h"
.include "entity-physics.h"
.include "entities/platforms.h"

.include "controller.h"
.include "camera.h"
.include "resources/metasprites.h"

CONFIG	JUMP_VELOCITY,	$0300
CONFIG	PLAYER_Y_BOTTOM_OFFSET,	15
CONFIG	WALK_ANIMATION_SHIFT, 2
CONFIG	N_WALK_ANIMATION_FRAMES, 6

.setcpu "65816"

.module PlayerEntity

START_X = 256 / 2

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
	LDA	#START_X + Camera::STARTING_XOFFSET
	STZ	z:PES::xPos
	STA	z:PES::xPos + 1

	LDA	#PlatformEntities::FIRST_START_Y + Camera::STARTING_YOFFSET - PLAYER_Y_BOTTOM_OFFSET
	STZ	z:PES::yPos
	STA	z:PES::yPos + 1

	STZ	z:PES::xVecl
	STZ	z:PES::yVecl

	; Reset animation state
	STZ	z:PES::walkAnimationFrame
	STZ	z:PES::facingLeftOnZero

	; Reset platform state
	STZ	z:PES::standingOnPlatform

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
	LDA	z:PES::yPos + 1
	SEC
	SBC	#Camera::WINDOW_HEIGHT
	CMP	Camera::yPos
	IF_GE
		; Player offscreen - now dead
		CLC
		RTS
	ENDIF

	LDA	z:PES::standingOnPlatform
	IF_NOT_ZERO
		; Jump only if standing on a platform
		LDA	Controller::pressed
		IF_BIT	#JOY_B | JOY_A
			LDA	#.loword(-JUMP_VELOCITY)
			STA	z:PES::yVecl
		ENDIF
	ENDIF

	LDA	Controller::current
	JSR	EntityPhysics::ProcessEntityPhyicsWithMovement


	; Process animation
	LDA	Controller::current
	IF_BIT	#JOY_LEFT | JOY_RIGHT
		IF_BIT	#JOY_LEFT
			STZ	z:PES::facingLeftOnZero

		ELSE
			; facing sight
			STA	z:PES::facingLeftOnZero
		ENDIF
	ENDIF

	LDA	z:PES::standingOnPlatform
	IF_ZERO
		; Jumping or falling
		LDA	z:PES::yVecl
		IF_MINUS
			; Jumping
			LDA	#MetaSprites::Player::Frames::jump_right
		ELSE
			; Falling
			LDA	#MetaSprites::Player::Frames::fall_right
		ENDIF

	ELSE
		; On a platform

		LDABS	z:PES::xVecl
		IF_NOT_ZERO

			; Walking

			CLC
			ADC	z:PES::walkAnimationFrame

			CMP	#(N_WALK_ANIMATION_FRAMES << 8) << WALK_ANIMATION_SHIFT
			IF_GE
				; C set
				LDA	#0
			ENDIF

			STA	z:PES::walkAnimationFrame

			.repeat WALK_ANIMATION_SHIFT
				LSR
			.endrepeat
			XBA
			AND	#$00FF
			CLC
			ADC	#MetaSprites::Player::Frames::walk0_right
		ELSE

			; Standing still
			LDA	#MetaSprites::Player::Frames::stand_right
		ENDIF
	ENDIF

	LDX	z:PES::facingLeftOnZero
	IF_ZERO
		CLC
		ADC	#MetaSprites::Player::leftOffset
	ENDIF

	JSR	MetaSprite::SetFrame

	SEC
	RTS
.endroutine

.endmodule

; vim: set ft=asm:

