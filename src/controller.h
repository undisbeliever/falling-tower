.ifndef ::_CONTROLLER_H_
::_CONTROLLER_H_ = 1

.setcpu "65816"

.include "common/modules.inc"


.importmodule Controller
	;; New buttons pressed on current frame.
	;; (word - shadow)
	.importlabel pressed

	;; The state of the current frame
	;; (word - shadow)
	.importlabel current


	;; Updates the controller variables.
	;;
	;; Will not check the status of the HVJOY_AUTOJOY flag, that
	;; should be done in VBlank
	;;
	;; REQUIRE: 16 bit A, 16 bit Index, AUTOJOY enabled, DB access shadow
	.importroutine Update

.endimportmodule

.endif

; vim: set ft=asm:

