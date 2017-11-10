; ******************************************************************************
; MEMORY MANAGEMENT DRIVER
; ******************************************************************************
; Driver:  Driver for memory testing and mappings.
; ------------------------------------------------------------------------------

; Constants
; ------------------------------------------------------------------------------
BANK_RAM_VAL	EQU	0x01		; Switch out ROM
BANK_ROM_VAL	EQU	0x00		; Switch out RAM

; Addresses
; ------------------------------------------------------------------------------
BANK		EQU	0x00		; Back switching device

; Variables
; ------------------------------------------------------------------------------
BANK_STATE_VAR	DEFB	0x00		; Storage for current state

; ------------------------------------------------------------------------------
; Title:      Test RAM
; Name:       MEM_TEST_RAM

; Entry:      HL = Start address, BC = Number of bytes
; Exit:       A = 1 (Error), A = 0 (OK)
; Registers:  A,BC,HL
; ------------------------------------------------------------------------------
MEM_TEST:
	XOR	A			; Reset bits
	LD	(HL),A			; Store 0x00
	CP	(HL)			; and verify
	JR	NZ,MEM_RAM_ERR

	CPL				; Flip bits
	LD	(HL),A			; Store 0xFF
	CPI				; Test (HL), increase HL, decrease and
	JR	NZ,MEM_RAM_ERR		;   test BC
	JP	M,MEM_TEST		; If BC != 0 then continue...

	XOR	A
	RET

MEM_RAM_ERR:
	LD	A,0x01
	RET

; ------------------------------------------------------------------------------
; Title:      Switch in ROM
; Name:       MEM_ROM_IN
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A
; ------------------------------------------------------------------------------
MEM_ROM_IN:
	LD	A,BANK_ROM_VAL
	LD	(BANK_STATE_VAR),A
	OUT	(BANK),A
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Switch out ROM
; Name:       MEM_ROM_OUT
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A
; ------------------------------------------------------------------------------
MEM_ROM_OUT:
	LD	A,BANK_RAM_VAL
	LD	(BANK_STATE_VAR),A
	OUT	(BANK),A
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Get Bank State
; Name:       MEM_BANK_STATE

; Entry:      [No arguments]
; Exit:       A = 1 if RAM, else A = 0
; Registers:  A
; ------------------------------------------------------------------------------
MEM_BANK_STATE:
	LD	A,(BANK_STATE_VAR)
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Driver
; ------------------------------------------------------------------------------
