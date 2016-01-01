
.include "metasprite/metasprite.h"


;; Preform a collision check between the current entity and all of the platforms
;; in the *platform entity list*
;;
;; Collision occurs between the MetaSprite__TileCollisionHitbox of the entity and
;; the platform list.
;;
;; When a collision occurs, the platform->`StandPlatformFunction` will be called with the
;; following state:
;;
;;	REGISTERS: 16 bit A, 16 bit Index, DB = $7E
;;	DP = platform
;;	 A = entity that was previously on the platform
;;	 Y = tileCollisionHitbox address
;;	 X = platform functionPtr
;;	 Entity::tch_ = tile collision hitbox of the entity
;;	 Entity::previousYpos = the yPos of the entity before processing
;;
;;
;; If the entity was on a platform in the previous frame but not on the platform in
;; this frame then platform->`LeavePlatformFunction` function will be called in the
;; following state:
;;
;;	REGISTERS: 16 bit A, 16 bit Index, DB = $7E
;;	DP = platform
;;	 Y = entity that touched the platform
;;	 X = platform functionPtr
;;	 Entity::tch_ = tile collision hitbox of the entity
;;	 Entity::previousYpos = the yPos of the entity before processing
;;
;; REQUIRES: 16 bit A, 16 bit Index, DB = $7E
;; INPUT: DP = entity to check, MUST NOT be in the platform list
;;
;; PARAM: PlatformFunctionToCall - the function to call when the entity touches a platform
.macro CheckPlatformCollisions StandPlatformFunction, LeavePlatformFunction
	.local Return, ReturnJump, NoCollision, SkipEntity
	.local tmp, tmp_standingOnPlatform

	tmp = collisionTmp1
	tmp_standingOnPlatform = collisionTmp2


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

		LDA	z:EntityStruct::standingOnPlatform
		STA	tmp_standingOnPlatform

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

			; Collision check code:
			;
			; platform_tch = platform->metasprite->frame->tileCollisionHitbox
			; platform_Left = (platform_tch->yOffset & 0xFF) + platform->xPos - 1
			;
			; if platform_Left < entity.tch_left
			;	tmp = (platform_tch->width & 0xFF) + platform_Left
			;	if tmp < entity.tch_left
			;		goto noCollision
			; else
			;	tmp = platform_Left - entity.tch_width
			;	if tmp >= entity.tch_left
			;		goto NoCollision
			;

			; Check Y collision first, more likely to miss
			;
			; The Y axis is offsetted by 1 pixel in order to ensure that the collision
			; is successful when the entity is pushed ontop of the platform.

			LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::yOffset, X
			AND	#$00FF
			CLC		; -1
			SBC	#MetaSprite::POSITION_OFFSET
			CLC
			ADC	z:EntityStruct::yPos + 1

			CMP	Entity::tch_top
			IF_LT
				STA	tmp

				LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::height, X
				AND	#$00FF
				; C clear
				ADC	tmp

				CMP	Entity::tch_top
				BLT	NoCollision
			ELSE

				; No signed comparison, camera left will always be > platform width
				; C set
				SBC	Entity::tch_height

				CMP	Entity::tch_top
				BGE	NoCollision
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
				STA	tmp

				LDA	f:tileCollisionDataOffset + MetaSprite__TileCollisionHitbox::width, X
				AND	#$00FF
				; C clear
				ADC	tmp

				CMP	Entity::tch_left
				BLT	NoCollision
			ELSE

				; No signed comparison, camera left will always be > platform width
				; C set
				SBC	Entity::tch_width

				CMP	Entity::tch_left
				BGE	NoCollision
			ENDIF

			; Collision occurs, call routine
				LDA	1, s
				TXY

				LDX	z:EntityStruct::functionPtr
				JSR	(StandPlatformFunction, X)

SkipEntity:
				LDA	z:EntityStruct::nextPtr
				BNE	CONTINUE_LABEL
				BRA	BREAK_LABEL

NoCollision:
			; No Collision Occurs, check to see if entity was on the platform
			TDC
			CMP	tmp_standingOnPlatform
			IF_EQ
				LDA	1, s
				TAY

				LDX	z:EntityStruct::functionPtr
				JSR	(LeavePlatformFunction, X)
			ENDIF

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

