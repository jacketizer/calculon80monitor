		ALIGN	256			; Buffer needs to be page aligned

CONS_BUF	DEFS	0x20
CONS_BUF_HEAD	DEFB	0x00
CONS_BUF_TAIL	DEFB	0x00
CONS_BUF_LEN	EQU	0x1F		; Needs to be a power of two - 1
CONS_COM_CH	EQU	0x00		; Which COM channel to allocate

ITOADDR MACRO	REG
	LD	HL,CONS_BUF		; 3.5
	LD	L,REG			; 2
	ENDM

ISEMPTY	MACRO
	LD	A,(CONS_BUF_HEAD)
	LD	C,A
	LD	A,(CONS_BUF_TAIL)
	CP	C
	ENDM

ISFULL	MACRO
	LD	A,(CONS_BUF_TAIL)
	INC	A
	AND	CONS_BUF_LEN		; Modulus Length
	LD	C,A
	LD	A,(CONS_BUF_HEAD)
	CP	C
	ENDM

BUF_ADV	MACRO	POINTER
	LD	HL,POINTER		; Load pointer
	LD	A,(HL)
	INC	A			; Increase pointer
	AND	CONS_BUF_LEN		; Modulus Length
	LD	(HL),A			; Save pointer
	ENDM

CONS_SEND_JACK:
	LD	B,"J"
	CALL	CONS_SEND_CHAR
	LD	B,"A"
	CALL	CONS_SEND_CHAR
	LD	B,"C"
	CALL	CONS_SEND_CHAR
	LD	B,"K"
	CALL	CONS_SEND_CHAR

	CALL	CONS_SEND_NEXT
	RET

CONS_SEND_CHAR:
	ISFULL
	RET	Z			; If full, return
	LD	A,(CONS_BUF_TAIL)
	ITOADDR	A
	LD	(HL),B
	BUF_ADV	CONS_BUF_TAIL
	RET

; ---------------------------------
CONS_SEND_NEXT:
	ISEMPTY
	RET	Z			; If empty, return
	
	ITOADDR	C
	LD	B,(HL)
	LD	C,CONS_COM_CH
	CALL	COM_WRITE

	BUF_ADV	CONS_BUF_HEAD
	RET

;---------------------------------------------
CONS_PROCESS:
	LD	C,0
	CALL	COM_STATUS
	BIT	6,A
	JP	NZ,ISR_COM_READ
	BIT	5,A
	JP	NZ,ISR_COM_TXEMPTY
	RET

ISR_COM_READ:
	LD	C,CONS_COM_CH
	CALL	COM_READ
	CALL	CONS_SEND_JACK
; TODO: Save character and check if rx buffer is empty...
	RET

ISR_COM_TXEMPTY:
	CALL	CONS_SEND_NEXT
	RET
;---------------------------------------------
