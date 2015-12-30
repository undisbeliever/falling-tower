; resources

.ifndef ::_RESOURCES__FONT_H_
::_RESOURCES__FONT_H_ := 1

.include "common/modules.inc"

.importmodule Font
	.importlabel Tiles, far
	.importlabel Tiles_size
	.importlabel Palettes, far
	.importlabel Palettes_size

	.enum
		BLACK
		RED
		GREEN
		YELLOW
		BLUE
		MAGENTA
		CYAN
		GRAY
	.endenum

.endimportmodule

.endif

; vim: set ft=asm:

