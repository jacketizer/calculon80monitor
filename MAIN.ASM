;==============================================================================;
;                                                                              ;
; CALCULON/80 MAIN PROGRAM                                                     ;
; COPYRIGHT 2017 JACK ENGQVIST JOHANSSON                                       ;
;                                                                              ;
;==============================================================================;

; RAM Layout
; ------------------------------------------------------------------------------
MAIN_SIZE	EQU	0x0F00		; Size of Main Program
STACK		EQU	0xFFFF		; Start of stack

; ROM Layout
; ------------------------------------------------------------------------------
ROM_MAIN	EQU	0x0030		; Start of Main Program in ROM

	ORG	0xE000

; MAIN PROGRAM
; ******************************************************************************
; Program: Main Program
; Purpose: Let the user control the computer.
; ------------------------------------------------------------------------------
MAIN:

; Init Stage 1
; ..............................................................................
	LD	SP,STACK		; Set stack pointer
	CALL	ISR_INIT		; Set interrupt mode and register
	CALL	MEM_ROM_OUT		; Switch out ROM

	LD	C,0x00			; Initiate timer driver
	CALL	CTC_INIT

	LD	L,0x00			; Install ISR Timer 0
	LD	BC,ISR_TIMER_0
	CALL	ISR_INSTALL

	LD	L,0x0C			; Install ISR COM 0
	LD	BC,ISR_COMRD_0
	CALL	ISR_INSTALL

	CALL	SIO_INIT
	LD	C,0x00
	CALL	SIO_CFG			; Channel 0

	EI				; Enable Interrupts

JACK:	XOR	A
	JP	JACK

	HALT
	; Start Timer 0
	LD	C,0x00			; Timer 0
	LD	D,0xFF			; Timer constant
	CALL	CTC_SET_VAL		; Set timer value
	LD	C,0x00			; Timer 0
	CALL	CTC_ENABLE_INT		; Enable interrupts

	LD	D,0xFF
	HALT				; Wait for interrupts


ISR_TIMER_0:
	DI

	LD	C,0x00
	CALL	SIO_READ
	LD	B,A
	LD	C,0x00
	CALL	SIO_WRITE

	EI
	RETI

ISR_COMRD_0:
	DI

	LD	C,0x00
	CALL	SIO_READ
	LD	B,A
	LD	C,0x00
	CALL	SIO_WRITE

	EI
	RETI

; ------------------------------------------------------------------------------
; END: Main Program
; ------------------------------------------------------------------------------

; Driver Includes
; ------------------------------------------------------------------------------
	include	"PIO.ASM"
	include	"ISR.ASM"
	include	"CTC.ASM"
	include	"MEM.ASM"
	include	"SIO.ASM"

	DS	0xF000-$-ROM_MAIN	; Fill up the entire 2732 EPROM
	END
