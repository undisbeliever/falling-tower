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

.import PlatformEntity

.endif

; vim: ft=asm:

