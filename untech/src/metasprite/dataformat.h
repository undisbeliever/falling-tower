;; Data formats used for the metasprite system of the UnTech Engine

.ifndef ::_METASPRITE_DATAFORMAT_H_
::_METASPRITE_DATAFORMAT_H_ = 1

.struct MetaSprite__Frame
	;; Addrss of the `MetaSprite__FrameObjectsList` struct within the
	;; `METASPRITE_FRAME_OBJECTS_BLOCK` bank.
	frameObjectsList	.addr

	;; Address of the `MetaSprite__Tileset` struct within the
	;; `METASPRITE_TILESET_BLOCK` bank.
	tilesetTable		.addr

	;; Address of the `MetaSprite__EntityCollisionHitboxes` struct within the
	;; `METASPRITE_ENTITY_COLLISION_HITBOXES_BLOCK` bank.
	entityCollisionHitbox	.addr

	;; Address of the `MetaSprite__TileCollisionHitbox` struct within the
	;; `METASPRITE_TILE_COLLISION_HITBOXES_BLOCK` bank.
	tileCollisionHitbox	.addr

	;; Address of the `MetaSprite__ActionPoints` struct within the
	;; `METASPRITE_ACTION_POINT_BLOCK` bank.
	actionPoints		.addr
.endstruct


;; Represents the metasprite frames objects.
;;
;; In order to simplify processing of the metasprite frame, there are no
;; signed integers in both frame/object data structures.
;;
;; This format is designed upon the following assumptions:
;;
;;	* Each entity/frame uses only a single palette which is already
;;	  preloaded into CGRAM by the animation subsystem.
;;
;;	* The animation subsystem can allocate one or two blocks of VRAM for
;;	  each entity.
;;
;;	  By having the entity allocate one or two blocks of VRAM we prevent
;;	  fragmentation when allocating VRAM tiles for entities that need
;;	  64 tiles and 32 tiles together.
;;
;;	  To further improve VRAM allocation there are two sizes of blocks:
;;
;;		* a single 16x16 tile.
;;		* two 8x8 rows of tiles.
;;
;;	  This allows for entities with the following allocations:
;;
;;		* A single 16x16 tile
;;		* Two 16x16 tiles
;;		* Two VRAM rows (8 16x16 tiles)
;;		* Four VRAM rows. (This option should only used for bosses)
;;
;;
;;
;; The OAM properties of the sprites is calculated by:
;;	oam.xpos = entity.xPos - 128 + frameObject.xPos
;;	oam.ypos = entity.yPos - 128 + frameObject.yPos
;;	oam.size = frameObject.attr & 1
;;	if frameObject.char & 0x20 == 0:
;;		oam.charAttr = (frameObject.charAttr & 0xF01F) + entity.blockOneCharAttrOffset
;;	else:
;;		oam.charAttr = (frameObject.charAttr & 0xF01F) + entity.blockTwoCharAttrOffset

.struct MetaSprite__FrameObjectsList
	;; The number of objects
	count		.byte

	;; The objects, repeated `count` times
	.struct Objects
		;; x position of the object, relative to `origin.x - 128`
		;;
		;; unsigned 8 bit integer
		xOffset		.byte

		;; y position of the object, relative to `origin.y - 128`
		;;
		;; unsigned 8 bit integer
		yOffset		.byte

		;; character number
		;;
		;; unsigned 6 bit integer. Value must be 0 - 63
		;;
		;; 00bccccc
		;;	b     - block number (0 / 1)
		;;	ccccc - character number within block.
		char		.byte

		;; Object attributes
		;;
		;; vhoo000s
		;;	v    - vflip
		;;	h    - hflip
		;;	oo   - order (0 - 3)
		;;	s    - size (0 = small, 1 = large)
		attr		.byte
	.endstruct
.endstruct

.enum MetaSprite__Tileset_Type
	;; The tileset uses a single 16x16 tile
	ONE_16_TILE

	;; The tileset uses two 16x16 tiles
	TWO_16_TILE

	;; The tileset uses a single VRAM row of 8 16x16 tiles
	ONE_VRAM_ROW

	;; The tileset uses two VRAM rows of 8 16x16 tiles.
	TWO_VRAM_ROWS
.endenum

;; The tileset that is used by the frame (or frames).
.struct MetaSprite__Tileset
	;; The type of tile
	;; Matches `MetaSprite__Tileset_Type`
	type		.byte

	;; The bank tha contains the tiles
	bank		.byte

	;; Number of tiles to copy
	count		.byte

	;; The address of the 16x16 tile within the `bank`
	;;
	;; The tileset is arranged so that each of the 4 tiles
	;; are one after another.
	;;
	;; Repeated count times
	tileAddress	.word
.endstruct


