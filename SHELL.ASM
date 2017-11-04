; ******************************************************************************
; Program: SHELL
; ******************************************************************************
; The shell. Let's users input commands through the console and execute them.
; ------------------------------------------------------------------------------

SHELL:
	LD	DE,SHELL_CMD_BUF		; Read a command from console
	CALL	CONS_READ_LINE

	LD	HL,SHELL_CMD_BUF		; Reset command buffer pointer
	LD	(SHELL_CMD_BUFN),HL

SHELL_NEXT:
	LD	HL,(SHELL_CMD_BUFN)		; Retrieve character
	LD	B,(HL)
	XOR	A				; Check for end of string
	CP	B
	JP	Z,SHELL_END

	CALL	CONS_WRITE_CHAR			; Write character to console

	LD	HL,SHELL_CMD_BUFN		; Increment buffer pointer
	INC	(HL)

	JP	SHELL_NEXT

SHELL_END:
	DI
	CALL	CONS_PROCESS_SEND
	EI

	JP	SHELL

; Variables
; ------------------------------------------------------------------------------
SHELL_CMD_BUF	DEFS	0x20
SHELL_CMD_BUFN	DEFW	SHELL_CMD_BUF

; ------------------------------------------------------------------------------
; END: Program
; ------------------------------------------------------------------------------
