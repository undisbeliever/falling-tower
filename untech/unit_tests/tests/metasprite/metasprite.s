; Common memory used by the various MetaSprite testing modules

.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "metasprite/metasprite.h"
.include "tests/tests.h"
.include "tests/static-random.inc"
.include "tests/metasprite/metasprite.h"

.setcpu "65816"

.export MetaSpriteDpOffset: zeropage = ExampleEntity::metasprite

.module UnitTest_MetaSprite
	.exportlabel	entities


.segment "SHADOW"
	entities:	.res N_ENTITIES * .sizeof(ExampleEntity)
entities_end:
entities_size = entities_end - entities


.code

.routine Reset
	SEP	#$20
.A8
	LDA	#$7E
	PHA
	PLB


	REP	#$30
.A16
.I16
	LDX	#entities_size - 2
	REPEAT
		STZ	entities, X
		DEX
		DEX
	UNTIL_ZERO

	LDX	#MetaSprite::paletteBuffer_size - 2
	REPEAT
		STZ	a:.loword(MetaSprite::paletteBuffer), X
		DEX
		DEX
	UNTIL_ZERO

	JMP	MetaSprite::Reset
.endroutine

; ::DEBUG fix import error::
.segment "BANK1"
.export MetaSpriteFrameSetTable: far
.export MetaSpriteFrameSetTable_end: far
MetaSpriteFrameSetTable:
MetaSpriteFrameSetTable_end:

.endmodule

; vim: set ft=asm:

