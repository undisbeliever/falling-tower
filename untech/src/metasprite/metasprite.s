
.include "metasprite.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/synthetic.inc"

.setcpu "65816"

.module MetaSprite

; ::DEBUG::
; ::TODO make it entity::metaSpriteState in the future::
.export MetaSpriteDpOffset = 2
.define MSDP MetaSpriteDpOffset + MetaSpriteStruct


.include "palette.asm"
.include "render.asm"
.include "vram.asm"
.include "dma.asm"


; DB = $7E
.A16
.I16
.routine Init
	Init__Render
	Init__Palette
	Init__Vram

	RTS
.endroutine



.segment METASPRITE_FRAME_DATA_BLOCK
	frameDataOffset = .bankbyte(*) << 16

.segment METASPRITE_FRAME_OBJECTS_BLOCK
	fobjDataOffset	= .bankbyte(*) << 16

.segment METASPRITE_PALETTE_DATA_BLOCK
	paletteDataBank = .bankbyte(*)

.segment METASPRITE_TILESET_BLOCK
	tilesetBankOffset = .bankbyte(*) << 16

.segment METASPRITE_DMA_TABLE_BLOCK
	dmaTableBank = .bankbyte(*)

.endmodule

