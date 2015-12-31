
.include "metasprite/metasprite.h"


;; Preform a collision check between the current entity and all of the platforms
;; in the *platform entity list*
;;
;; Collision occurs between the MetaSprite__TileCollisionHitbox of the entity and
;; the platform list.
;;
;; When a collision occurs, the `PlatformFunctionToCall` will be called with the
;; following state:
;;
;;	REGISTERS: 16 bit A, 16 bit Index, DB = $7E
;;	DP = platform
;;	 A = entity that touched the platform
;;	 Y = tileCollisionHitbox address
;;	 X = platform functionPtr
;;	 Entity::tch_ = tile collision hitbox of the entity
;;
;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
;; INPUT: DP = entity to check, MUST NOT be in the platform list
;;
;; PARAM: PlatformFunctionToCall - the function to call when the entity touches a platform
.macro CheckPlatformCollisions PlatformFunctionToCall
	.local Return, ReturnJump, SkipEntity

	LDX	z:EntityStruct::metasprite + MetaSpriteStruct::currentFrame
	IF_ZERO
ReturnJump:
		JMP	Return
	ENDIF

	; Check if platforms exist and the entity has a tileCollision hitbox

	LDY	platformEntityLList
	BEQ	ReturnJump

	LDA	f:frameDataOffset + MetaSprite__Frame::tileCollisionHitbox, X
	BEQ	ReturnJump
	TAX

		; Save the tile collision hitbox data for the given entity
		; This saves processing time and allows the data to be accessed by
		; the `PlatformFunctionToCall` routine.

		LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::xOffset, X
		AND	#$00FF
		SEC
		SBC	#MetaSprite::POSITION_OFFSET
		STA	Entity::tch_xOffset
		CLC
		ADC	z:EntityStruct::xPos + 1
		STA	Entity::tch_left

		LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::yOffset, X
		AND	#$00FF
		SEC
		SBC	#MetaSprite::POSITION_OFFSET
		STA	Entity::tch_yOffset
		CLC
		ADC	z:EntityStruct::yPos + 1
		STA	Entity::tch_top

		LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::width, X
		AND	#$00FF
		STA	Entity::tch_width

		LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::height, X
		AND	#$00FF
		STA	Entity::tch_height


		; Loop through entities

		PHD
		TYA
		REPEAT
			TCD

			LDX	z:EntityStruct::metasprite + MetaSpriteStruct::currentFrame
			BEQ	SkipEntity

			LDA	f:frameDataOffset + MetaSprite__Frame::tileCollisionHitbox, X
			BEQ	SkipEntity
			TAX


			; Check Y collision first, more likely to miss

			; Collision check code:
			;
			; platform_tch = platform->metasprite->frame->tileCollisionHitbox
			; platform_Top = (platform_tch->yOffset & 0xFF) + platform->yPos
			;
			; if platform_Top < entity.tch_top
			;	collisionTmp = (platform_tch->height & 0xFF) + platform_Top
			;	if collisionTmp < entity.tch_top
			;		goto noCollision
			; else
			;	collisionTmp = platform_Top - entity.tch_height
			;	if collisionTmp >= entity.tch_top
			;		goto NoCollision
			;

			LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::yOffset, X
			AND	#$00FF
			SEC
			SBC	#MetaSprite::POSITION_OFFSET
			CLC
			ADC	z:EntityStruct::yPos + 1

			CMP	Entity::tch_top
			IF_LT
				STA	collisionTmp

				LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::height, X
				AND	#$00FF
				; C clear
				ADC	collisionTmp

				CMP	Entity::tch_top
				BLT	SkipEntity
			ELSE

				; No signed comparison, camera left will always be > platform width
				; C set
				SBC	Entity::tch_height

				CMP	Entity::tch_top
				BGE	SkipEntity
			ENDIF


			; Check X collision

			LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::xOffset, X
			AND	#$00FF
			SEC
			SBC	#MetaSprite::POSITION_OFFSET
			CLC
			ADC	z:EntityStruct::xPos + 1

			CMP	Entity::tch_left
			IF_LT
				STA	collisionTmp

				LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::width, X
				AND	#$00FF
				; C clear
				ADC	Entity::tch_left

				CMP	Entity::tch_left
				BLT	SkipEntity
			ELSE

				; No signed comparison, camera left will always be > platform width
				; C set
				SBC	Entity::tch_width

				CMP	Entity::tch_left
				BGE	SkipEntity
			ENDIF

			; Collision occurs

			LDA	1, s
			TXY

			LDX	z:EntityStruct::functionPtr
			JSR	(PlatformFunctionToCall, X)

SkipEntity:
			LDA	z:EntityStruct::nextPtr
		UNTIL_ZERO

		PLD

	; end if
Return:
.endmacro


.pushseg

.segment METASPRITE_FRAME_DATA_BLOCK
	frameDataOffset = .bankbyte(*) << 16

.segment METASPRITE_TILE_COLLISION_HITBOXES_BLOCK
	tileCollisionDataOffset = .bankbyte(*) << 16

.popseg

; vim: set ft=asm:

