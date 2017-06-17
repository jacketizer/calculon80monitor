CONS_BUF	DEFM	"ST JOHANSSON 89JACK ENGQVI"
CONS_BUF_HEAD	DEFB	15
CONS_BUF_TAIL	DEFB	14
CONS_BUF_LEN	DEFB	26

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

ISATEND MACRO
	LD	A,(CONS_BUF_HEAD)
	LD	C,A
	LD	A,(CONS_BUF_LEN)
	CP	C
	ENDM

CONS_SEND_JACK:
	LD	HL,CONS_BUF_HEAD	; 5
	LD	(HL),15			; 5
	LD	HL,CONS_BUF_TAIL
	LD	(HL),14
	CALL	CONS_SEND_NEXT
	RET

; ---------------------------------
CONS_SEND_NEXT:
	ISEMPTY
	JP	Z,CONS_EMPTY		; If empty, jump
	
	ITOADDR
	LD	B,(HL)
	LD	C,0x00
	CALL	COM_WRITE

	; Increase HEAD pointer
	LD	HL,CONS_BUF_HEAD
	INC	(HL)

	; Check if at end of buffer, if so, set HEAD to 0
	ISATEND
	JP	Z,CONS_ATEND

	RET

CONS_ATEND:
	XOR	A
	LD	(CONS_BUF_HEAD),A
	RET

CONS_EMPTY:				; Reset buffer pointers. Remove this part?
	XOR	A			; 2
	LD	(CONS_BUF_HEAD),A	; 6.5
	LD	(CONS_BUF_TAIL),A	; 6.5
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
