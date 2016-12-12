
.scope Player

.segment METASPRITE_TILESET_BLOCK_0
N_TILES = 14
Tiles:
	; Convert to tile16 format
	.repeat 8, i
		.incbin "player.4bpp", i * 64, 64
		.incbin "player.4bpp", (8 + i) * 64, 64
	.endrepeat
	.repeat (N_TILES - 8), i
		.incbin "player.4bpp", (16 + i) * 64, 64
		.incbin "player.4bpp", (24 + i) * 64, 64
	.endrepeat


.segment METASPRITE_DMA_TABLE_BLOCK
DmaTable0:
	.byte 8 * 2 - 2
	.repeat 8, i
		.faraddr	Tiles + 128 * i
	.endrepeat

DmaTable1:
	.byte (N_TILES - 8) * 2 - 2
	.repeat (N_TILES - 8), i
		.faraddr	Tiles + 128 * (8 + i)
	.endrepeat



.segment METASPRITE_TILESET_BLOCK
TilesetFormat = MetaSprite__FrameSet_TilesetSize::TWO_VRAM_ROWS | MetaSprite__FrameSet_TilesetLifecycle::FIXED
Tileset:
	.byte	N_TILES		; nTiles
	.addr	DmaTable0
	.addr	DmaTable1



.segment METASPRITE_PALETTE_DATA_BLOCK
Palette:
	.incbin "player.clr", 2, 30


.segment METASPRITE_PALETTE_LIST_BLOCK
N_PALETTES = 1
PaletteList:
	.addr	Palette



.segment METASPRITE_FRAME_OBJECTS_BLOCK
.scope FO

stand_right:
	.byte 3
		Object  -8,	 -8,	$24, 2, small
		Object   0,	 -8,	$25, 2, small
		Object  -8,	  0,	$00, 2, large

blink_right:
	.byte 3
		Object  -8,	 -8,	$34, 2, small
		Object   0,	 -8,	$35, 2, small
		Object  -8,	  0,	$00, 2, large

jump_right:
	.byte 3
		Object  -8,	 -8,	$26, 2, small
		Object   0,	 -8,	$27, 2, small
		Object  -8,	  0,	$02, 2, large

fall_right:
	.byte 3
		Object  -8,	 -8,	$36, 2, small
		Object   0,	 -8,	$37, 2, small
		Object  -8,	  0,	$04, 2, large

die_right:
	.byte 3
		Object  -8,	 -8,	$28, 2, small
		Object   0,	 -8,	$29, 2, small
		Object  -8,	  0,	$06, 2, large

walk0_right:
	.byte 3
		Object  -8,	 -8,	$38, 2, small
		Object   0,	 -8,	$39, 2, small
		Object  -8,	  0,	$08, 2, large

walk1_right:
	.byte 3
		Object  -8,	 -8,	$36, 2, small
		Object   0,	 -8,	$2a, 2, small
		Object  -8,	  0,	$0a, 2, large

walk2_right:
	.byte 3
		Object  -8,	 -8,	$38, 2, small
		Object   0,	 -8,	$39, 2, small
		Object  -8,	  0,	$0c, 2, large

walk3_right:
	.byte 3
		Object  -8,	 -8,	$38, 2, small
		Object   0,	 -8,	$39, 2, small
		Object  -8,	  0,	$0e, 2, large

walk4_right:
	.byte 3
		Object  -8,	 -8,	$36, 2, small
		Object   0,	 -8,	$2a, 2, small
		Object  -8,	  0,	$20, 2, large

walk5_right:
	.byte 3
		Object  -8,	 -8,	$38, 2, small
		Object   0,	 -8,	$39, 2, small
		Object  -8,	  0,	$22, 2, large


stand_left:
	.byte 3
		Object  -8,	 -8,	$25, 2, small, hFlip
		Object   0,	 -8,	$24, 2, small, hFlip
		Object  -8,	  0,	$00, 2, large, hFlip

blink_left:
	.byte 3
		Object  -8,	 -8,	$35, 2, small, hFlip
		Object   0,	 -8,	$34, 2, small, hFlip
		Object  -8,	  0,	$00, 2, large, hFlip

jump_left:
	.byte 3
		Object  -8,	 -8,	$27, 2, small, hFlip
		Object   0,	 -8,	$26, 2, small, hFlip
		Object  -8,	  0,	$02, 2, large, hFlip

fall_left:
	.byte 3
		Object  -8,	 -8,	$37, 2, small, hFlip
		Object   0,	 -8,	$36, 2, small, hFlip
		Object  -8,	  0,	$04, 2, large, hFlip

die_left:
	.byte 3
		Object  -8,	 -8,	$29, 2, small, hFlip
		Object   0,	 -8,	$28, 2, small, hFlip
		Object  -8,	  0,	$06, 2, large, hFlip

