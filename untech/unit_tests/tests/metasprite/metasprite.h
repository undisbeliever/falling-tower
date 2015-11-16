.ifndef ::_TESTS__METASPRITE__METASPRITE_H_
::_TESTS__METASPRITE__METASPRITE_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"

.include "metasprite/metasprite.h"

.setcpu "65816"

.struct ExampleEntity
	padding		.word
	metasprite	.tag MetaSpriteStruct
.endstruct

.define N_ENTITIES 20

.importmodule UnitTest_MetaSprite
	.importlabel	entities
	entities_end := entities + N_ENTITIES * .sizeof(ExampleEntity)


	;; Resets the state to initial values
	;;
	;; This routine:
	;;	* Sets DB set to $7E
	;;	* Sets A and Index size to 16 bits
	;;	* clears the memory of `entities`
	;;	* clears the palette buffer
	;;	* calls MetaSprite::Init
	.importroutine Reset

.endimportmodule


.endif

; vim: ft=asm:

