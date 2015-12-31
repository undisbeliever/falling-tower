
.include "entity.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

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

	; MUST NOT USE Y UNTIL AFTER INIT CALL

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
	LDA	#.loword(player)
	TCD

	LDX	z:EntityStruct::functionPtr
	JSR	(EntityFunctions::ProcessFrame, X)


	LDA	platformEntityLList
	IF_NOT_ZERO
		REPEAT
			TCD

			LDX	z:EntityStruct::functionPtr
			JSR	(EntityFunctions::ProcessFrame, X)

			LDA	z:EntityStruct::nextPtr
		UNTIL_ZERO
	ENDIF

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
	STA	MetaSprite::xPos

	LDA	z:EntityStruct::yPos + 1
	SEC
	SBC	#MetaSprite::POSITION_OFFSET
	STA	MetaSprite::yPos

	JSR	MetaSprite::RenderFrame


	LDA	platformEntityLList
	IF_NOT_ZERO
		REPEAT
			TCD

			LDA	z:EntityStruct::xPos + 1
			SEC
			SBC	#MetaSprite::POSITION_OFFSET
			STA	MetaSprite::xPos

			LDA	z:EntityStruct::yPos + 1
			SEC
			SBC	#MetaSprite::POSITION_OFFSET
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

