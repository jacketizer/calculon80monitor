; ******************************************************************************
; CONSOLE DRIVER
; ******************************************************************************
; Driver:  Console Driver
;          Let's programs print, read and control the console. The input and
;          output is asynchronous and buffered by the driver.
; ------------------------------------------------------------------------------

; Addresses
; ------------------------------------------------------------------------------
; TODO: The buffers should not be allocated in the binary file...
		ALIGN	256		; Buffer needs to be page aligned
CONS_OUTBUF	DEFS	0x20
		ALIGN	256		; Buffer needs to be page aligned
CONS_INBUF	DEFS	0x20
CONS_JACK:	DEFB	0x00
		DEFB	0x00

; Variables
; ------------------------------------------------------------------------------
CONS_BUF_LEN	EQU	0x1F		; Needs to be a power of two - 1
CONS_COM_CH	EQU	0x00		; Which COM channel to allocate

CONS_BUF_HEAD	DEFB	0x00
CONS_BUF_TAIL	DEFB	0x00
; TODO: Pointers for input buffer...

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
	LD	A,(CONS_BUF_HEAD)
	LD	C,A
	LD	A,(CONS_BUF_TAIL)
	ELSE
	LD	A,(CONS_BUF_HEAD)
	LD	C,A
	LD	A,(CONS_BUF_TAIL)
	ENDIF
	CP	C
	ENDM

ISFULL	MACRO	BUFFER
	IF	BUFFER==OUT
	LD	A,(CONS_BUF_TAIL)
	INC	A
	AND	CONS_BUF_LEN		; Modulus Length
	LD	C,A
	LD	A,(CONS_BUF_HEAD)
	ELSE
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
; Name:       CON_WRITE_CHAR
;
; Entry:      B = Character
; Exit:       [No value]
; Registers:  A,B,C,HL
; ------------------------------------------------------------------------------
CONS_WRITE_CHAR:
	ISFULL	OUT
	RET	Z			; If full, return
	LD	A,(CONS_BUF_TAIL)
	ITOADDR	OUT,A
	LD	(HL),B
	BUF_ADV	CONS_BUF_TAIL
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Send a character if buffer is not empty
; Desc:       Uses the COM driver to actually send a character from the output
;             buffer.
; Name:       CON_PROCESS_SEND
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,B,C,HL
; ------------------------------------------------------------------------------
CONS_PROCESS_SEND:
	ISEMPTY	OUT
	LD	C,CONS_COM_CH
	JP	Z,COM_TX_OFF
	CALL	COM_TX_ON
	
	LD	A,(CONS_BUF_HEAD)
	LD	C,A
	ITOADDR	OUT,C
	LD	B,(HL)
	LD	C,CONS_COM_CH
	CALL	COM_WRITE

	BUF_ADV	CONS_BUF_HEAD
	RET
; ------------------------------------------------------------------------------

CONS_READ_CHAR:

	LD	A,(CONS_JACK)
	CP	0x00
	JP	Z,CONS_READ_CHAR

	XOR	A
	LD	(CONS_JACK),A

	RET

; ------------------------------------------------------------------------------
; Title:      Process pending send and receive requests 
; Desc:       Sends or receives characters from the hardware module depending on
;             the status. This function should be called evertime an interrupt
;             is triggered by the hardware module.
; Name:       CON_PROCESS
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,B,C,D,HL
; ------------------------------------------------------------------------------
CONS_PROCESS:
	LD	C,0
	CALL	COM_STATUS
	BIT	6,A
	CALL	NZ,ISR_COM_READ

	LD	C,0
	CALL	COM_STATUS
	BIT	5,A
	CALL	NZ,ISR_COM_TXEMPTY

	RET

ISR_COM_READ:
	LD	C,CONS_COM_CH
	CALL	COM_READ
	LD	A,0x89
	LD	(CONS_JACK),A
; TODO: Save character and check if rx buffer is empty...
; Save character in input buffer
; Advance pointer
; Set rx flag to 1
	RET

ISR_COM_TXEMPTY:
	CALL	CONS_PROCESS_SEND
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Driver
; ------------------------------------------------------------------------------
