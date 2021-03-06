.ifndef ::_ENTITIES__PLATFORMS_H_
::_ENTITIES__PLATFORMS_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"
.include "metasprite/metasprite.h"

.include "entity.h"

.setcpu "65816"

.enum	PlatformEntityFunctions
	Init			= 0
	ProcessFrame		= 2

	;; Called when an entity touches the platform
	;;
	;; Should set EntityStruct::standingOnPlatform to DP if the
	;; entity is actually standing on the platform
	;;
	;; REGISTERS: 16 bit A, 16 bit Index, DB = $7E
	;; INPUT: DP = platform
	;;	   Y = entity that touched the platform
	;;	   A = tileCollisionHitbox address of the platform
	;;	   X = platform functionPtr
	;;	   Entity::tch_ = tile collision hitbox of the entity
	;;	   Entity::previousYpos = the yPos of the entity before frame processing
	EntityTouchPlatform	= 4

	;; Called when an entity leaves the platform
	;;
	;; Should clear EntityStruct::platform.
	;;
	;; REGISTERS: 16 bit A, 16 bit Index, DB = $7E
	;; INPUT: DP = platform
	;;	   Y = entity that was previously on the platform
	;;	   X = platform functionPtr
	;;	   Entity::tch_ = tile collision hitbox of the entity
	;;	   Entity::previousYpos = the yPos of the entity before frame processing
	EntityLeavePlatform	= 6
.endenum

.entitystruct PlatformEntityStruct
.endentitystruct


.importmodule PlatformEntities
	HUGE_WIDTH	= 48
	LARGE_WIDTH	= 40
	MEDIUM_WIDTH	= 32
	SMALL_WIDTH	= 24

	FIRST_START_X	= (256 - HUGE_WIDTH) / 2
	FIRST_START_Y	= 200

	.importlabel HugePlatformEntity
	.importlabel LargePlatformEntity
	.importlabel MediumPlatformEntity
	.importlabel SmallPlatformEntity

	;; This one will start the first platform at a constant position
	.importlabel FirstPlatformEntity
.endimportmodule

.endif

; vim: ft=asm:

