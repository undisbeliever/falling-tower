; Common memory used by the various MetaSprite testing modules

.include "_test_data.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "metasprite/metasprite.h"
.include "metasprite/dataformat.h"


.assert METASPRITE_VRAM_TILE_SLOTS = 16, error, "Bad config"
.assert METASPRITE_VRAM_ROW_SLOTS = 14, error, "Bad config"

.module UnitTest_MetaSprite_Data

.macro FrameSet name, lifestyle, size, paletteList, frameList
	.pushseg
	.segment METASPRITE_FRAMESET_DATA_BLOCK
		.proc name
			.addr	paletteList
			.byte	paletteList::count

			.byte	MetaSprite__FrameSet_TilesetLifecycle::lifestyle | MetaSprite__FrameSet_TilesetSize::size

			.addr	frameList
			.byte	frameList::count

			; ::TODO animations::
		.endproc
	.popseg
.endmacro

.macro _List name, item1, item2, item3, item4
	.proc name
		.if .not .blank(item4)
			.addr	item1
			.addr	item2
			.addr	item3
			.addr	item4
		.elseif .not .blank(item3)
			count = 3
			.addr	item1
			.addr	item2
			.addr	item3
		.elseif .not .blank(item2)
			count = 2
			.addr	item1
			.addr	item2
		.else
			count = 1
			.addr	item1
		.endif
	.endproc
.endmacro


.macro FrameList name, frame1, frame2, frame3, frame4
	.pushseg
	.segment METASPRITE_FRAME_LIST_BLOCK
		_List name, frame1, frame2, frame3, frame4
	.popseg
.endmacro


.macro PaletteList name, palette1, palette2, palette3, palette4
	.pushseg
	.segment METASPRITE_PALETTE_LIST_BLOCK
		_List name, palette1, palette2, palette3, palette4
	.popseg
.endmacro


.macro Frame name, tileset
	.pushseg
	.segment METASPRITE_FRAME_DATA_BLOCK
		.proc name
			; Only testing tileset
			.addr	0
			.addr	0
			.addr	0
			.addr	0
			.addr	tileset
		.endproc
	.popseg
.endmacro


.macro Tileset name, count, nBlocks
	.pushseg
	.segment METASPRITE_FRAME_DATA_BLOCK
		.proc name
			; Only testing tileset uniqueness, not dma table (ATM)
			.byte	count

			.addr	.ident(.sprintf("%s_DMA0", .string(name)))

			.if nBlocks = 2
				.addr	.ident(.sprintf("%s_DMA1", .string(name)))
			.else
				.addr	0
			.endif
		.endproc

	.segment METASPRITE_DMA_TABLE_BLOCK
		.exportlabel .ident(.sprintf("%s_DMA0", .string(name)))
		.ident(.sprintf("%s_DMA0", .string(name))):
			.addr	$FFFF

		.if nBlocks = 2
			.exportlabel .ident(.sprintf("%s_DMA1", .string(name)))
			.ident(.sprintf("%s_DMA1", .string(name))):
				.addr	$FFFF
		.endif
	.popseg
.endmacro


.segment METASPRITE_PALETTE_DATA_BLOCK
ExamplePaletteData:
	.word	$FFFF

PaletteList ExamplePaletteList, ExamplePaletteData



.segment METASPRITE_FRAMESET_LIST_BLOCK
.export MetaSpriteFrameSetTable: far
.export MetaSpriteFrameSetTable_end: far
MetaSpriteFrameSetTable:

.repeat ::N_FIXED_ONE_TILE, i
	.addr .ident(.sprintf("FrameSet_Fixed_OneTile_%i", i))
.endrepeat
.repeat ::N_FIXED_TWO_TILES, i
	.addr .ident(.sprintf("FrameSet_Fixed_TwoTiles_%i", i))
.endrepeat
.repeat ::N_FIXED_ONE_ROW, i
	.addr .ident(.sprintf("FrameSet_Fixed_OneRow_%i", i))
.endrepeat
.repeat ::N_FIXED_TWO_ROWS, i
	.addr .ident(.sprintf("FrameSet_Fixed_TwoRows_%i", i))
.endrepeat

	.addr FrameSet_Dynamic_OneTile
	.addr FrameSet_Dynamic_TwoTiles
	.addr FrameSet_Dynamic_OneRow
	.addr FrameSet_Dynamic_TwoRows
MetaSpriteFrameSetTable_end:


