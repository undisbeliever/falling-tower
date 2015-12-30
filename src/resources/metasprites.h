; resources

.ifndef ::_RESOURCES__METASPRITES_H_
::_RESOURCES__METASPRITES_H_ := 1

.import MetaSprite__FrameSet_Data

.scope MetaSprites
	.scope Player
		frameSetId = 0
		nFrames	= 22

		leftOffset = 11

		.enum Frames
			stand_right
			blink_right
			jump_right
			fall_right
			die_right
			walk0_right
			walk1_right
			walk2_right
			walk3_right
			walk4_right
			walk5_right
			stand_left
			blink_left
			jump_left
			fall_left
			die_left
			walk0_left
			walk1_left
			walk2_left
			walk3_left
			walk4_left
			walk5_left
		.endenum
	.endscope

	.scope Platforms
		frameSetId = 1
		nFrames	= 4

		leftOffset = 0

		.enum Frames
			platform_huge
			platform_large
			platform_medium
			platform_small
		.endenum
	.endscope
.endscope

.endif

; vim: set ft=asm:

