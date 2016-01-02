
.include "entity.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "camera.h"
.include "entity-collisions.asm"

.include "entities/platform.h"
.include "resources/metasprites.h"

.setcpu "65816"

MetaSpriteDpOffset = EntityStruct::metasprite

CONFIG N_ENTITIES, 12

.import PlayerEntity


.module Entity

.segment "SHADOW"
	player:			.res	ENTITY_STRUCT_SIZE

	entityPool:		.res	N_ENTITIES * ENTITY_STRUCT_SIZE


.segment "WRAM7E"
	firstFreeEntity:	.res	2

	platformEntityLList:	.res	2

	; Used for collision testing code
	collisionTmp1:		.res	2
	collisionTmp2:		.res	2

	previousYpos:		.res	2

	tch_xOffset:		.res	2
	tch_yOffset:		.res	2
	tch_left:		.res	2
	tch_top:		.res	2
	tch_width:		.res	2
	tch_height:		.res	2

.exportlabel previousYpos
.exportlabel tch_xOffset
.exportlabel tch_yOffset
.exportlabel tch_left
.exportlabel tch_top
.exportlabel tch_width
.exportlabel tch_height

.exportlabel player
.exportlabel platformEntityLList

.code


.macro EntityPool_Init
	.assert .asize = 16, error, "Bad asize"
	.assert .isize = 16, error, "Bad asize"

	LDA	#entityPool
	STA	firstFreeEntity
	REPEAT
		TCD

		STZ	z:EntityStruct::functionPtr
		ADD	#ENTITY_STRUCT_SIZE
		STA	z:EntityStruct::nextPtr

		CMP	#entityPool + (N_ENTITIES - 1) * ENTITY_STRUCT_SIZE
	UNTIL_GE

	; Last one terminates the list
	STZ	entityPool + (N_ENTITIES - 1) * ENTITY_STRUCT_SIZE

	STZ	platformEntityLList
.endmacro


; DB = $7E
; IN: A = functionTable
; IN: Y = value to pass to Init Function
; OUT: Z clear if successful, A & Y = entity address
; This macro will RTS
.macro _EntityPool_Create list
	.assert .asize = 16, error, "Bad asize"
	.assert .isize = 16, error, "Bad asize"

	; MUST NOT USE Y UNTIL BEFORE INIT CALL

	TAX

	LDA	firstFreeEntity
	IF_NOT_ZERO
		PHD

		TCD

		LDA	z:EntityStruct::nextPtr
		STA	firstFreeEntity

		LDA	list
		STA	z:EntityStruct::nextPtr

		TDC
		STA	list



		STX	z:EntityStruct::functionPtr
		JSR	(EntityFunctions::Init, X)

		JSR	MetaSprite::Activate


		TDC
		PLD

		TAY
		RTS
	ENDIF

	LDY	#0
	RTS
.endmacro


; DB = $7E
.A16
.I16
.routine Init
	JSR	MetaSprite::Reset

	PHD

	EntityPool_Init



	LDA	#.loword(player)
	TCD

	STZ	z:EntityStruct::nextPtr

	LDX	#.loword(PlayerEntity)
	STX	z:EntityStruct::functionPtr
	JSR	(EntityFunctions::Init, X)

	JSR	MetaSprite::Activate

	PLD

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine ProcessFrame
	; Process platforms first (in case they move)

	LDA	platformEntityLList
	IF_NOT_ZERO
		REPEAT
			TCD

			LDA	z:EntityStruct::yPos + 1
			STA	previousYpos

			LDX	z:EntityStruct::functionPtr
			JSR	(EntityFunctions::ProcessFrame, X)

			LDA	z:EntityStruct::nextPtr
		UNTIL_ZERO
	ENDIF

	; Process player

	LDA	#.loword(player)
	TCD

	LDA	z:EntityStruct::yPos + 1
	STA	previousYpos

	LDX	z:EntityStruct::functionPtr
	JSR	(EntityFunctions::ProcessFrame, X)


	CheckPlatformCollisions	PlatformEntityFunctions::EntityTouchPlatform, PlatformEntityFunctions::EntityLeavePlatform

	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine RenderFrame
	JSR	MetaSprite::RenderLoopInit

	LDA	#.loword(player)
	TCD

	LDA	z:EntityStruct::xPos + 1
	SEC
	SBC	#MetaSprite::POSITION_OFFSET
	SEC
	SBC	Camera::xPos
	STA	MetaSprite::xPos

	LDA	z:EntityStruct::yPos + 1
	SEC
	SBC	#MetaSprite::POSITION_OFFSET
	SEC
	SBC	Camera::yPos
	STA	MetaSprite::yPos

	JSR	MetaSprite::RenderFrame


	LDA	platformEntityLList
	IF_NOT_ZERO
		REPEAT
			TCD

			LDA	z:EntityStruct::xPos + 1
			SEC
			SBC	#MetaSprite::POSITION_OFFSET
			SEC
			SBC	Camera::xPos
			STA	MetaSprite::xPos

			LDA	z:EntityStruct::yPos + 1
			SEC
			SBC	#MetaSprite::POSITION_OFFSET
			SEC
			SBC	Camera::yPos
			STA	MetaSprite::yPos

			JSR	MetaSprite::RenderFrame

			LDA	z:EntityStruct::nextPtr
		UNTIL_ZERO
	ENDIF

	JSR	MetaSprite::RenderLoopEnd

	RTS
.endroutine


; DB = $7E
; IN: A = functionTable
; IN: Y = value to pass to Init Function
; OUT: Z clear if successful, A & Y = entity address
; This macro will RTS
.routine NewPlatformEntity
	_EntityPool_Create	platformEntityLList
.endroutine


.endmodule

; vim: set ft=asm:

