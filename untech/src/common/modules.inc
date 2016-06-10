;; modules.inc
;;
;; Macros to handle module seperation.
;;
;; Inspired by:
;;	* http://forums.nesdev.com/viewtopic.php?p=49694#p49694


.feature leading_dot_in_identifiers

.ifndef ::_COMMON__MODULES_INC_
::_COMMON__MODULES_INC_ = 1


::__MODULE_ENABLED__ .set 0
::__IMPORT_MODULE_ENABLED__ .set 0



.macro .module name
	.if ::__MODULE_ENABLED__
		.error("Cannot nest .module")
	.endif

	.define __MODULE_NAME__ .string(name)
	::__MODULE_ENABLED__ .set 1

	.scope
.endmacro

.macro .endmodule
	.if .not ::__MODULE_ENABLED__
		.error("Expected .module")
	.endif

	.endscope

	::__MODULE_ENABLED__ .set 0
	.undefine __MODULE_NAME__
.endmacro


.macro .importmodule name
	.if ::__IMPORT_MODULE_ENABLED__
		.error("Cannot nest .importmodule")
	.endif

	.define __IMPORT_MODULE_NAME__ .string(name)
	::__IMPORT_MODULE_ENABLED__ .set 1

	.scope name
.endmacro

.macro .endimportmodule
	.if .not ::__IMPORT_MODULE_ENABLED__
		.error("Expected .importmodule")
	.endif

	.endscope

	::__IMPORT_MODULE_ENABLED__ .set 0
	.undefine __IMPORT_MODULE_NAME__
.endmacro



.macro	.importroutine name
	.if ::__IMPORT_MODULE_ENABLED__
		.import .ident(.concat(__IMPORT_MODULE_NAME__, "__", .string(name)))
		name = .ident(.concat(__IMPORT_MODULE_NAME__, "__", .string(name)))
	.else
		.import name
	.endif
.endmacro


.macro	.importlabel name, access
	.if ::__IMPORT_MODULE_ENABLED__
		.ifblank access
			.import .ident(.concat(__IMPORT_MODULE_NAME__, "__", .string(name)))
			name := .ident(.concat(__IMPORT_MODULE_NAME__, "__", .string(name)))
		.else
			.import .ident(.concat(__IMPORT_MODULE_NAME__, "__", .string(name))) : access
			name := .ident(.concat(__IMPORT_MODULE_NAME__, "__", .string(name)))
		.endif
	.else
		.error "Expected .importmodule"
	.endif
.endmacro


.macro	.importconst name, access
	.importlabel name, access
.endmacro



.macro .routine name
	.if ::__MODULE_ENABLED__
		.export .ident(.concat(__MODULE_NAME__, "__", .string(name)))
		.ident(.concat(__MODULE_NAME__, "__", .string(name))):
	.else
		.export name
	.endif

	.proc name
.endmacro

.macro .endroutine
	.endproc
.endmacro


.macro	.exportlabel name, access
	.if ::__MODULE_ENABLED__
		.ifblank access
			.export .ident(.concat(__MODULE_NAME__, "__", .string(name))) := name
		.else
			.export .ident(.concat(__MODULE_NAME__, "__", .string(name))) : access := name
		.endif
	.else
		.ifblank access
			.export name
		.else
			.export name : access
		.endif
	.endif
.endmacro

.macro	.exportconst name, access
	.exportlabel name, access
.endmacro

.endif ; ::_COMMON__MODULES_INC_

; vim: ft=asm:

