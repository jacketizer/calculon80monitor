; ******************************************************************************
; Program: SHELL
; ******************************************************************************
; The shell. Let's users input commands through the console and execute them.
; ------------------------------------------------------------------------------

SHELL:	CALL	SHELL_READ_CMD
	RET

; Variables
; ------------------------------------------------------------------------------
SHELL_CMD_BUF	DEFS	0x20
SHELL_CMD_LEN	DEFB	0x00

; ------------------------------------------------------------------------------
; Title:      Read characters into the command buffer, until CR
; Name:       SHELL_READ_CMD
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,B,C,HL
; ------------------------------------------------------------------------------
SHELL_READ_CMD:
	XOR	A
	LD	(SHELL_CMD_LEN),A
SHELL_READ_CHAR:
	; Shell:
 	; Read character
	; Check for enter
	; If not, put into buffer and echo back character
	; Then run command
	; Repeat
	CALL	CONS_READ_CHAR
	LD	A,13			; Check for ENTER
	CP	B
	RET	Z			; Return if ENTER

	CALL	CONS_WRITE_CHAR
	DI
	CALL	CONS_PROCESS_SEND
	EI
	JP	SHELL_READ_CHAR

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Program
; ------------------------------------------------------------------------------
