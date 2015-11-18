; Unit test Metasprite render routine

.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "metasprite/metasprite.h"

.include "tests/tests.h"
.include "tests/static-random.inc"
.include "tests/metasprite/metasprite.h"

.setcpu "65816"

.module UnitTest_MetaSprite_Render

	UnitTestHeader MetaSprite_Render
		UnitTest	RenderFrame_Nothing
		UnitTest	RenderFrame_NULL
		UnitTest	RenderFrame_OneSmall
		UnitTest	RenderFrame_OneLarge
		UnitTest	RenderFrame_Multiple
		UnitTest	RenderFrame_BlockTwo
		UnitTest	RenderFrame_HiTable1
		UnitTest	RenderFrame_HiTable2
		UnitTest	RenderFrame_HiTable3
		UnitTest	RenderFrame_XMinus
		UnitTest	RenderFrame_Offscreen
		UnitTest	RenderFrame_Overflow
		UnitTest	RenderLoopEnd
	EndUnitTestHeader


oamBuffer	:= .loword(MetaSprite::oamBuffer)
oamHiBuffer	:= .loword(MetaSprite::oamBuffer) + 4 * 128
entity		:= UnitTest_MetaSprite::entities

.define MSDP ExampleEntity::metasprite + MetaSpriteStruct

.code


; Test that rendering NULL does nothing
.A8
.I16
.routine RenderFrame_Nothing
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	MetaSprite::RenderLoopInit
	JSR	MetaSprite::RenderLoopEnd

	; Ensure objects are offscreen
	LDX	#0
	JMP	_TestRestOfBuffer
.endroutine


; Test that rendering NULL does nothing
.A8
.I16
.routine RenderFrame_NULL
	JSR	_Init
.A16
.I16
	LDA	#.loword(Frame_NullObject)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	STZ	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd

	; Ensure there are no objects on screen
	LDX	#0
	JMP	_TestRestOfBuffer
.endroutine



.A8
.I16
.routine RenderFrame_OneSmall
	JSR	_Init
.A16
.I16
	LDA	#.loword(Frame_OneSmall)
	STA	z:MSDP::currentFrame

	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd

	; Ensure object buffer has correct data
	LDA	oamBuffer
	CMP	f:Frame_OneSmall_Expected
	BNE	Failure

	LDA	oamBuffer + 2
	CMP	f:Frame_OneSmall_Expected + 2
	BNE	Failure

	; Ensure object is small
	LDA	oamHiBuffer
	AND	#%11
	BNE	Failure

	LDX	#4
	JSR	_TestRestOfBuffer
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine RenderFrame_OneLarge
	JSR	_Init
.A16
.I16
	LDA	#.loword(Frame_OneLarge)
	STA	z:MSDP::currentFrame

	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd

	; Ensure object buffer has correct data
	LDA	oamBuffer
	CMP	f:Frame_OneLarge_Expected
	BNE	Failure

	LDA	oamBuffer + 2
	CMP	f:Frame_OneLarge_Expected + 2
	BNE	Failure

	; Ensure object is large
	LDA	oamHiBuffer
	AND	#%11
	CMP	#%10
	BNE	Failure

	LDX	#4
	JSR	_TestRestOfBuffer
	RTS

Failure:
	CLC
	RTS
.endroutine


; Render frame object lists that contain more than one sprite
.A8
.I16
.routine RenderFrame_Multiple
	JSR	_Init
.A16
.I16
	LDA	#.loword(Frame_Multiple0)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	LDA	#.loword(Frame_Multiple1)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd


	; Test hi Buffer
	LDA	oamHiBuffer
	AND	#FrameObjects_Multiple_ExpectedHi_Bitmask
	CMP	f:FrameObjects_Multiple_ExpectedHi
	BNE	Failure


	; Test oamBuffer
	LDX	#0
	REPEAT
		LDA	oamBuffer, X
		CMP	f:FrameObjects_Multiple_Expected, X
		BNE	Failure

		INX
		INX
		CPX	#FrameObjects_Multiple_Expected_size
	UNTIL_GE

	JSR	_TestRestOfBuffer
	RTS

Failure:
	CLC
	RTS
.endroutine


; Render frame object lists that 2 use blocks
.A8
.I16
.routine RenderFrame_BlockTwo
	JSR	_Init
