.ifndef ::_ENTITIES__PLATFORM_H_
::_ENTITIES__PLATFORM_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"
.include "metasprite/metasprite.h"

.include "entity.h"

.setcpu "65816"

.entitystruct PlatformEntityStruct
.endentitystruct

;; This will start a large platform at a random X location
;; and a given Y position (Init parameter)
.import PlatformEntity

;; This one will start the first platform at a constant position
.import FirstPlatformEntity

.endif

; vim: ft=asm:

