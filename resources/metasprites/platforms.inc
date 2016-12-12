
.scope Platforms

.segment METASPRITE_TILESET_BLOCK_0
N_TILES = 2
Tiles:
	; Convert to tile16 format
	.repeat N_TILES, i
		.incbin "platforms.4bpp", i * 64, 64
		.incbin "platforms.4bpp", i * 64 + 128, 64
	.endrepeat


.segment METASPRITE_DMA_TABLE_BLOCK
DmaTable0:
	.byte 0
	.faraddr	Tiles

DmaTable1:
	.byte 0
	.faraddr	Tiles + 128



.segment METASPRITE_TILESET_BLOCK
TilesetFormat = MetaSprite__FrameSet_TilesetSize::TWO_16_TILES | MetaSprite__FrameSet_TilesetLifecycle::FIXED
Tileset:
	.byte	N_TILES		; nTiles
	.addr	DmaTable0
	.addr	DmaTable1



.segment METASPRITE_PALETTE_DATA_BLOCK
Palette:
	.incbin "platforms.clr", 2, 30


.segment METASPRITE_PALETTE_LIST_BLOCK
N_PALETTES = 1
PaletteList:
	.addr	Palette



.segment METASPRITE_FRAME_OBJECTS_BLOCK
.scope FO

platform_huge:
	.byte 4
		Object   0,	  0,	$20, 2, small
		Object  40,	  0,	$20, 2, small, hFlip
		Object   8,	  0,	$00, 2, large
		Object  24,	  0,	$00, 2, large

platform_large:
	.byte 4
		Object   0,	  0,	$20, 2, small
		Object  32,	  0,	$20, 2, small, hFlip
		Object   8,	  0,	$00, 2, large
		Object  24,	  0,	$00, 2, small

platform_medium:
	.byte 3
		Object   0,	  0,	$20, 2, small
		Object  24,	  0,	$20, 2, small, hFlip
		Object   8,	  0,	$00, 2, large

platform_small:
	.byte 3
		Object   0,	  0,	$20, 2, small
		Object  16,	  0,	$20, 2, small, hFlip
		Object   8,	  0,	$00, 2, small

.endscope



.segment METASPRITE_TILE_COLLISION_HITBOXES_BLOCK
.scope THB
platform_huge:
	TileHitbox	0,	0,	48,	5

platform_large:
	TileHitbox	0,	0,	40,	5

platform_medium:
	TileHitbox	0,	0,	32,	5

platform_small:
	TileHitbox	0,	0,	24,	5

.endscope



.segment METASPRITE_FRAME_DATA_BLOCK
N_FRAMES = 4
FrameData:
	.addr	FO::platform_huge,   0, THB::platform_huge,   0, Tileset
	.addr	FO::platform_large,  0, THB::platform_large,  0, Tileset
	.addr	FO::platform_medium, 0, THB::platform_medium, 0, Tileset
	.addr	FO::platform_small,  0, THB::platform_small,  0, Tileset


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