;; The hitbox of the entity, used by the physics engine for entity
;; collisions.
;;
;; The collision hitbox is represented by multiple Axis-Aligned
;; Bounding Boxes, each of a different type.
;;
;; The type is dependant of the implementation code, but allows for
;; flexibility in defining different collision areas on a frame.
;;
;; For example, an enemy frame could consist of:
;;
;;	* a sword AABB (the part the hurts the player)
;;	* a shield AABB (the part where no damage would occur if hit)
;;	* a weak-point AABB (where double damage would occur if hit)
;;	* a body AABB (where normal damage would occur if hit)
;;
;;
;; In order to save processing an "outer" hitbox is used. This hitbox
;; is tested first, then only if that hits, will the inner hitboxes
;; be tested.
;;
;; Some hitboxes only involve one AABB. In this case count is 0 and
;; the outer hitbox is checked.

.struct MetaSprite__EntityCollisionHitboxes
	;; The outer hitbox
	.struct Outer
		;; xOffset of the hitbox, relative to `origin.x - 128`
		;;
		;; unsigned 8 bit integer
		xOffset		.byte

		;; yOffset of the hitbox, relative to `origin.y - 128`
		;;
		;; unsigned 8 bit integer
		yOffset		.byte

		;; Width of the hitbox
		;;
		;; unsigned 8 bit integer
		width		.byte

		;; Width of the hitbox
		;;
		;; unsigned 8 bit integer
		height		.byte
	.endstruct

	;; Number of inner hitboxes used by the entity.
	;;
	;; If zero then only the outer hitbox is checked, the inner hitboxes
	;; are not processed
	;;
	;; unsigned 8 bit integer
	count		.byte

	.union
		.struct SingleHitbox
			;; The type of outer hitbox
			;;
			;; It is processed ONLY if count is 0.
			;;
			;; The format/value of this parameter depends on the entity
			;; and is parsed by the entity's update routine.
			OuterHitboxType		.byte

			;; The parameter for the outer hitbox type
			;;
			;; It is processed ONLY if count is 0.
			;;
			;; The format/value of this parameter depends on the
			;; entity and hitbox type and is parsed by the entity's update routine
			parameter	.byte
		.endstruct

		;; The inner hitboxes, repeated `count` times
		;;
		;; All inner hitboxes MUST be inside the outer hitbox.
		.struct Inner
			;; xOffset of the hitbox, relative to `origin.x - 128`
			;;
			;; unsigned 8 bit integer
			xOffset		.byte

			;; yOffset of the hitbox, relative to `origin.y - 128`
			;;
			;; unsigned 8 bit integer
			yOffset		.byte

			;; Width of the hitbox
			;;
			;; unsigned 8 bit integer
			width		.byte

			;; Width of the hitbox
			;;
			;; unsigned 8 bit integer
			height		.byte

			;; The type of hitbox
			;;
			;; The format/value of this parameter depends on the
			;; entity and is parsed by the entity's update routine
			type		.byte

			;; The parameter for the hitbox type
			;;
			;; The format/value of this parameter depends on the
			;; entity and hitbox type and is parsed by the entity's update routine
			parameter	.byte
		.endstruct
	.endunion
.endstruct


;; A hitbox of the entity, used by the physics engine for collisions
;; with the meta-tilemap.
;;
;; For the moment the engine only supports a single AABB hitbox.

; ::SHOULDO handle a more complex hitboxes::

.struct MetaSprite__TileCollisionHitbox
	;; xOffset of the hitbox, relative to `origin.x - 128`
	;;
	;; unsigned 8 bit integer
	xOffset		.byte

	;; yOffset of the hitbox, relative to `origin.y - 128`
	;;
	;; unsigned 8 bit integer
	yOffset		.byte

	;; Width of the hitbox
	;;
	;; unsigned 8 bit integer
	width		.byte

	;; Width of the hitbox
	;;
	;; unsigned 8 bit integer
	height		.byte
.endstruct


;; Action points used by the metasprite animation engine
;;
;; This is used by the animator to tell the game-loop
;; when to preform certain actions.
;;
;; Action points only occur for one frame. On the next processing frame the
;; pointer to the ActionPoints data location is reset to NULL.
;;
;; Examples of action points include:
;;	* Fire weapon frame - would includes the position and direction
;;	  of the projectile launched
;;	* Feed touching ground - used for run/walk sounds.
;;
;;
;; The location of the action point is calculated in the same manner as the
;; metasprite frames.
;;
;;	xPos = entity.xPos - actionPoints.xOffset + point.xPos
;;	yPos = entity.yPos - actionPoints.yOffset + point.yPos

.struct MetaSprite__ActionPoints
	;; The number of action points
	;;
	;; 8 bit signed integer
	count		.byte

	.struct Point
		;; The type of action point
		;;
		;; The format/value of this parameter depends on the entity
		;; code and is parsed by the entity's update routine.
		type		.byte

		;; The parameter of the action point
		;;
		;; The format/value of this parameter depends on the entity
		;; and/or type and is parsed by the entity's update routine.
		parameter	.byte

		;; xPos of the point, relative to `origin.x - 128`
		;;
		;; 8 bit signed integer
		xPos		.byte

		;; yPos of the point, relative to `origin.x - 128`
		;;
		;; 8 bit signed integer
		yPos		.byte
	.endstruct
.endstruct

.endif ; ::_METASPRITE_DATAFORMAT_H_

; vim: set ft=asm:

