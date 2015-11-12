.ifndef ::_METASPRITE__METASPRITE_H_
::_METASPRITE__METASPRITE_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"

.include "dataformat.h"

.setcpu "65816"


METASPRITE_STATUS_PALETTE_SET_FLAG	= %10000000

.struct MetaSpriteStruct
	;; The state of the metasprite
	;; 	%p0000000
	;;
	;; p: palette set
	status			.byte
	currentFrame		.addr
	blockOneCharAttrOffset	.word
	blockTwoCharAttrOffset	.word
.endstruct

;; The dp offset between the DP passed to the functions
;; and the the address of `MetaSprite__State`.
;;
;; Should be the location of the `MetaSprite__State` struct
;; with the entity struct.
;;
;; ::TODO make it entity::metaSpriteState in the future::
.global MetaSpriteDpOffset: zeropage


.importmodule MetaSprite
	;; The segment that holds the frame data.
	CONFIG	METASPRITE_FRAME_DATA_BLOCK, "METASPRITE_FRAME"
	CONFIG	METASPRITE_FRAME_OBJECTS_BLOCK, "METASPRITE_FRAME_OBJECTS"
	CONFIG	METASPRITE_TILESET_BLOCK, "METASPRITE_TILESET_TABLE"
	CONFIG	METASPRITE_ENTITY_COLLISION_HITBOXES_BLOCK, "METASPRITE_ENTITY_COLLISION_HITBOXES"
	CONFIG	METASPRITE_TILE_COLLISION_HITBOXES_BLOCK, "METASPRITE_TILE_COLLISION_HITBOXES"
	CONFIG	METASPRITE_ACTION_POINT_BLOCK, "METASPRITE_ACTION_POINT"
	CONFIG	METASPRITE_PALETTE_DATA_BLOCK, "METASPRITE_PALETTE"
	CONFIG	METASPRITE_DMA_TABLE_BLOCK, "METASPRITE_DMA_TABLE"

	;; The offset between the sprite xpos/ypos and the frame xpos/ypos
	POSITION_OFFSET = 128


	;; The offsetted position of the metasprite to render
	;; (word, value = xPos - POSITION_OFFSET)
	.importlabel xPos
	.importlabel yPos


	;; When zero, load the buffer into OAM during VBlank
	;; When buffer is copied, the variable is set to non-zero
	;; (byte, shadow)
	.importlabel updateOamBufferOnZero

	;; The buffer to load into OAM
	;; (oamBuffer_size bytes, WRAM7E)
	.importlabel oamBuffer, far
	oamBuffer_size = 128 * 4 + 128 / 4


	;; When zero, load the palette buffer into CGRAM during VBlank
	;; When buffer is copied, the variable is set to non-zero
	;; (byte, shadow)
	.importlabel updatePaletteBufferOnZero

	;; The buffer to load into CGRAM for the sprite palettes
	;; (paletteBuffer_size bytes, WRAM7E)
	.importlabel paletteBuffer, far
	paletteBuffer_size = 32 * 8



	;; Initialize the metasprite module
	;;
	;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	.importroutine Init


	;; Palettes
	;; ========

	;;; Sets the palette of a metasprite.
	;;;
	;;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	;;;
	;;; INPUT:
	;;;	DP: MetaSpriteStruct address - MetaSpriteDpOffset
	;;;	A: palette address in METASPRITE_PALETTE_DATA_BLOCK
	;;;	   points to the 15 colors in metasprite
	;;;	   MUST not be NULL
	;;;
	;;; OUTPUT: C set if succeeded
	.importroutine SetPaletteAddress

	;;; Removes the palette from the metasprite
	;;;
	;;; This function should not be called directly,
	;;; instead you should call `Deactive` ::CHECK name::
	;;;
	;;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	;;;
	;;; INPUT:
	;;;	DP: MetaSpriteStruct address - MetaSpriteDpOffset
	.importroutine RemovePalette

	;;; Retrieves the palette of a metasprite.
	;;;
	;;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	;;;
	;;; INPUT:
	;;;	DP: MetaSpriteStruct address - MetaSpriteDpOffset
	;;;
	;;; RETURN:
	;;;	A: palette address in METASPRITE_PALETTE_DATA_BLOCK
	;;;	   points to the 15 colors in metasprite
	;;;	   NULL (0) if metasprite has no palette (in which case it is removed)
	;;;	zero: set if no metasprite has no palette
	.importroutine GetPaletteAddress

	;;; Rebuilds the palette buffer
	;;;
	;;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	;;;
	.importroutine ReloadPalettes



	;; ::TODO handle rest of metasprite modules, tiles, etc::


	;; Render Loop
	;; ===========

	;;; Start a render loop
	;;;
	;;; REQUIRES: 16 bit A, DB = $7E
	.importroutine RenderLoopInit

	;;; Renders a metasprite frame
	;;;
	;;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	;;;
	;;; INPUT:
	;;;	DP: MetaSpriteStruct address - MetaSpriteDpOffset
	;;; 	xPos: sprite.xPos - POSITION_OFFSET
	;;; 	yPos: sprite.yPos - POSITION_OFFSET
	.importroutine RenderFrame

	;;; Finalizes the render loop
	;;;
	;;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	.importroutine RenderLoopEnd

.endimportmodule

.endif

; vim: ft=asm:

