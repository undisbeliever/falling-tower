.ifndef ::_TESTS__METASPRITE__TESTDATA_H_
::_TESTS__METASPRITE__TESTDATA_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"

.include "metasprite/metasprite.h"

.setcpu "65816"


N_FIXED_ONE_TILE	= 4
N_FIXED_TWO_TILES	= 8
N_FIXED_ONE_ROW		= 4
N_FIXED_TWO_ROWS	= 7


.importmodule UnitTest_MetaSprite_Data
	.scope FrameSets
		;; Each of these framesets:
		;;	* Is marked FIXED
		;;	* contains one frame with a unique tileset
		;;	* The share a paletteList with only 1 palette
		;;
		;; They have no collision data, tile data, object list data or palette data

		.repeat ::N_FIXED_ONE_TILE, i
			.ident(.sprintf("Fixed_OneTile_%i", i)) = i
		.endrepeat
		count .set ::N_FIXED_ONE_TILE

		.repeat ::N_FIXED_TWO_TILES, i
			.ident(.sprintf("Fixed_TwoTiles_%i", i)) = count + i
		.endrepeat
		count .set count + ::N_FIXED_TWO_TILES

		.repeat ::N_FIXED_ONE_ROW, i
			.ident(.sprintf("Fixed_OneRow_%i", i)) = count + i
		.endrepeat
		count .set count + ::N_FIXED_ONE_ROW

		.repeat ::N_FIXED_TWO_ROWS, i
			.ident(.sprintf("Fixed_TwoRows_%i", i)) = count + i
		.endrepeat
		count .set count + ::N_FIXED_TWO_ROWS

		Fixed_OneTile_Overflow  = Fixed_OneTile_2
		Fixed_OneTile_Overflow2 = Fixed_OneTile_3
		Fixed_TwoTiles_Overflow  = Fixed_TwoTiles_7
		Fixed_OneRow_Overflow  = Fixed_OneRow_2
		Fixed_OneRow_Overflow2 = Fixed_OneRow_3
		Fixed_TwoRows_Overflow  = Fixed_TwoRows_6
	.endscope



	.repeat ::N_FIXED_ONE_TILE, i
		.importlabel .ident(.sprintf("Tileset_Fixed_OneTile_%i_DMA0", i))
	.endrepeat

	.repeat ::N_FIXED_TWO_TILES, i
		.importlabel .ident(.sprintf("Tileset_Fixed_TwoTiles_%i_DMA0", i))
		.importlabel .ident(.sprintf("Tileset_Fixed_TwoTiles_%i_DMA1", i))
	.endrepeat

	.repeat ::N_FIXED_ONE_ROW, i
		.importlabel .ident(.sprintf("Tileset_Fixed_OneRow_%i_DMA0", i))
	.endrepeat

	.repeat ::N_FIXED_TWO_ROWS, i
		.importlabel .ident(.sprintf("Tileset_Fixed_TwoRows_%i_DMA0", i))
		.importlabel .ident(.sprintf("Tileset_Fixed_TwoRows_%i_DMA1", i))
	.endrepeat

	Tileset_Fixed_OneTile_Overflow_DMA0 = Tileset_Fixed_OneTile_2_DMA0
	Tileset_Fixed_OneTile_Overflow2_DMA0 = Tileset_Fixed_OneTile_3_DMA0
	Tileset_Fixed_TwoTiles_Overflow_DMA0 = Tileset_Fixed_TwoTiles_7_DMA0
	Tileset_Fixed_TwoTiles_Overflow_DMA1 = Tileset_Fixed_TwoTiles_7_DMA1
	Tileset_Fixed_OneRow_Overflow_DMA0 = Tileset_Fixed_OneRow_2_DMA0
	Tileset_Fixed_OneRow_Overflow2_DMA0 = Tileset_Fixed_OneRow_3_DMA0
	Tileset_Fixed_TwoRows_Overflow_DMA0 = Tileset_Fixed_TwoRows_6_DMA0
	Tileset_Fixed_TwoRows_Overflow_DMA1 = Tileset_Fixed_TwoRows_6_DMA1
.endimportmodule

.endif

; vim: ft=asm:

