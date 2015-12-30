.ifndef ::_ENTITY_H_
::_ENTITY_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"
.include "metasprite/metasprite.h"

.setcpu "65816"

CONFIG ENTITY_STRUCT_SIZE, 64

.enum EntityFunctions
	;; Called when ititializing the entity
	;;
	;; REGISTERS: 16 bit A, 16 bit Index, DB = $7E
	;; INPUT: DP = entity
	Init		= 0

	;; Process entity frame.
	;; Called once per frame.
	;; Do not display the entity, that is handed by the gameloop.
	;;
	;; REGISTERS: 16 bit A, 16 bit Index, DB = $7E
	;; INPUT: DP = entity
	ProcessFrame	= 2
.endenum

.macro .entitystruct name
	.define __ENTITY_STRUCT_NAME_ name

	.struct name
		;; Location of the next entity in the list
		nextPtr		.res 2

		;; Function table for the entity
		functionPtr	.res 2

		;; Entity position
		;; (0:16:8 fixed point)
		xPos		.res 3
		yPos		.res 3

		;; Entity Velocity
		;; (1:7:8 fixed point)
		xVecl		.res 2
		yVecl		.res 2

		metasprite	.tag MetaSpriteStruct
.endmacro

.macro .endentitystruct
	.endstruct

	.assert .sizeof(__ENTITY_STRUCT_NAME_) < ENTITY_STRUCT_SIZE, error, "Out of Memory"
	.undefine __ENTITY_STRUCT_NAME_
.endmacro

.entitystruct EntityStruct
.endentitystruct


.importmodule Entity
	;; Initialize the entity module
	;; REQUIRES: 8 bit A, 16 bit Index
	.importroutine Init

	;; Processes a single frame of the gameloop
	;; REQUIRES: 16 bit A, 16 Index, DB = $7E
	.importroutine ProcessFrame


	;; Renders the entities to the screen
	;; REQUIRES: 16 bit A, 16 Index, DB = $7E
	.importroutine RenderFrame

.endimportmodule

.endif

; vim: ft=asm:
