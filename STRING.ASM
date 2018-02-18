; ******************************************************************************
; LIB: STRING
; ******************************************************************************
; Functions for string handling. Strings are arrays containing ASCII characters
; terminated by a NULL character.
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Get the length of a string
; Name:       STR_LEN
;
; Entry:      HL = Address to string
; Exit:       A = Number of characters in string
; Registers:  A,BC,HL
; ------------------------------------------------------------------------------
STR_LEN:
	XOR	A		; Load NULL
	LD	BC,0x0000	; Reset counter
	CPIR			; Compare characters until NULL is found
	LD	A,C		; Load B to A
	NEG			; Substract A from 0
	DEC	A		; Don't count the NULL terminator
	RET
; -----------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Compare two strings
; Name:       STR_CMP
;
; Entry:      HL = Address to string A, DE = Address to string B
; Exit:       F = Zero set if equal, else Zero = 0
; Registers:  AF,BC,DE,HL
; ------------------------------------------------------------------------------
STR_CMP:
	LD	A,(DE)		; Load test character
	CPI			; Test it against HL, and increase HL
	RET	NZ		; Return if mismatch

	AND	A		; Check for NULL
	RET	Z		; Return if NULL

	INC	DE		; Next character
	JR	STR_CMP
; -----------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Compare two strings with length limited by C
; Name:       STR_CMPN
;
; Entry:      HL = Address to string A, DE = Address to string B, C = Max length
; Exit:       F = Zero set if equal, else Zero = 0
; Registers:  AF,BC,DE,HL
; ------------------------------------------------------------------------------
STR_CMPN:
	LD	A,(DE)		; Load test character
	CPI			; Test it against HL, and increase HL
	RET	NZ		; Return if mismatch

	AND	A		; Check for NULL
	RET	Z		; Return if NULL

	DEC	C		; Check max length
	JR	Z,STRCMPN_MAX

	INC	DE		; Next character
	JR	STR_CMP

STRCMPN_MAX:
	INC	C		; Increase C to 1 to set Zero to 0
	RET
; -----------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Lib
; ------------------------------------------------------------------------------
