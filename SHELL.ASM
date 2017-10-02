; ******************************************************************************
; SHELL
; ******************************************************************************
; The shell. Let's users input commands through the console and execute them.
; ------------------------------------------------------------------------------

; Variables
; ------------------------------------------------------------------------------
SHELL_CMD_BUF	DEFS	0x20
SHELL_CMD_LEN	DEFB	0x00

SHELL:	JP	SHELL_READ_CMD

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
	CALL	CONS_WRITE_CHAR
	DI
	CALL	CONS_PROCESS_SEND
	EI
	JP	SHELL_READ_CHAR

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: SHELL
; ------------------------------------------------------------------------------
