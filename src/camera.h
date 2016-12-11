.ifndef ::_CAMERA_H_
::_CAMERA_H_ = 1

.setcpu "65816"

.include "common/modules.inc"


.importmodule Camera
	;; The x position of the screen
	;; (uint16, WRAM7E)
	.importlabel xPos

	;; The y position of the screen
	;; (uint16, WRAM7E)
	.importlabel yPos


	;; Starting offset of the camera
	;; This is needed to prevent signed comparisons in collision code
	STARTING_XOFFSET = $1000
	STARTING_YOFFSET = $C000

	;; The height (in pixels) of the active window
	WINDOW_HEIGHT = 240

	;; Initialize the camera module
	;;
	;; MUST be called after Entity::Init
	;;
	;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	.importroutine Init

	;; Process a single frame of the camera module
	;;
	;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	.importroutine ProcessFrame

.endimportmodule

.endif

; vim: set ft=asm:

