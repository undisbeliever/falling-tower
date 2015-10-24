;; config.inc
;;
;; Handles configurable variables that can be overridden with a project's
;; `config.h` file.
;;
;; This module uses a '.define' to define configs because I get an
;; "Error: Constant expression expected" error when using a constant variable
;; with a `.res` statement.
;;
;; This means that default must be a simple integer, not an equation or a label


.ifndef ::_COMMON__CONFIG_INC_
::_COMMON__CONFIG_INC_ = 1

.include "config.h"

;; Creates a .define called FPS with a value of either 60 or 50
;; depending on the state of the REGION flag

.if .xmatch(REGION, NTSC)
	.define FPS 60
.elseif .xmatch(REGION, PAL)
	.define FPS 50
.else
	.error "Unkown Region"
.endif

;; Handles a configurable .define.
;;
;; If the system detects that the .define does not exist (ie, it resolves to something
;; that is a symbol) it will either:
;;	* Creates a .define macro with a value of `default` (if it doesn't exist)
;;	* Error out, asking for the .define name.
;;
;; NOTE: Due to the way ca65 tokenizes this macro cannot test if define exists,
;;       it tests by type instead. Thus default must not be a label.
;;
;; PARAM: name - the name of the .define
;;        default (MUST be a fixed integer) - can be blank
.macro CONFIG name, default
	.if .match(name, __UNKOWN_LABEL__)
		.ifblank default
			.error .sprintf("Require `%s` config .define ", .string(name))
		.else
			.define name default
		.endif
	.endif
.endmacro

;; Handles a configurable .define that has a value within a given range
;;
;; If the system detects that the .define does not exist (ie, it resolves to something
;; that is a symbol) it will either:
;;	* Creates a .define macro with a value of `default` (if it doesn't exist)
;;	* Error out, asking for the .define name.
;;
;; NOTE: Due to the way ca65 tokenizes this macro cannot test if define exists,
;;       it tests by type instead. Thus default must not be a label.
;;
;; PARAM: name - the name of the .define
;;        default (MUST be a fixed integer) - can be blank
;;        min - minimum valid value
;;        max - maximum valid value
.macro CONFIG_RANGE name, default, min, max
	.if .match(name, __UNKOWN_LABEL__)
		.ifblank default
			.error .sprintf("Require `%s` config .define ", .string(name))
		.else
			.define name default
		.endif
	.endif

	.assert name >= (min) .and name <= (max), error, .sprintf("%s out of range (%i - %i)", .string(name), min, max)
.endmacro

.endif ; _COMMON__CONFIG_INC_

; vim: ft=asm:

