.ifndef ::_ENTITIES__PLATFORM_H_
::_ENTITIES__PLATFORM_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"
.include "metasprite/metasprite.h"

.include "entity.h"

.setcpu "65816"

.enum	PlatformEntityFunctions
	; ::SHOULDO clean up::
	Init			= 0
	ProcessFrame		= 2

	;; Called when an entity touches the platform
	;;
	;; Should set EntityStruct::standingOnPlatform to DP if the
	;; entity is actually standing on the platform
	;;
	;; REGISTERS: 16 bit A, 16 bit Index, DB = $7E
	;; INPUT: DP = platform
	;;	   A = entity that touched the platform
	;;	   Y = tileCollisionHitbox address of the platform
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

;; This will start a large platform at a random X location
;; and a given Y position (Init parameter)
.import PlatformEntity

;; This one will start the first platform at a constant position
.import FirstPlatformEntity

.endif

; vim: ft=asm:

