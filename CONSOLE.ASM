CONS_BUF	DEFM	"JACK ENGQVIST JOHANSSON 89"
CONS_PTR_S	DEFB	0
CONS_PTR_E	DEFB	26

CONS_SEND_JACK:
	LD	HL,CONS_PTR_S		; 5
	LD	(HL),0x00		; 5
	LD	HL,CONS_PTR_E
	LD	(HL),26
	CALL	CONS_SEND_NEXT
	RET

CONS_SEND_NEXT:
	LD	A,(CONS_PTR_S)
	LD	C,A
	LD	A,(CONS_PTR_E)
	CP	C
	JP	Z,CONS_EMPTY			; Buffer empty
	
	LD	B,0x00
	LD	HL,CONS_BUF
	ADD	HL,BC
	LD	B,(HL)
	LD	C,0x00
	CALL	COM_WRITE

	LD	A,(CONS_PTR_S)
	INC	A
	LD	(CONS_PTR_S),A

	RET

CONS_EMPTY:
	XOR	A			; 2
	LD	(CONS_PTR_S),A		; 6.5
	LD	(CONS_PTR_E),A		; 6.5
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
	LD	C,0x00
	CALL	COM_READ
	CALL	CONS_SEND_JACK
; TODO: Save character and check if rx buffer is empty...
	JP	ISR_COM_END

ISR_COM_TXEMPTY:
	CALL	CONS_SEND_NEXT

ISR_COM_END:
	RET
;---------------------------------------------