.A16
.I16
	LDA	#Test_BlockTwo_CharAttr1
	STA	z:MSDP::blockOneCharAttrOffset
	LDA	#Test_BlockTwo_CharAttr2
	STA	z:MSDP::blockTwoCharAttrOffset

	LDA	#.loword(Frame_Multiple0)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	LDA	#.loword(Frame_Multiple1)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd


	; Test hi Buffer
	LDA	oamHiBuffer
	AND	#FrameObjects_Multiple_ExpectedHi_Bitmask
	CMP	f:FrameObjects_Multiple_ExpectedHi
	BNE	Failure


	; Test oamBuffer
	LDX	#0
	REPEAT
		LDA	oamBuffer, X
		CMP	f:FrameObjects_Render_BlockTwo_Expected, X
		BNE	Failure

		INX
		INX
		CPX	#FrameObjects_Render_BlockTwo_Expected_size
	UNTIL_GE

	JSR	_TestRestOfBuffer
	RTS

Failure:
	CLC
	RTS
.endroutine

; Tests that the hiTable renders correctly with 8 entities in play
.A8
.I16
.routine RenderFrame_HiTable1
	JSR	_Init
.A16
.I16
	LDA	#.loword(Frame_OneSmall)
	STA	z:MSDP::currentFrame

	JSR	MetaSprite::RenderFrame
	JSR	MetaSprite::RenderFrame

	LDA	#.loword(Frame_OneLarge)
	STA	z:MSDP::currentFrame

	JSR	MetaSprite::RenderFrame
	JSR	MetaSprite::RenderFrame
	JSR	MetaSprite::RenderFrame

	LDA	#.loword(Frame_OneSmall)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame
	JSR	MetaSprite::RenderFrame

	LDA	#.loword(Frame_OneLarge)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd

	; Ensure hitable is correct
	LDA	oamHiBuffer
	CMP	#(%10 << (2 * 2)) | (%10 << (3 * 2)) | (%10 << (4 * 2)) | (%10 << (7 * 2))
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


; Tests that the hiTable renders correctly with 24 + 2 metasprites in play
.A8
.I16
.routine RenderFrame_HiTable2
	JSR	_Init
.A16
.I16
	LDA	#.loword(Frame_Four)
	STA	z:MSDP::currentFrame

	LDA	#24 / 4
	STA	tmp1

	REPEAT
		JSR	MetaSprite::RenderFrame
		DEC	tmp1
	UNTIL_ZERO

	LDA	#.loword(Frame_OneLarge)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	LDA	#.loword(Frame_OneSmall)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd


	SEP	#$20
.A8
	; Ensure hitable is correct
	LDX	#0
	LDA	f:FrameObjects_Four_ExpectedHi
	REPEAT
		CMP	oamHiBuffer, X
		BNE	Failure

		INX
		CPX	#24 / 4
	UNTIL_GE

	LDA	oamHiBuffer, X
	AND	#%1111
	CMP	#%0010
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


; Tests that the hiTable renders correctly with 127 metasprites in play
.A8
.I16
.routine RenderFrame_HiTable3
	JSR	_Init
.A16
.I16
	LDA	#.loword(Frame_OneSmall)
	STA	z:MSDP::currentFrame

	LDA	#127 - 2
	STA	tmp1

	REPEAT
		JSR	MetaSprite::RenderFrame
		DEC	tmp1
	UNTIL_ZERO

	LDA	#.loword(Frame_OneLarge)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd

	SEP	#$20
.A8
	; Ensure hitable is correct
	LDX	#0
	REPEAT
		LDA	oamHiBuffer, X
		BNE	Failure

		INX
		CPX	#127 / 4
	UNTIL_GE

	LDA	oamHiBuffer, X
	AND	#$3F
	CMP	#%101000
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


; Tests the rendering of an image when X is negative but on screen
.A8
.I16
.routine RenderFrame_XMinus
	JSR	_Init
.A16
.I16
	LDA	#.loword(-small_xPos - 4 - MetaSprite::POSITION_OFFSET)
	STA	MetaSprite::xPos

	LDA	#.loword(Frame_OneSmall)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame


	LDA	#.loword(-large_xPos - 12 - MetaSprite::POSITION_OFFSET)
	STA	MetaSprite::xPos

	LDA	#.loword(Frame_OneLarge)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd


	; Ensure xPos is correct
	SEP	#$20
.A8
	LDA	oamBuffer + OamFormat::xPos
	CMP	#.lobyte(-4)
	BNE	Failure

	LDA	oamBuffer + OamFormat::xPos + .sizeof(OamFormat)
	CMP	#.lobyte(-12)
	BNE	Failure

	; Ensure object1 is small and with 9th x bit set
	; Ensure object2 is large and with 9th x bit set
	LDA	oamHiBuffer
	AND	#%1101
	CMP	#%1101
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine



; Tests the rendering of an image when offscreen
.A8
.I16
.routine RenderFrame_Offscreen
	JSR	_Init
.A16
.I16
	LDA	#.loword(offscreen0_xPos - MetaSprite::POSITION_OFFSET)
	STA	MetaSprite::xPos

	LDA	#.loword(offscreen0_yPos - MetaSprite::POSITION_OFFSET)
	STA	MetaSprite::yPos

	LDA	#.loword(Frame_Offscreen0)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	LDA	#.loword(offscreen1_xPos - MetaSprite::POSITION_OFFSET)
	STA	MetaSprite::xPos

	LDA	#.loword(offscreen1_yPos - MetaSprite::POSITION_OFFSET)
	STA	MetaSprite::yPos

	LDA	#.loword(Frame_Offscreen1)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd


	; Test hi Buffer
	LDA	oamHiBuffer
	AND	#FrameObjects_Offscreen_ExpectedHi_Bitmask
	CMP	f:FrameObjects_Offscreen_ExpectedHi
	BNE	Failure


	; Test oamBuffer
	LDX	#0
	REPEAT
		LDA	oamBuffer, X
		CMP	f:FrameObjects_Offscreen_Expected, X
		BNE	Failure

		INX
		INX
		CPX	#FrameObjects_Offscreen_Expected_size
	UNTIL_GE

	JSR	_TestRestOfBuffer
	RTS

Failure:
	CLC
	RTS
.endroutine



; Tests that overflowing the buffer does not crash the game
.A8
.I16
.routine RenderFrame_Overflow
	JSR	_Init
.A16
.I16
	LDA	#.loword(Frame_Four)
	STA	z:MSDP::currentFrame

	LDA	#90
	STA	tmp1
	REPEAT
		JSR	MetaSprite::RenderFrame
		DEC	tmp1
	UNTIL_ZERO

	JSR	MetaSprite::RenderLoopEnd


	SEP	#$20
.A8
	; Test hi Buffer is not overridden
	LDA	oamHiBuffer + 127/4
	CMP	f:FrameObjects_Four_ExpectedHi
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine



; Tests that rendering 3 objects after rendering 12 objects works correctly
.A8
.I16
.routine RenderLoopEnd
	JSR	_Init
.A16
.I16
	LDA	#.loword(Frame_Multiple0)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	LDA	#.loword(Frame_Multiple1)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd

	; New frame - 3 objects
	JSR	MetaSprite::RenderLoopInit

	LDA	#.loword(Frame_OneLarge)
	STA	z:MSDP::currentFrame
	JSR	MetaSprite::RenderFrame
	JSR	MetaSprite::RenderFrame
	JSR	MetaSprite::RenderFrame

	JSR	MetaSprite::RenderLoopEnd

	; Test that sprites 3-127 are offscreen

	LDX	#3 * 4
	JSR	_TestRestOfBuffer
	BCC	Failure

	; New frame - only 0 objects
	JSR	MetaSprite::RenderLoopInit
	JSR	MetaSprite::RenderLoopEnd

	; Test that all sprites are offscreen

	LDX	#0
	JSR	_TestRestOfBuffer
	RTS

Failure:
	CLC
	RTS
.endroutine



;; Initialize the test
;;	Reset system
;; 	Start render loop
;;	Reset xpos, ypos, charattr to zero
;;	sets dp to entity
;;	A16, I16
.routine _Init
	JSR	UnitTest_MetaSprite::Reset
.A16
.I16
	JSR	MetaSprite::RenderLoopInit

	LDA	#.loword(0 - MetaSprite::POSITION_OFFSET)
	STA	MetaSprite::xPos

	LDA	#.loword(0 - MetaSprite::POSITION_OFFSET)
	STA	MetaSprite::yPos

	LDA	#entity
	TCD

	STZ	z:MSDP::blockOneCharAttrOffset
	STZ	z:MSDP::blockTwoCharAttrOffset

	RTS
.endroutine


;; Tests that the oamBuffer is cleared
;; IN: X = buffer position
;; OUT: C set on success
.A16
.I16
.routine _TestRestOfBuffer
	LDA	#0

	SEP	#$20
.A8
	; Check that the position of the sprites positions is >= 224
	REPEAT
		LDA	oamBuffer + OamFormat::yPos, X
		CMP	#224
		BLT	Failure

		INX
		INX
		INX
		INX
		CPX	#128 * .sizeof(OamFormat)
	UNTIL_GE

	; Don't worry about the hi table
	REP	#$30
.A16
	; C set by CPX
	RTS

Failure:
	REP	#$31
.A16
	; Carry clear
	RTS
.endroutine


.segment METASPRITE_FRAME_DATA_BLOCK
	; Only need to show MetaSprite__Frame::frameObjectsList
	; None of the other data is accessed

Frame_NullObject:
	.addr	0

Frame_OneSmall:
	.addr	FrameObjects_OneSmall

Frame_OneLarge:
	.addr	FrameObjects_OneLarge

Frame_Multiple0:
	.addr	FrameObjects_Multiple0

Frame_Four:
Frame_Multiple1:
	.addr	FrameObjects_Multiple1

Frame_Offscreen0:
	.addr	FrameObjects_Offscreen0

Frame_Offscreen1:
	.addr	FrameObjects_Offscreen1


.segment METASPRITE_FRAME_OBJECTS_BLOCK

.macro Object xpos, ypos, char, attr
	.byte	xpos + 128
	.byte	ypos + 128
	.byte	char
	.byte	attr
.endmacro

small_xPos = 13
small_yPos = 37
large_xPos = 33
large_yPos = 42

FrameObjects_OneSmall:
	.byte	1
		Object	small_xPos, small_yPos, $02, $80

Frame_OneSmall_Expected:
	.byte	small_xPos, small_yPos, $02, $80


FrameObjects_OneLarge:
	.byte	1
		Object	large_xPos, large_yPos, $0F, $01

Frame_OneLarge_Expected:
	.byte	large_xPos, large_yPos, $0F, $00


FrameObjects_Multiple0:
	.byte	3
		Object	$00, $02, $04, $F1
		Object	$10, $12, $2E, $C0
		Object	$20, $22, $0E, $00


FrameObjects_Multiple1:
	.byte	4
		Object	$30, $32, $21, $00
		Object	$40, $42, $0E, $C1
		Object	$50, $52, $FE, $00
		Object	$60, $62, $07, $21


; For these tests X = 0, Y = 0, charattr is 0
FrameObjects_Multiple_Expected:
	.byte	$00, $02, $04, $F0
	.byte	$10, $12, $0E, $C0
	.byte	$20, $22, $0E, $00
FrameObjects_Four_Expected:
	.byte	$30, $32, $01, $00
	.byte	$40, $42, $0E, $C0
	.byte	$50, $52, $1E, $00
	.byte	$60, $62, $07, $20
FrameObjects_Multiple_Expected_size = * - FrameObjects_Multiple_Expected


Test_BlockTwo_CharAttr1 = $0560
Test_BlockTwo_CharAttr2 = $0110

FrameObjects_Render_BlockTwo_Expected:
	.byte	$00, $02, $64, $F5
	.byte	$10, $12, $1E, $C1
	.byte	$20, $22, $6E, $05
	.byte	$30, $32, $11, $01
	.byte	$40, $42, $6E, $C5
	.byte	$50, $52, $2E, $01
	.byte	$60, $62, $67, $25
FrameObjects_Render_BlockTwo_Expected_size = * - FrameObjects_Render_BlockTwo_Expected

FrameObjects_Multiple_ExpectedHi:
	.byte	%00000010
	.byte	%00100010

FrameObjects_Multiple_ExpectedHi_Bitmask = $3FFF

FrameObjects_Four_ExpectedHi:
	.byte	%10001000


; table to test the offscreen test, half of these will not appear onscreen.
offscreen0_xPos = 20
offscreen0_yPos = 30

FrameObjects_Offscreen0:
	.byte	6
		Object	-28,   0, $00, $00   ; offscreen
		Object	-22, -32, $00, $00
		Object	  0, -58, $00, $00   ; offscreen
		Object	-28,   0, $00, $01
		Object	  0, -50, $00, $01   ; offscreen
		Object	  0, -38, $00, $01


offscreen1_xPos = 220
offscreen1_yPos = 180

FrameObjects_Offscreen1:
	.byte	5
		Object	-28,   0, $00, $00
		Object	 36,   0, $00, $00   ; offscreen
		Object	  0,  54, $00, $00   ; offscreen
		Object	 36,   0, $00, $01   ; offscreen
		Object	  0,  49, $00, $01   ; offscreen


FrameObjects_Offscreen_Expected:
	.byte	.lobyte(-2), .lobyte(-2), 0, 0
	.byte	.lobyte(-8), .lobyte(30), 0, 0
	.byte	.lobyte(20), .lobyte(-8), 0, 0
	.byte	.lobyte(192), .loword(180), 0, 0
FrameObjects_Offscreen_Expected_size = * - FrameObjects_Offscreen_Expected

FrameObjects_Offscreen_ExpectedHi:
	.byte	%00101101
FrameObjects_Offscreen_ExpectedHi_Bitmask = $00FF

.endmodule

; vim: set ft=asm:

