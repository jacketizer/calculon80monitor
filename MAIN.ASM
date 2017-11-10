;==============================================================================;
;                                                                              ;
; CALCULON/80 MAIN PROGRAM                                                     ;
; COPYRIGHT 2017 JACK ENGQVIST JOHANSSON                                       ;
;                                                                              ;
;==============================================================================;

; ROM Layout
; ------------------------------------------------------------------------------
ROM_BOOT	EQU	0x0000		; Start of Bootloader in ROM
ROM_MAIN	EQU	0x0030		; Start of Main Program in ROM

; RAM Layout
; ------------------------------------------------------------------------------
RAM_STACK	EQU	0xFFFF		; Start of stack in RAM
RAM_MAIN	EQU	0xE000		; Start of Main Program in RAM
RAM_BSS		EQU	0xDC00		; Start of uninitialized data in RAM

; Segment Definitions
; ------------------------------------------------------------------------------
	BSS
	ORG	RAM_BSS
	CODE
	ORG	RAM_MAIN

; MAIN PROGRAM
; ******************************************************************************
; Program: Main Program
; Purpose: Lets the user control the computer.
; ------------------------------------------------------------------------------
MAIN:

; Init Stage 1
; ..............................................................................
	LD	SP,RAM_STACK		; Set stack pointer
	CALL	MEM_ROM_OUT		; Switch out ROM

	CALL	ISR_INIT		; Set interrupt mode and register
	CALL	CTC_INIT		; Initiate CTC driver
	CALL	COM_INIT		; Initiate COM driver

	LD	L,0x00			; Install ISR COM:0
	LD	BC,ISR_COM_0
	CALL	ISR_INSTALL

	LD	L,0x10			; Install ISR CTC:0
	LD	BC,ISR_TIMER_0
	CALL	ISR_INSTALL

	LD	C,0x00			; Configure COM:0
	CALL	COM_CFG

	LD	C,0x00			; Start timer 0
	LD	D,0xFF			; Value = 255
	CALL	CTC_SET_VAL
	LD	C,0x00			; Enable interrupts for timer 0
	CALL	CTC_ENABLE_INT

	EI				; Enable interrupts

	CALL	SHELL			; Start shell

	HALT				; Halt and wait for interrupts

ISR_TIMER_0:
	EX	AF,AF'
	EXX

	CALL	CONS_MAIN

	EXX
	EX	AF,AF'
	EI
	RETI

ISR_COM_0:
	EX	AF,AF'
	EXX

	CALL	CONS_ISR

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
	include "SHELL.ASM"

	END
