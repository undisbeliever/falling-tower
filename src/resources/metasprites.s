; resources

.include "common/modules.inc"
.include "common/config.inc"

.include "metasprite/metasprite.h"

.define METASPRITE_TILESET_BLOCK_0 "BANK3"

.define hFlip   $40
.define vFlip   $80
.define hvFlip  $C0
.define small   $00
.define large   $01

.macro Object xPos, yPos, char, order, size, flip
	.if .blank(flip)
		Object xPos, yPos, char, order, size, 0
	.else
		.byte	MetaSprite::POSITION_OFFSET + xPos
		.byte	MetaSprite::POSITION_OFFSET + yPos
		.byte	char
		.byte	(order << 4) | size | flip
	.endif
.endmacro

.macro TileHitbox xPos, yPos, width, height
		.byte	MetaSprite::POSITION_OFFSET + xPos
		.byte	MetaSprite::POSITION_OFFSET + yPos
		.byte	width
		.byte	height
.endmacro

.segment METASPRITE_FRAMESET_LIST_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.export MetaSpriteFrameSetTable: far
MetaSpriteFrameSetTable:

.segment METASPRITE_FRAMESET_DATA_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.exportzp MetaSprite__FrameSet_Bank = .bankbyte(*)

.segment METASPRITE_FRAME_LIST_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.export MetaSprite__Frame_List: far
MetaSprite__Frame_List:

.segment METASPRITE_FRAME_DATA_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.exportzp MetaSprite__Frame_Bank = .bankbyte(*)

.segment METASPRITE_TILESET_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.exportzp MetaSprite__Tileset_Bank = .bankbyte(*)

.segment METASPRITE_DMA_TABLE_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.exportzp MetaSprite__DmaTable_Bank = .bankbyte(*)

.segment METASPRITE_FRAME_OBJECTS_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.exportzp MetaSprite__FrameObjectsList_Bank = .bankbyte(*)

.segment METASPRITE_TILE_COLLISION_HITBOXES_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.exportzp MetaSprite__TileCollisionHitbox_Bank = .bankbyte(*)

.segment METASPRITE_ENTITY_COLLISION_HITBOXES_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.exportzp MetaSprite__EntityCollisionHitboxes_Bank = .bankbyte(*)

.segment METASPRITE_ACTION_POINT_BLOCK
.assert .loword(*) <> 0, error, "Cannot start data with addr=0"
.exportzp MetaSprite__ActionPoints_Bank = .bankbyte(*)



.include "resources/metasprites/player.inc"
.include "resources/metasprites/platforms.inc"



.segment METASPRITE_FRAMESET_LIST_BLOCK
.export MetaSpriteFrameSetTable_end: far
MetaSpriteFrameSetTable_end:
.export MetaSprite__FrameSet_Count = (MetaSpriteFrameSetTable_end - MetaSpriteFrameSetTable) / 2

.segment METASPRITE_FRAME_LIST_BLOCK
.export MetaSprite__Frame_Count = (MetaSprite__Frame_List_end - MetaSprite__Frame_List) / 2
MetaSprite__Frame_List_end:

; vim: set ft=asm:

