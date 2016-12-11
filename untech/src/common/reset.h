; SNES Reset Routines

.ifndef ::_COMMON__RESET_H_
::_COMMON__RESET_H_ := 1

.include "common/modules.inc"

.setcpu "65816"

.importmodule Reset
	;; Reset Handler
	;;
	;;
	;; Resets
	;;    * Stack Pointer
	;;    * DB register to RESET_DB (default $80)
	;;    * WRAM
	;;    * SNES Registers to a basic default (except mode 7 Matrix)
	;;    * VRAM
	;;    * OAM
	;;    * CGRAM
	;;
	;; Will jump to `Main` routine when complete.
	.importroutine ResetSNES


	;; Resets most of the Registers in the SNES to their recommended defaults.
	;;
	;; Defaults:
	;;     * Forced Screen Blank
	;;     * Mode 0
	;;     * OAM Size 8x8, 16x16, base address 0
	;;     * BG Base address 0, size = 8x8
	;;     * No Mosaic
	;;     * No BG Scrolling
	;;     * VRAM Increment on High Byte
	;;     * No Windows
	;;     * No Color Math
	;;     * No Backgrounds
	;;     * No HDMA
	;;     * ROM access to slow
	;;
	;; This routine does not set the following as any programmer need to set them anyway:
	;;     * the Mode 7 Matrix
	;;     * VRAM/CGRAM/OAM data address registers
	.importroutine ResetRegisters


	;; Transfers 0x10000 0 bytes to VRAM
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, Force Blank, DB access registers
	;;
	;; Uses DMA Channel 0 to do so.
	.importroutine ClearVRAM


	;; Clears the CGRAM
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, Force Blank, DB access registers
	;;
	;; Uses DMA Channel 0 to do so.
	.importroutine ClearCGRAM


	;; Clears the Sprites off the screen.
	;;
	;; Sets:
	;;	* X position to -128 (can't use -256, as it would be counted in the scanlines)
	;;	* Y position to 240 (outside rendering area for 8x8 and 16x16 sprites)
	;;	* Character 0
	;;	* No Priority, no flips
	;;	* Small Size
	;;
	;; NOTICE: This sets both OAM tables.
	;; REQUIRES: Force Blank
	.importroutine ClearOAM

.endimportmodule

.endif

; vim: ft=asm:

