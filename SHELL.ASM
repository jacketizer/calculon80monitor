; ******************************************************************************
; Program: SHELL
; ******************************************************************************
; The shell. Let's users input commands through the console and execute them.
; ------------------------------------------------------------------------------

; Variables
; ------------------------------------------------------------------------------
SHELL_PROMPT	DB	"\r\nCMD> ",0
		BSS
SHELL_CMD_BUF	DEFS	0x20
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

	LD	B,13			; Print a line line
	CALL	CONS_WRITE_CHAR
	LD	B,10
	CALL	CONS_WRITE_CHAR

	LD	DE,SHELL_CMD_BUF	; Print the entered command to console
	CALL	CONS_WRITE_STRING

	JP	SHELL
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Program
; ------------------------------------------------------------------------------
