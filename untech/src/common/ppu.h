; Macros/routines relating to the PPU

.ifndef ::_COMMON__PPU_H_
::_COMMON__PPU_H_ := 1

.include "registers.inc"


;; Sets the VRAM tiles/map size and position registers.
;;
;; The values to use are fixed constants and stored in the `namespace` scope.
;;	* namespace::BGx_MAP - tilemap location, word address in VRAM
;;	* namespace::BGx_SIZE - tile size, matches the values BGXSC_SIZE_*
;;      * namespace::BGx_TILES - tile location, word address in VRAM
;;	* namespace::OAM_TILES - OAM tile location, word address in VRAM
;;	* namespace::OAM_NAME - matches the values OBSEL_NAME_*
;;	* namespace::OAM_SIZE - size of the OAM tiles, matches the values OBSEL_SIZE_*
;;
;; If a BGx_MAP or BGx_TILES is missing then the register will not be set.
;;
;; As the `BG12NBA` and `BG34NBA` registers handle 2 layers, if one layer's tile address variable is missing its word address is 0.
;;
;; REQUIRES: 8 bit A, 16 bit Index, DB access registers
;; MODIFIES: A, Y
.macro SetVramBaseAndSize namespace
	.assert .asize = 8, error, "Require 8 bit Accumulator"
	.assert .isize = 16, error, "Require 16 bit Index"

	__SetVramBaseAndSize_map namespace::BG1_MAP, namespace::BG1_SIZE, namespace::BG2_MAP, namespace::BG2_SIZE, BG1SC
	__SetVramBaseAndSize_map namespace::BG3_MAP, namespace::BG3_SIZE, namespace::BG4_MAP, namespace::BG4_SIZE, BG1SC

	__SetVramBaseAndSize_tiles namespace::BG1_TILES, namespace::BG2_TILES, namespace::BG3_TILES, namespace::BG4_TILES

	.ifdef namespace::OAM_TILES
		.assert (namespace::OAM_TILES / OBSEL_BASE_WALIGN) * OBSEL_BASE_WALIGN = namespace::OAM_TILES, error, "OAM_TILES does not align with OBSEL_BASE_WALIGN"
		.assert namespace::OAM_TILES < $8000, error, "OAM_TILES too large"
		.assert (namespace::OAM_SIZE & OBSEL_SIZE_MASK) = namespace::OAM_SIZE, error, "OAM_SIZE invalid"
		.assert (namespace::OAM_NAME & OBSEL_NAME_MASK) = namespace::OAM_NAME, error, "OAM_NAME invalid"

		LDA	#(namespace::OAM_SIZE & OBSEL_SIZE_MASK) | (namespace::OAM_NAME & OBSEL_NAME_MASK) | (namespace::OAM_TILES / OBSEL_BASE_WALIGN) & OBSEL_BASE_MASK
		STA	OBSEL
	.endif
.endmacro

	.macro __SetVramBaseAndSize_map map1, size1, map2, size2, register
		.ifdef map1
			.assert (map1 / BGXSC_BASE_WALIGN) * BGXSC_BASE_WALIGN = map1, error, "BGx_MAP does not align with BGXSC_BASE_WALIGN"
			.assert map1 < $8000, error, "BGx_MAP too large"
			.assert (size1 & BGXSC_MAP_SIZE_MASK) = size1, error, "BGx_SIZE invalid"

			.ifdef map2
				.assert (map2 / BGXSC_BASE_WALIGN) * BGXSC_BASE_WALIGN = map2, error, "BGx_MAP does not align with BGXSC_BASE_WALIGN"
				.assert map2 < $8000, error, "BGx_MAP too large"
				.assert (size2 & BGXSC_MAP_SIZE_MASK) = size2, error, "BGx_SIZE invalid"

				LDY	#((map1 / BGXSC_BASE_WALIGN) << BGXSC_BASE_SHIFT | (size1 & BGXSC_MAP_SIZE_MASK)) | ((map2 / BGXSC_BASE_WALIGN) << BGXSC_BASE_SHIFT | (size2 & BGXSC_MAP_SIZE_MASK)) << 8
				STY	register
			.else
				LDA	#(map1 / BGXSC_BASE_WALIGN) << BGXSC_BASE_SHIFT | (size1 & BGXSC_MAP_SIZE_MASK)
				STA	register
			.endif
		.else
			.ifdef map2
				.assert (map2 / BGXSC_BASE_WALIGN) * BGXSC_BASE_WALIGN = map2, error, "BGx_MAP does not align with BGXSC_BASE_WALIGN"
				.assert map2 < $8000, error, "BGx_MAP too large"
				.assert (size2 & BGXSC_MAP_SIZE_MASK) = size2, error, "BGx_SIZE invalid"

				LDA	#(map2 / BGXSC_BASE_WALIGN) << BGXSC_BASE_SHIFT | (size2 & BGXSC_MAP_SIZE_MASK)
				STA	register + 1
			.endif
		.endif
	.endmacro

	.macro __SetVramBaseAndSize_tiles bg1, bg2, bg3, bg4
		.ifndef bg1
			bg1 = 0
		.endif
		.ifndef bg2
			bg2 = 0
		.endif
		.ifndef bg3
			bg3 = 0
		.endif
		.ifndef bg4
			bg4 = 0
		.endif

		.assert (bg1 / BG12NBA_BASE_WALIGN) * BG12NBA_BASE_WALIGN = bg1, error, "BG1_MAP map word adddress does not align with BG12NBA_BASE_WALIGN"
		.assert bg1 < $8000, error, "BG1_MAP address too large"
		.assert (bg2 / BG12NBA_BASE_WALIGN) * BG12NBA_BASE_WALIGN = bg2, error, "BG2_MAP map word adddress does not align with BG12NBA_BASE_WALIGN"
		.assert bg2 < $8000, error, "BG2_MAP address too large"
		.assert (bg3 / BG34NBA_BASE_WALIGN) * BG34NBA_BASE_WALIGN = bg3, error, "BG3_MAP map word adddress does not align with BG34NBA_BASE_WALIGN"
		.assert bg3 < $8000, error, "BG3_MAP address too large"
		.assert (bg4 / BG34NBA_BASE_WALIGN) * BG34NBA_BASE_WALIGN = bg4, error, "BG4_MAP map word adddress does not align with BG34NBA_BASE_WALIGN"
		.assert bg4 < $8000, error, "BG4_MAP address too large"

		LDY	#(((bg2 / BG12NBA_BASE_WALIGN) << BG12NBA_BG2_SHIFT) & BG12NBA_BG2_MASK) | ((bg1 / BG12NBA_BASE_WALIGN) & BG12NBA_BG1_MASK) | ((((bg4 / BG12NBA_BASE_WALIGN) << BG34NBA_BG4_SHIFT) & BG34NBA_BG4_MASK) | ((bg3 / BG34NBA_BASE_WALIGN) & BG34NBA_BG3_MASK)) << 8
		STY	BG12NBA
	.endmacro

.endif

; vim: ft=asm:

