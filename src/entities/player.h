.ifndef ::_ENTITIES__PLAYER_H_
::_ENTITIES__PLAYER_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"
.include "metasprite/metasprite.h"

.include "entity.h"

.setcpu "65816"

.entitystruct PlayerEntityStruct
.endentitystruct

.import PlayerEntity

.endif

; vim: ft=asm:

