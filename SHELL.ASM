; ******************************************************************************
; Program: SHELL
; ******************************************************************************
; The shell. Lets users input commands through the console and execute them.
; ------------------------------------------------------------------------------

; Constants
; ------------------------------------------------------------------------------
SHELL_PROMPT	DB	"\r\nCALCULON80> ",ASCII_NUL

; Variables
; ------------------------------------------------------------------------------
		BSS
SHELL_CMD_BUF	DEFS	0x100
		CODE

; ------------------------------------------------------------------------------
; Title:      Shell Main
; Name:       SHELL

; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,BC,DE,HL
; ------------------------------------------------------------------------------
SHELL:
	LD	DE,SHELL_PROMPT		; Print prompt
	CALL	CONS_WRITE_STRING

	LD	DE,SHELL_CMD_BUF	; Read a command from console
	CALL	CONS_READ_LINE_ECHO

	LD	B,ASCII_CR		; Print a line line
	CALL	CONS_WRITE_CHAR
	LD	B,ASCII_LF
	CALL	CONS_WRITE_CHAR

	LD	DE,SHELL_CMD_BUF	; Print the entered command to console
	CALL	CONS_WRITE_STRING

	JP	SHELL
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Program
; ------------------------------------------------------------------------------