.repeat ::N_FIXED_ONE_TILE, i
	Tileset		.ident(.sprintf("Tileset_Fixed_OneTile_%i", i)), 1, 1
	Frame		.ident(.sprintf("Frame_Fixed_OneTile_%i", i)), .ident(.sprintf("Tileset_Fixed_OneTile_%i", i))
	FrameList	.ident(.sprintf("FrameList_Fixed_OneTile_%i", i)), .ident(.sprintf("Frame_Fixed_OneTile_%i", i))
	FrameSet	.ident(.sprintf("FrameSet_Fixed_OneTile_%i", i)), FIXED, ONE_16_TILE, ExamplePaletteList, .ident(.sprintf("FrameList_Fixed_OneTile_%i", i))
.endrepeat

.repeat ::N_FIXED_TWO_TILES, i
	Tileset		.ident(.sprintf("Tileset_Fixed_TwoTiles_%i", i)), 2, 2
	Frame		.ident(.sprintf("Frame_Fixed_TwoTiles_%i", i)),	.ident(.sprintf("Tileset_Fixed_TwoTiles_%i", i))
	FrameList	.ident(.sprintf("FrameList_Fixed_TwoTiles_%i", i)), .ident(.sprintf("Frame_Fixed_TwoTiles_%i", i))
	FrameSet	.ident(.sprintf("FrameSet_Fixed_TwoTiles_%i", i)), FIXED, TWO_16_TILES, ExamplePaletteList, .ident(.sprintf("FrameList_Fixed_TwoTiles_%i", i))
.endrepeat


.repeat ::N_FIXED_ONE_ROW, i
	Tileset		.ident(.sprintf("Tileset_Fixed_OneRow_%i", i)), 8, 1
	Frame		.ident(.sprintf("Frame_Fixed_OneRow_%i", i)), .ident(.sprintf("Tileset_Fixed_OneRow_%i", i))
	FrameList	.ident(.sprintf("FrameList_Fixed_OneRow_%i", i)), .ident(.sprintf("Frame_Fixed_OneRow_%i", i))
	FrameSet	.ident(.sprintf("FrameSet_Fixed_OneRow_%i", i)), FIXED, ONE_VRAM_ROW, ExamplePaletteList, .ident(.sprintf("FrameList_Fixed_OneRow_%i", i))
.endrepeat

.repeat ::N_FIXED_TWO_ROWS, i
	Tileset		.ident(.sprintf("Tileset_Fixed_TwoRows_%i", i)), 16, 2
	Frame		.ident(.sprintf("Frame_Fixed_TwoRows_%i", i)),	.ident(.sprintf("Tileset_Fixed_TwoRows_%i", i))
	FrameList	.ident(.sprintf("FrameList_Fixed_TwoRows_%i", i)), .ident(.sprintf("Frame_Fixed_TwoRows_%i", i))
	FrameSet	.ident(.sprintf("FrameSet_Fixed_TwoRows_%i", i)), FIXED, TWO_VRAM_ROWS, ExamplePaletteList, .ident(.sprintf("FrameList_Fixed_TwoRows_%i", i))
.endrepeat

;; Dynamic tilesets have two frames, which have the following.
;; Frames 0 & 2 have the same tileset
;; Frame 2 has a different tileset
.macro DynamicFrameSet name, size, tile_count, nBlocks
	Tileset		.ident(.sprintf("Tileset_Dynamic_%s_0", .string(name))), tile_count, nBlocks
	Tileset		.ident(.sprintf("Tileset_Dynamic_%s_1", .string(name))), tile_count, nBlocks

	Frame		.ident(.sprintf("Frame_Dynamic_%s_0", .string(name))), .ident(.sprintf("Tileset_Dynamic_%s_0", .string(name)))
	Frame		.ident(.sprintf("Frame_Dynamic_%s_1", .string(name))), .ident(.sprintf("Tileset_Dynamic_%s_1", .string(name)))
	Frame		.ident(.sprintf("Frame_Dynamic_%s_2", .string(name))), .ident(.sprintf("Tileset_Dynamic_%s_0", .string(name)))

	FrameList	.ident(.sprintf("FrameList_Dynamic_%s", .string(name))), .ident(.sprintf("Frame_Dynamic_%s_0", .string(name))), .ident(.sprintf("Frame_Dynamic_%s_1", .string(name))), .ident(.sprintf("Frame_Dynamic_%s_2", .string(name)))

	FrameSet	.ident(.sprintf("FrameSet_Dynamic_%s", .string(name))),	DYNAMIC, size, ExamplePaletteList, .ident(.sprintf("FrameList_Dynamic_%s", .string(name)))
.endmacro

DynamicFrameSet OneTile, ONE_16_TILE, 1, 1
DynamicFrameSet TwoTiles, TWO_16_TILES, 2, 2
DynamicFrameSet OneRow, ONE_VRAM_ROW, 8, 1
DynamicFrameSet TwoRows, TWO_VRAM_ROWS, 16, 2

.endmodule

; vim: set ft=asm:

