; ******************************************************************************
; COM DRIVER
; ******************************************************************************
; Driver:  Low level COM driver for the Z80 SIO
; ------------------------------------------------------------------------------

; Addresses
; ------------------------------------------------------------------------------
COM_BASE_ADDR			EQU	0x10
COM_CTRL_A			EQU	0x11
COM_CTRL_B			EQU	0x13

; Variables
; ------------------------------------------------------------------------------

; Macros
; ------------------------------------------------------------------------------
FIX_IDX	MACRO
	LD	A,COM_BASE_ADDR		; Load base addr
	RLC	C			; Multiply index by two
	ADD	A,C			; Merge
	LD	C,A
	ENDM

RD_REG	MACRO	REG
	IF	REG!=0
	LD	A,REG
	OUT	(C),A
	ENDIF
	IN	A,(C)
	ENDM

WR_REG	MACRO	REG,VAL
	IF	REG!=0
	LD	A,REG
	OUT	(C),A
	ENDIF
	LD	A,VAL
	OUT	(C),A
	ENDM

CH_RST	MACRO
	WR_REG	0,0x18			; WR0: Channel Reset
	ENDM

ERR_RST	MACRO
	WR_REG	0,0x30			; WR0: Error Reset
	ENDM

; ------------------------------------------------------------------------------
; Title:      Initiate the driver
; Desc:       Resets all channels and sets the interrupt vector.
; Name:       COM_INIT
;
; Entry:      [No arguments]
; Exit:       [No value]
; Registers:  A,C 
; ------------------------------------------------------------------------------
COM_INIT:
	LD	C,COM_CTRL_A
	ERR_RST
	CH_RST

	LD	C,COM_CTRL_B
	ERR_RST
	CH_RST

	WR_REG	2,0x00			; WR4: Interrupt Vector
	WR_REG	1,0x04			; WR1: Status Affects Vector

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Configure a channel for communication
; Name:       COM_CFG
;
; Entry:      C = Channel Index (0..1)
; Exit:       [No value]
; Registers:  A,C 
; ------------------------------------------------------------------------------
COM_CFG:
	FIX_IDX
	INC	C			; Set to control address

	; Error reset
	ERR_RST

	; Reset channel
	CH_RST

	; Parity, clock and stop bits
	WR_REG	4,0x8F			; WR4: x32 clock, 2 stop bits, even parity

	; Tx enable, 8 bits/char, RTS
	WR_REG	5,0x6A			; WR5: 8-bit, Tx enabled, RTS

	; Rx enable, 8 bits/char
	WR_REG	3,0xC1			; WR3: 8-bit, Rx enabled

	; Rx int enable
	WR_REG	1,0x18			; WR1: Rx interrupts enabled
	; TODO: If channel is B (0), then OR 0x18 with 0x04 (Vector affects)

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Check status of a COM channel
; Name:       COM_STATUS
; Desc:       Retrieves the status and returns an appropriate value.
;
; Entry:      C = Channel Index (0..1)
; Exit:       A = Status Code
;             Bits:
;               7: Error
;               6: Rx Char Available
;               5: Reserved
;               4: Reserved
;               3: Reserved
;               2: Reserved
;               1: CTS
;               0: DCD
; Registers:  A,B,C 
; ------------------------------------------------------------------------------
COM_STATUS:
	FIX_IDX
	INC	C			; Set to control address
	LD	D,0x00			; Reset result

	RD_REG	1
	LD	B,0x08			; If reg is 8 or more: error!
	CP	B
	CALL	M,COM_ST_ERR		; Error

	RD_REG	0
	BIT	5,A
	CALL	NZ,COM_ST_CTS		; Clear To Send
	BIT	3,A
	CALL	NZ,COM_ST_DCD		; Data Carrier Detect
	BIT	0,A
	CALL	NZ,COM_ST_CHAR		; Character received
	
	LD	A,D			; Copy result to A
	RET

COM_ST_ERR:
	SET	7,D
	RET
COM_ST_CTS:
	SET	1,D
	RET
COM_ST_DCD:
	SET	0,D
	RET
COM_ST_CHAR:
	SET	6,D
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Write a character to the COM channel (blocking)
; Name:       COM_WRITE
;
; Entry:      C = Channel Index (0..1), B = Character to send
; Exit:       [No value]
; Registers:  A,C 
; TODO: Add timeout and error return code
; ------------------------------------------------------------------------------
COM_WRITE:
	FIX_IDX

	LD	A,B
	OUT	(C),A
	INC	C			; Set to control address

ISSENT:
	RD_REG	1
	BIT	0,A
	JR	Z,ISSENT

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Read a character from the COM channel (blocking)
; Name:       SIO_READ
;
; Entry:      C = Channel Index (0..1)
; Exit:       A = Character
; Registers:  A,C 
; TODO: Add timeout and error return code
; ------------------------------------------------------------------------------
COM_READ:
	FIX_IDX
	INC	C			; Set to control address

COM_READ_2:
	RD_REG	1
	BIT	4,A
	JR	NZ,COM_READ_ERR		; Parity error
	BIT	6,A
	JR	NZ,COM_READ_ERR		; Framing error

	RD_REG	0			; Check if a character is available
	BIT	0,A
	JR	Z,COM_READ_2

	DEC	C			; Set to data address
	IN	A,(C)			; Read character

COM_READ_ERR:
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Driver
; ------------------------------------------------------------------------------