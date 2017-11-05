;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
; CALCULON/80 ROM RESIDENT BOOTLOADER                                          ;
; COPYRIGHT JACK ENGQVIST JOHANSSON                                            ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; RAM Layout
; ------------------------------------------------------------------------------
RAM_MAIN	EQU	0xE000	; Start of Main Program in RAM
MAIN_SIZE	EQU	0x0FF0	; Size of Main Program

; ROM Layout
; ------------------------------------------------------------------------------
ROM_MAIN	EQU	0x0030	; Start of Main Program in ROM

		ORG	0x0000

; BOOTLOADER
; ******************************************************************************
; Program: ROM Resident Bootloader
; Purpose: Test higher RAM, copy Main Program to RAM and then run it.
; ------------------------------------------------------------------------------
	DI			; Make sure interrupts are disabled

	LD	B,0xFF		; Wait a moment to make sure that all devices
	DEC	B		; have been brought out of reset
	JR	NZ,$-1

; RAMTEST
; ------------------------------------------------------------------------------
; Procedure: RAM Test (High)
; Purpose:   Test the higher RAM locations by writing and reading two different
;            bit patterns (0x00 and 0xFF).
; ------------------------------------------------------------------------------
RAMTEST:
	LD	HL,0xE000	; Start of memory
	LD	BC,0x2000	; Number of bytes to test

NEXT:	XOR	A		; Reset bits
	LD	(HL),A		; Store 0x00
	CP	(HL)		; and verify
	JR	NZ,ERROR

	CPL			; Flip bits
	LD	(HL),A		; Store 0xFF
	CPI			; Test (HL), increase HL, decrease and test BC
	JR	NZ,ERROR
	JP	M,NEXT		; If BC != 0 then continue to NEXT
				; No errors and BC is 0, continue to COPY_MAIN
; ------------------------------------------------------------------------------

; COPY_MAIN
; ------------------------------------------------------------------------------
; Procedure: Copy Main Program to RAM
; Purpose:   Copy the Main Program to RAM.
; ------------------------------------------------------------------------------
COPY_MAIN:
	LD	HL,ROM_MAIN	; Source
	LD	DE,RAM_MAIN	; Destination
	LD	BC,MAIN_SIZE	; Number of bytes
	LDIR
; ------------------------------------------------------------------------------

	JP	RAM_MAIN	; Run Main Program

ERROR:	HALT			; Halt on error

; ------------------------------------------------------------------------------
; END: ROM Resident Bootloader
; ------------------------------------------------------------------------------

	DS	ROM_MAIN-$	; Fill up unused space
	END