walk0_left:
	.byte 3
		Object  -8,	 -8,	$39, 2, small, hFlip
		Object   0,	 -8,	$38, 2, small, hFlip
		Object  -8,	  0,	$08, 2, large, hFlip

walk1_left:
	.byte 3
		Object  -8,	 -8,	$2a, 2, small, hFlip
		Object   0,	 -8,	$36, 2, small, hFlip
		Object  -8,	  0,	$0a, 2, large, hFlip

walk2_left:
	.byte 3
		Object  -8,	 -8,	$39, 2, small, hFlip
		Object   0,	 -8,	$38, 2, small, hFlip
		Object  -8,	  0,	$0c, 2, large, hFlip

walk3_left:
	.byte 3
		Object  -8,	 -8,	$39, 2, small, hFlip
		Object   0,	 -8,	$38, 2, small, hFlip
		Object  -8,	  0,	$0e, 2, large, hFlip

walk4_left:
	.byte 3
		Object  -8,	 -8,	$2a, 2, small, hFlip
		Object   0,	 -8,	$36, 2, small, hFlip
		Object  -8,	  0,	$20, 2, large, hFlip

walk5_left:
	.byte 3
		Object  -8,	 -8,	$39, 2, small, hFlip
		Object   0,	 -8,	$38, 2, small, hFlip
		Object  -8,	  0,	$22, 2, large, hFlip
.endscope



.segment METASPRITE_TILE_COLLISION_HITBOXES_BLOCK
.scope THB
stand:
	TileHitbox	-4,	-6,	8,	21

fall:
	TileHitbox	-4,	-7,	8,	20

jump_right:
	TileHitbox	-6,	-7,	11,	20

die_right:
	TileHitbox	-6,	-7,	11,	19

walk_right:
	TileHitbox	-4,	-6,	9,	21

walk1_right:
	TileHitbox	-4,	-7,	9,	22


jump_left:
	TileHitbox	-5,	-7,	11,	20

die_left:
	TileHitbox	-5,	-7,	11,	19

walk_left:
	TileHitbox	-5,	-6,	9,	21

walk1_left:
	TileHitbox	-5,	-7,	9,	22


.endscope



.segment METASPRITE_FRAME_DATA_BLOCK
N_FRAMES = 22
FrameData:
	.addr	FO::stand_right, 0, THB::stand,       0, Tileset
	.addr	FO::blink_right, 0, THB::stand,       0, Tileset
	.addr	FO::jump_right,  0, THB::jump_right,  0, Tileset
	.addr	FO::fall_right,  0, THB::fall,        0, Tileset
	.addr	FO::die_right,   0, THB::die_right,   0, Tileset
	.addr	FO::walk0_right, 0, THB::walk_right,  0, Tileset
	.addr	FO::walk1_right, 0, THB::walk1_right, 0, Tileset
	.addr	FO::walk2_right, 0, THB::walk_right,  0, Tileset
	.addr	FO::walk3_right, 0, THB::walk_right,  0, Tileset
	.addr	FO::walk4_right, 0, THB::walk_right,  0, Tileset
	.addr	FO::walk5_right, 0, THB::walk_right,  0, Tileset

	.addr	FO::stand_left, 0, THB::stand,       0, Tileset
	.addr	FO::blink_left, 0, THB::stand,       0, Tileset
	.addr	FO::jump_left,  0, THB::jump_right,  0, Tileset
	.addr	FO::fall_left,  0, THB::fall,        0, Tileset
	.addr	FO::die_left,   0, THB::die_right,   0, Tileset
	.addr	FO::walk0_left, 0, THB::walk_right,  0, Tileset
	.addr	FO::walk1_left, 0, THB::walk1_right, 0, Tileset
	.addr	FO::walk2_left, 0, THB::walk_right,  0, Tileset
	.addr	FO::walk3_left, 0, THB::walk_right,  0, Tileset
	.addr	FO::walk4_left, 0, THB::walk_right,  0, Tileset
	.addr	FO::walk5_left, 0, THB::walk_right,  0, Tileset


.segment METASPRITE_FRAME_LIST_BLOCK
FrameList:
.repeat N_FRAMES, i
	.addr	FrameData + 10 * i
.endrepeat



.segment METASPRITE_FRAMESET_DATA_BLOCK
FrameSet:
	.addr	PaletteList	; paletteList
	.byte	N_PALETTES	; nPalettes
	.byte   TilesetFormat	; tilesetType
	.addr	FrameList	; frameList
	.byte	N_FRAMES	; nFrames
	.addr	0		; animationList
	.byte	0		; nAnimations


.segment METASPRITE_FRAMESET_LIST_BLOCK
    .addr	FrameSet

.endscope

; vim: set ft=asm:

