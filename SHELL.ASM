; ******************************************************************************
; Program: SHELL
; ******************************************************************************
; The shell. Let's users input commands through the console and execute them.
; ------------------------------------------------------------------------------

SHELL:
	CALL	SHELL_READ_CMD

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
; Title:      Read characters into the command buffer, until ENTER is read
; Name:       SHELL_READ_CMD
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,B,C,HL
; ------------------------------------------------------------------------------
SHELL_READ_CMD:
	LD	HL,SHELL_CMD_BUF		; Reset command buffer pointer
	LD	(SHELL_CMD_BUFN),HL
SHELL_READ_CHAR:
	CALL	CONS_READ_CHAR			; Read a character from console

	LD	A,13				; Check for ENTER
	CP	B
	JP	Z,SHELL_READ_ENTER

	LD	HL,(SHELL_CMD_BUFN)		; Store character
	LD	(HL),B

	LD	HL,SHELL_CMD_BUFN		; Increment buffer pointer
	INC	(HL)

	CALL	CONS_WRITE_CHAR			; Echo character
	DI
	CALL	CONS_PROCESS_SEND
	EI

	JP	SHELL_READ_CHAR			; Read next...

SHELL_READ_ENTER:
	LD	HL,(SHELL_CMD_BUFN)		; Terminate command string
	LD	(HL),0x00

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Program
; ------------------------------------------------------------------------------
