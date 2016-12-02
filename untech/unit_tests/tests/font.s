; resources

.include "common/modules.inc"

.setcpu "65816"

.module Font
	.exportlabel Tiles, far
	.exportlabel Tiles_size
	.exportlabel Palettes, far
	.exportlabel Palettes_size


.segment "BANK1"

Tiles:
	.incbin "resources/font.2bpp"
Tiles_size = * - Tiles

Palettes:                                  ; ANSI Colors
	.word	$7FFF, $0000, $0000, $0000 ; Black   (0)
	.word	$7FFF, $001F, $0000, $0000 ; Red     (1)
	.word	$7FFF, $02E0, $0000, $0000 ; Green   (2)
	.word	$7FFF, $02FF, $0000, $0000 ; Yellow  (3)
	.word	$7FFF, $7C00, $0000, $0000 ; Blue    (4)
	.word	$7FFF, $3C0F, $0000, $0000 ; Magenta (5)
	.word	$7FFF, $3DE0, $0000, $0000 ; Cyan    (6)
	.word	$7FFF, $3DEF, $0000, $0000 ; Gray    (7)
Palettes_size = * - Palettes

.endmodule


; vim: set ft=asm:

