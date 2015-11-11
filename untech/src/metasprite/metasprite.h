.ifndef ::_METASPRITE__METASPRITE_H_
::_METASPRITE__METASPRITE_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"

.include "dataformat.h"

.setcpu "65816"

.struct MetaSpriteStruct
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
	;; When buffer is loaded, set this variabel to non-zero
	;; (byte, shadow)
	.importlabel updateBufferOnZero

	;; The buffer to load into OAM
	;; (oamBuffer_size bytes, WRAM7E)
	.importlabel oamBuffer
	oamBuffer_size = 128 * 4 + 128 / 4




	;; Initialize the metasprite module
	;;
	;; REQUIRES: 16 bit Index, DB = $7E
	.importroutine Init


	;; Start a render loop
	;;
	;; REQUIRES: 16 bit A, DB = $7E
	.importroutine RenderLoopInit

	;; ::TODO handle rest of metasprite modules, tiles, palettes, etc::

	;; Renders a metasprite frame
	;;
	;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	;;
	;; INPUT:
	;;	A: MetaSprite__State address
	;; 	xPos: sprite.xPos - POSITION_OFFSET
	;; 	yPos: sprite.yPos - POSITION_OFFSET
	.importroutine RenderFrame_A

	;; Renders a metasprite frame
	;;
	;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	;;
	;; INPUT:
	;;	DP: MetaSprite__State address - MetaSpriteDpOffset
	;; 	xPos: sprite.xPos - POSITION_OFFSET
	;; 	yPos: sprite.yPos - POSITION_OFFSET
	.importroutine RenderFrame

	;; Finalizes the render loop
	;;
	;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
	.importroutine RenderLoopEnd

.endimportmodule

.endif

; vim: ft=asm:

