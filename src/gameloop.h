.ifndef ::_GAMELOOP_H_
::_GAMELOOP_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"
.include "metasprite/metasprite.h"

.setcpu "65816"

.enum GameState
	PLAYING		= 0
	GAME_OVER	= 2
	PAUSED		= 4
.endenum


.importmodule GameLoop
	;; The current game state
	;; See GameState enum
	;; (word)
	.importlabel	state

	;; Initializes and plays the game
	;; REQUIRES: 8 bit A, 16 bit Index, DB = $80
	.importroutine PlayGame
.endimportmodule

.endif

; vim: ft=asm:

