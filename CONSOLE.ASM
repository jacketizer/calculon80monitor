	ALIGN	256			; Buffer needs to be page aligned

CONS_BUF	DEFM	"ST JOHANSSON 12345678 JACK ENGQVIXXXXX"
CONS_BUF_HEAD	DEFB	22
CONS_BUF_TAIL	DEFB	21
CONS_BUF_LEN	EQU	0x1F		; Needs to be a power of two - 1
CONS_COM_CH	EQU	0x00		; Which COM channel to allocate

ITOADDR MACRO				; Index in C
	LD	HL,CONS_BUF		; 3.5
	LD	L,C			; 2
	ENDM

ISEMPTY MACRO
	LD	A,(CONS_BUF_HEAD)
	LD	C,A
	LD	A,(CONS_BUF_TAIL)
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
	LD	HL,CONS_BUF_HEAD
	LD	(HL),22	
	LD	HL,CONS_BUF_TAIL
	LD	(HL),21
	CALL	CONS_SEND_NEXT
	RET

CONS_SEND_CHAR:
	LD	(CONS_BUF_TAIL),A
	BUF_ADV	CONS_BUF_TAIL
	RET

; ---------------------------------
CONS_SEND_NEXT:
	ISEMPTY
	RET	Z			; If empty, return
	
	ITOADDR
	LD	B,(HL)
	LD	C,CONS_COM_CH
	CALL	COM_WRITE

	BUF_ADV	CONS_BUF_HEAD

	; The SIO has a two character buffer, send again
	CALL	CONS_SEND_NEXT
	RET

;---------------------------------------------
CONS_PROCESS:
	LD	C,0
	CALL	COM_STATUS
	BIT	6,A
	JP	NZ,ISR_COM_READ
	BIT	5,A
	JP	NZ,ISR_COM_TXEMPTY
	JP	ISR_COM_END

ISR_COM_READ:
	LD	C,CONS_COM_CH
	CALL	COM_READ
	CALL	CONS_SEND_JACK
; TODO: Save character and check if rx buffer is empty...
	JP	ISR_COM_END

ISR_COM_TXEMPTY:
	CALL	CONS_SEND_NEXT

ISR_COM_END:
	RET
;---------------------------------------------
