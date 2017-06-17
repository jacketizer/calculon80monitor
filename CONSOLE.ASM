CONS_BUF	DEFM	"ST JOHANSSON 79 JACK ENGQVI"
CONS_BUF_HEAD	DEFB	16
CONS_BUF_TAIL	DEFB	15
CONS_BUF_LEN	DEFB	27

ITOADDR MACRO				; Index in C
	LD	B,0x00
	LD	HL,CONS_BUF
	ADD	HL,BC
	ENDM

ISEMPTY MACRO
	LD	A,(CONS_BUF_HEAD)
	LD	C,A
	LD	A,(CONS_BUF_TAIL)
	CP	C
	ENDM

BUF_ADV	MACRO	POINTER
	; Increase pointer
	LD	HL,POINTER
	INC	(HL)
	; Check if over the edge
	LD	A,(POINTER)		; (HL)?
	LD	C,A			; LD C,(HL)?
	LD	A,(CONS_BUF_LEN)
	CP	C
;JP	NZ,$+3
	RET	NZ
	; If over the edge, reset pointer to 0
	XOR	A			; LD (HL),0x00?
	LD	(POINTER),A
	ENDM

CONS_SEND_JACK:
	LD	HL,CONS_BUF_HEAD	; 5
	LD	(HL),16			; 5
	LD	HL,CONS_BUF_TAIL
	LD	(HL),15
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
	LD	C,0x00
	CALL	COM_WRITE

	BUF_ADV	CONS_BUF_HEAD

	RET

CONS_EMPTY:				; Reset buffer pointers. Remove this part?
;	XOR	A			; 2
;	LD	(CONS_BUF_TAIL),A	; 6.5
;	INC	A
;	LD	(CONS_BUF_HEAD),A	; 6.5
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
