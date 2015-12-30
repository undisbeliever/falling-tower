; resources

.ifndef ::_VRAM_H_
::_VRAM_H_ := 1


.scope VRAM
	BG3_MAP		= $0000
	BG3_TILES	= $1000
	BG3_SIZE	= BGXSC_SIZE_32X32

	BG1_MAP		= $0400
	BG1_TILES	= $2000
	BG1_SIZE	= BGXSC_SIZE_32X64

	BG2_MAP		= $0C00
	BG2_TILES	= $5000
	BG2_SIZE	= BGXSC_SIZE_32X32

	OAM_TILES	= $6000
	OAM_SIZE	= OBSEL_SIZE_8_16
	OAM_NAME	= 0

	SCREEN_MODE	= 1

	ConsoleMap	= BG3_MAP
	ConsoleTiles	= BG3_TILES
	ConsoleHOFS	= BG3HOFS
	ConsoleVOFS	= BG3VOFS
.endscope


.endif

; vim: set ft=asm:

