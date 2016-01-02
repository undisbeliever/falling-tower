.ifndef ::_ENTITYPHYSICS_H_
::_ENTITYPHYSICS_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"
.include "metasprite/metasprite.h"

.setcpu "65816"

.importmodule EntityPhysics

	;; Processes an entity's physics (including movement and gravity)
	;;
	;; REQUIRES: 16 bit A, 16 Index, DB = $7E
	;; INPUT: DP = entity to process
	;;	   A = controls
	;; OUTPUT: always returns Carry set
	.importroutine ProcessEntityPhyicsWithMovement

	;; Processes an entity's physics (including gravity)
	;;
	;; REQUIRES: 16 bit A, 16 Index, DB = $7E
	;; INPUT: DP = entity to process
	;; OUTPUT: always returns Carry set
	.importroutine ProcessEntityPhyicsWithGravity

	;; Processes an entity's physics (ignoring gravity)
	;;
	;; REQUIRES: 16 bit A, 16 Index, DB = $7E
	;; INPUT: DP = entity to process
	;; OUTPUT: always returns Carry set
	.importroutine ProcessEntityPhyicsWithoutGravity

.endimportmodule

.endif

; vim: ft=asm:

