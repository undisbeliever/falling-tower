.ifndef ::_RANDOM_H_
::_RANDOM_H_ = 1

.setcpu "65816"

.include "common/modules.inc"

;; This module is a Linear congruential psudeo random number generator.
;;
;; In order to increase the observed randomness of this module,
;; the function `AddJoypadEntropy` should be called once every frame.
;; This will cycle the random number generator once or twice, depending
;; on the state of JOY1.
.importmodule Random

	;; The random seed
	;; (double word - shadow)
	.importlabel seed


	;; Adds entropy to the random seed by calling `Rnd`
	;;	* twice if the state of JOY1 has changed since the last call.
	;;	* once if the joypad hasn't changed.
	;;
	;; This can add a bit of variety to the random number generator.
	;;
	;; REQUIRE: 16 bit A, 16 bit Index, AutoJoy Enbled, DB access shadow
	.importroutine AddJoypadEntropy


	;; Generates a 16 bit random number between 0 and A (non-inclusive)
	;;
	;; Skewed towards smaller numbers
	;;
	;; REQUIRE: 16 bit A, 16 bit Index, DB access shadow
	;; INPUT:
	;;	Y: unsigned 16 bit value.
	;; OUTPUT:
	;;	A: unsigned 16 bit value between 0 and (A-1) (inlusive).
	.importroutine	Rnd_U16A


	;; Generates a 16 bit random number between X and Y
	;;
	;; Skewed towards smaller numbers
	;;
	;; REQUIRE: 16 bit A, 16 bit Index, DB access shadow
	;; INPUT:
	;;	X: unsigned 16 bit min
	;;	Y: unsigned 16 bit max
	;; OUTPUT:
	;;	A: unsigned 16 bit value.
	.importroutine	Rnd_U16X_U16Y

.endimportmodule

.endif

; vim: set ft=asm:

