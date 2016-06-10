; Unit tests

.include "tests.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "common/console.h"
.include "font.h"

.setcpu "65816"

.segment "SHADOW"
	moduleTablePos:		.res 2
	headerPos:		.res 2
	functionStringPtr:	.res 2
	previousCursor:		.res 2

	_Tests_tmp1:		.res 2
	_Tests_tmp2:		.res 2
	_Tests_tmp3:		.res 2
	_Tests_tmp4:		.res 2
	_Tests_tmp5:		.res 2
	_Tests_tmp6:		.res 2

.code

.import __TEST_MODULE_TABLE_SIZE__
.import __TEST_MODULE_TABLE_LOAD__

TestModuleTable := __TEST_MODULE_TABLE_LOAD__

.routine RunTests
	REP	#$30
	SEP	#$20
.A8
.I16
	LDA	#$80
	PHA
	PLB

	JSR	Console::Init

	LDA	#Font::MAGENTA
	JSR	Console::SetColor

	CPrintStringLn "Untech Unit Tests"

	LDX	#0
	REPEAT
		REP	#$30
.A16
.I16
		STX	moduleTablePos

		LDA	f:TestModuleTable, X
		TAX

		LDA	f:rodataBank << 16 + UnitTestModuleHeader::name, X
		PHA


		INX
		INX
		STX	headerPos

		SEP	#$20
.A8
		LDA	#Font::BLUE
		JSR	Console::SetColor

		JSR	Console::NewLine
		JSR	Console::NewLine

		LDA	#stringBank
		PLX
		JSR	Console::PrintString

		REPEAT
			REP	#$30
.A16
			LDX	headerPos
			LDA	f:rodataBank << 16 + UnitTestRoutineHeader::name, X

		WHILE_NOT_ZERO
			STA	functionStringPtr

			SEP	#$20
.A8
			LDA	#Font::BLACK
			JSR	Console::SetColor

			JSR	Console::NewLine
			LDA	#' '
			JSR	Console::PrintChar
			LDA	#' '
			JSR	Console::PrintChar

			LDX	Console::cursor
			STX	previousCursor

			LDA	#stringBank
			LDX	functionStringPtr
			JSR	Console::PrintString

			LDX	headerPos
			JSR	(UnitTestRoutineHeader::routinePtr, X)

			; Reset asize, isize, DP, DB, all status except C
			REP	#$FE
.A16
			LDA	#0
			TCD

			SEP	#$24
.A8
.I16
			LDA	#$80
			PHA
			PLB

			LDX	previousCursor
			STX	Console::cursor

			IF_C_CLEAR
				LDA	#Font::RED
				JSR	Console::SetColor

				LDA	#stringBank
				LDX	functionStringPtr
				JSR	Console::PrintString

				; ::TODO print address of routine for debugging purposes::
				REPEAT
				FOREVER
			ELSE
				LDA	#Font::GREEN
				JSR	Console::SetColor

				LDA	#stringBank
				LDX	functionStringPtr
				JSR	Console::PrintString
			ENDIF

			REP	#$31		; include carry for ADC
.A16
			LDA	headerPos
			ADC	#4
			STA	headerPos
		WEND

		SEP	#$20
.A8

		LDX	moduleTablePos
		INX
		INX
		CPX	#__TEST_MODULE_TABLE_SIZE__
	UNTIL_GE


	LDA	#Font::MAGENTA
	JSR	Console::SetColor

	JSR	Console::NewLine
	JSR	Console::NewLine
	CPrintString "Unit Tests Complete"

	RTS
.endroutine


.rodata
	rodataBank = .bankbyte(*)

.segment TEST_STRING_BANK
	stringBank = .bankbyte(*)

; vim: set ft=asm:

