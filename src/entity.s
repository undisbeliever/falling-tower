
.include "entity.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "resources/metasprites.h"

.setcpu "65816"

MetaSpriteDpOffset = EntityStruct::metasprite

.module Entity

.segment "SHADOW"
	player:		.res	ENTITY_STRUCT_SIZE
	platform:	.res	ENTITY_STRUCT_SIZE


.code

; DB = $7E
.A16
.I16
.routine Init
	JSR	MetaSprite::Reset

	PHD

	LDA	#.loword(player)
	TCD

	; ::TODO AddEntity Routine::
	.import PlayerEntity

	STZ	z:EntityStruct::nextPtr

	LDX	#.loword(PlayerEntity)
	STX	z:EntityStruct::functionPtr
	JSR	(EntityFunctions::Init, X)

	JSR	MetaSprite::Activate



	; ::TODO AddEntity Routine::

	LDA	#.loword(platform)
	TCD

	.import PlatformEntity

	STZ	z:EntityStruct::nextPtr

	LDX	#.loword(PlatformEntity)
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
	PHD

	LDA	#.loword(player)
	TCD

	LDX	z:EntityStruct::functionPtr
	JSR	(EntityFunctions::ProcessFrame, X)


	LDA	#.loword(platform)
	TCD

	LDX	z:EntityStruct::functionPtr
	JSR	(EntityFunctions::ProcessFrame, X)

	PLD
	RTS
.endroutine


; DB = $7E
.A16
.I16
.routine RenderFrame
	PHD

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


	LDA	#.loword(platform)
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


	JSR	MetaSprite::RenderLoopEnd

	PLD
	RTS
.endroutine

.endmodule

; vim: set ft=asm:

