; ******************************************************************************
; CONSOLE DRIVER
; ******************************************************************************
; Driver:  Console driver implementation utilizing a COM channel.
;          Lets programs control, print and read to the console. The input and
;          output is asynchronous and buffered by the driver.
;          This implementation uses a COM channel to communicate with a terminal
;          to serve as a console for the user.
; ------------------------------------------------------------------------------

; Constants
; ------------------------------------------------------------------------------
CONS_BUF_LEN	EQU	0xFF		; Needs to be a power of two - 1
CONS_COM_CH	EQU	0x00		; Which COM channel to allocate


; Variables
; ------------------------------------------------------------------------------
CONS_OUT_HEAD	DEFB	0x00		; Console buffer pointers
CONS_OUT_TAIL	DEFB	0x00
CONS_IN_HEAD	DEFB	0x00
CONS_IN_TAIL	DEFB	0x00
CONS_COM_STATUS	DEFB	0x00		; Temporary storage for COM status
CONS_NEW_CHAR	DEFB	0x00
		BSS
		ALIGN	256		; Buffers needs to be page aligned
CONS_OUTBUF	DEFS	0x100		; Console output buffer
		ALIGN	256
CONS_INBUF	DEFS	0x100		; Console input buffer
		CODE


; Macros
; ------------------------------------------------------------------------------
ITOADDR MACRO	BUFFER,REG
	IF	BUFFER==OUT
	LD	HL,CONS_OUTBUF
	ELSE
	LD	HL,CONS_INBUF
	ENDIF
	LD	L,REG
	ENDM

ISEMPTY	MACRO	BUFFER
	IF	BUFFER==OUT
	LD	A,(CONS_OUT_HEAD)
	LD	C,A
	LD	A,(CONS_OUT_TAIL)
	ELSE
	LD	A,(CONS_IN_HEAD)
	LD	C,A
	LD	A,(CONS_IN_TAIL)
	ENDIF
	CP	C
	ENDM

ISFULL	MACRO	BUFFER
	IF	BUFFER==OUT
	LD	A,(CONS_OUT_TAIL)
	INC	A
	AND	CONS_BUF_LEN		; Modulus Length
	LD	C,A
	LD	A,(CONS_OUT_HEAD)
	ELSE
	LD	A,(CONS_IN_TAIL)
	INC	A
	AND	CONS_BUF_LEN		; Modulus Length
	LD	C,A
	LD	A,(CONS_IN_HEAD)
	ENDIF
	CP	C
	ENDM

BUF_ADV	MACRO	POINTER
	LD	HL,POINTER		; Load pointer
	LD	A,(HL)
	INC	A			; Increase pointer
	AND	CONS_BUF_LEN		; Modulus Length
	LD	(HL),A			; Save pointer
	ENDM

; ------------------------------------------------------------------------------
; Title:      Write a character to the console
; Desc:       Write a character to the console at the current position. The
;             output is buffered by the driver and is therefore decoupled from
;             the hardware module.
; Name:       CONS_WRITE_CHAR
;
; Entry:      B = Character
; Exit:       [No value]
; Registers:  A,B,C,HL
; ------------------------------------------------------------------------------
CONS_WRITE_CHAR:
	ISFULL	OUT
	RET	Z			; If full, return

	LD	A,(CONS_OUT_TAIL)	; Push character to buffer
	ITOADDR	OUT,A
	LD	(HL),B
	BUF_ADV	CONS_OUT_TAIL

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Read a character from the console
; Desc:       The input is buffered by the driver and is therefore decoupled
;             from the hardware module.
; Name:       CONS_READ_CHAR
;
; Entry:      [No arguments]
; Exit:       B = Character
; Registers:  A,B,C,HL
; ------------------------------------------------------------------------------
CONS_READ_CHAR:
	LD	A,(CONS_NEW_CHAR)	; Check unread character flag
	CP	0x00
	JP	Z,CONS_READ_CHAR

	XOR	A			; Reset unread character flag
	LD	(CONS_NEW_CHAR),A

	LD	A,(CONS_IN_HEAD)	; Read character into buffer
	LD	C,A
	ITOADDR	IN,C
	LD	B,(HL)
	BUF_ADV	CONS_IN_HEAD

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Read line with echo
; Desc:       Read characters into a buffer and echo them until enter is read.
;             Then null terminate the buffer and return.
; Name:       CONS_READ_LINE_ECHO
;
; Entry:      DE = Buffer pointer to read characters into
; Exit:       [No value]
; Registers:  A,B,C,HL,DE
; ------------------------------------------------------------------------------
CONS_READ_LINE_ECHO:
	CALL	CONS_READ_CHAR		; Read a character from console

	LD	A,"\r"			; Check for ENTER
	CP	B
	JP	Z,CONS_READ_ENTER

	LD	A,B			; Store character
	LD	(DE),A

	INC	DE			; Increment buffer pointer

	CALL	CONS_WRITE_CHAR		; Echo character

	JP	CONS_READ_LINE_ECHO	; Read next...

