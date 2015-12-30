
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "gameloop.h"

.setcpu "65816"

.code

.routine Main
	REP	#$30
	SEP	#$20
.A8
.I16
	REPEAT
		JSR	GameLoop::PlayGame
	FOREVER
.endroutine


.segment "COPYRIGHT"
		;1234567890123456789012345678901
	.byte	"Falling Tower                  ", 10
	.byte	"(c) 2015, The Undisbeliever    ", 10
	.byte	"MIT Licensed, CC0 Graphics     ", 10
	.byte	"One Game Per Month Challange   ", 10


; vim: set ft=asm:

