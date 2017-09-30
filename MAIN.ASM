;==============================================================================;
;                                                                              ;
; CALCULON/80 MAIN PROGRAM                                                     ;
; COPYRIGHT 2017 JACK ENGQVIST JOHANSSON                                       ;
;                                                                              ;
;==============================================================================;

; RAM Layout
; ------------------------------------------------------------------------------
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
	CALL	MEM_ROM_OUT		; Switch out ROM

	CALL	ISR_INIT		; Set interrupt mode and register
	CALL	CTC_INIT		; Initiate CTC driver
	CALL	COM_INIT		; Initiate COM driver

	LD	L,0x00			; Install ISR CTC:0
	LD	BC,ISR_COM_0
	CALL	ISR_INSTALL

	LD	L,0x0C			; Install ISR COM:0
	LD	BC,ISR_COM_0
	CALL	ISR_INSTALL

	LD	C,0x00			; Configure COM:0
	CALL	COM_CFG

	EI				; Enable Interrupts

JACK:
	CALL	CONS_READ_CHAR
	CALL	CONS_WRITE_CHAR
	CALL	SEND_JACK
	JP	JACK

	HALT

	; Start Timer 0
	LD	C,0x00			; Timer 0
	LD	D,0xFF			; Timer constant
	CALL	CTC_SET_VAL		; Set timer value
	LD	C,0x00			; Timer 0
	CALL	CTC_ENABLE_INT		; Enable interrupts

	HALT				; Wait for interrupts

SEND_JACK:
	LD	B,"J"
	CALL	CONS_WRITE_CHAR
	LD	B,"A"
	CALL	CONS_WRITE_CHAR
	LD	B,"C"
	CALL	CONS_WRITE_CHAR
	LD	B,"K"
	CALL	CONS_WRITE_CHAR

	DI
	CALL	CONS_PROCESS_SEND
	EI
	RET



ISR_TIMER_0:

	EI
	RETI

ISR_COM_0:
	EX	AF,AF'
	EXX

	CALL	CONS_PROCESS

	EXX
	EX	AF,AF'
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
	include	"COM.ASM"
	include "CONSOLE.ASM"

	END