CONS_READ_ENTER:
	XOR	A			; Null terminate buffer
	LD	(DE),A

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Write a string to the console
; Name:       CONS_WRITE_STRING
;
; Entry:      DE = Buffer pointer
; Exit:       [No value]
; Registers:  A,B,C,HL,DE
; ------------------------------------------------------------------------------
CONS_WRITE_STRING:
	LD	A,(DE)			; Retrieve character
	LD	B,A

	XOR	A			; Check for end of string
	CP	B
	RET	Z

	CALL	CONS_WRITE_CHAR		; Write character to console

	INC	DE			; Increment buffer pointer

	JP	CONS_WRITE_STRING	; Write next...
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Send a character if buffer is not empty
; Desc:       Uses the COM driver to actually send a character from the output
;             buffer.
; Name:       CONS_PROCESS_SEND
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,B,C,HL
; ------------------------------------------------------------------------------
CONS_ISR_SEND:
	ISEMPTY	OUT
	LD	C,CONS_COM_CH
	JP	Z,COM_TX_OFF
	CALL	COM_TX_ON
	
	LD	A,(CONS_OUT_HEAD)
	LD	C,A
	ITOADDR	OUT,C
	LD	B,(HL)
	LD	C,CONS_COM_CH
	CALL	COM_WRITE

	BUF_ADV	CONS_OUT_HEAD
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Read a character into the buffer
; Desc:       Uses the COM driver to actually read a character into the input
;             buffer.
; Name:       CONS_PROCESS_RECEIVE
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,B,C,HL
; ------------------------------------------------------------------------------
CONS_ISR_RECEIVE:
	LD	C,CONS_COM_CH
	CALL	COM_READ
	LD	B,A

	ISFULL	IN
	RET	Z			; If full, return

	LD	A,(CONS_IN_TAIL)
	ITOADDR	IN,A
	LD	(HL),B
	BUF_ADV	CONS_IN_TAIL

	LD	A,0xFF
	LD	(CONS_NEW_CHAR),A

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Process pending send and receive requests 
; Desc:       Sends or receives characters from the hardware module depending on
;             the status. This function should be called everytime an interrupt
;             is triggered by the hardware module.
; Name:       CONS_PROCESS
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,B,C,D,HL
; ------------------------------------------------------------------------------
CONS_ISR:
	LD	C,CONS_COM_CH		; Retrieve status word from COM channel
	CALL	COM_STATUS
	LD	(CONS_COM_STATUS),A

	BIT	6,A			; Check if character is available
	CALL	NZ,CONS_ISR_RECEIVE

	LD	A,(CONS_COM_STATUS)	; Check if hw buffer is empty, if so,
	BIT	5,A			; send next character
	CALL	NZ,CONS_ISR_SEND

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Cyclic main procedure
; Desc:       Should be called periodically by OS. The purpose of this is to
;             initiate transmission when needed.
; Name:       CONS_PROCESS
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,B,C,D,HL
; ------------------------------------------------------------------------------
CONS_MAIN:
	LD	C,CONS_COM_CH		; Return if Tx is already ongoing
	CALL	COM_TX_STATE
	CP	COM_TX_STATE_ON
	RET	Z

	CALL	CONS_ISR_SEND		; Start transmission

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Driver
; ------------------------------------------------------------------------------
