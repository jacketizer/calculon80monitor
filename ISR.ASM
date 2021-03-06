; ******************************************************************************
; INTERRUPT SERVICE ROUTINE DRIVER
; ******************************************************************************
; Driver:  Functions to install interrupt service routines.
; ------------------------------------------------------------------------------

; Addresses
; ------------------------------------------------------------------------------
ISR_IV_PAGE	EQU	0x01

; ------------------------------------------------------------------------------
; Title:      Prepare the system for interrupts
; Name:       ISR_INIT
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A
; ------------------------------------------------------------------------------
ISR_INIT:
	LD	A,ISR_IV_PAGE		; Set high order interrupt vector
	LD	I,A
	IM	2			; Set interrupt mode 2
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Install a service routine in the vector table
; Name:       ISR_INSTALL
;
; Entry:      L = Vector 0 - 127 (16-bit aligned), BC = Address to ISR
; Exit:       [No value]
; Registers:  A,BC,HL
; ------------------------------------------------------------------------------
ISR_INSTALL:
	LD	A,I
	LD	H,A
	LD	(HL),C
	INC	HL
	LD	(HL),B
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Enable interrupts
; Name:       ISR_ENABLE
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  [No register]
; ------------------------------------------------------------------------------
ISR_ENABLE:
	EI
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Driver
; ------------------------------------------------------------------------------
