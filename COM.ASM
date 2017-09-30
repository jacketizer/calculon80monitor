; ******************************************************************************
; COM DRIVER
; ******************************************************************************
; Driver:  Low level character device driver for the Z80 SIO
; ------------------------------------------------------------------------------

; Addresses
; ------------------------------------------------------------------------------
COM_BASE_ADDR			EQU	0x10
COM_CTRL_A			EQU	0x11
COM_CTRL_B			EQU	0x13

; Variables
; ------------------------------------------------------------------------------
TX_OFF				DEFB	0x00

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

	WR_REG	2,0x00			; WR2: Interrupt Vector
	WR_REG	1,0x00			; WR1: Status Affect Vector: off

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Configure a channel for communication
; Name:       COM_CFG
;
; Entry:      C = Channel Index (0..1)
; Exit:       [No value]
; Registers:  A,C 
; TODO: If channel is B (0), then OR 0x18 with 0x04 (Vector affects)
; TODO: DTR?
; ------------------------------------------------------------------------------
COM_CFG:
	FIX_IDX
	INC	C			; Set to control address

	ERR_RST				; Reset errors
	CH_RST				; Reset channel

	WR_REG	4,0x8F			; WR4: x32 clock, 2 stop bits, even parity
	WR_REG	5,0xEA			; WR5: 8-bit, Tx enabled, RTS, DTR
	WR_REG	3,0xC1			; WR3: 8-bit, Rx enabled
	WR_REG	1,0x1A			; WR1: Rx and Tx interrupts enabled

	LD	A,0x00
	LD	(TX_OFF),A

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Disable transmission for a channel
; Name:       COM_TX_OFF
;
; Entry:      C = Channel Index (0..1)
; Exit:       [No value]
; Registers:  A,C 
; ------------------------------------------------------------------------------
COM_TX_OFF:
	LD	A,(TX_OFF)
	CP	0x00
	RET	NZ

	FIX_IDX
	INC	C			; Set to control address

	WR_REG	5,0xE0			; WR5: 8-bit, Tx disabled, DTR
	WR_REG	1,0x18			; WR1: Tx interrupts disabled

	LD	A,0xFF
	LD	(TX_OFF),A

	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Enable transmission for a channel
; Name:       COM_TX_ON
;
; Entry:      C = Channel Index (0..1)
; Exit:       [No value]
; Registers:  A,C 
; ------------------------------------------------------------------------------
COM_TX_ON:
	LD	A,(TX_OFF)
	CP	0x00
	RET	Z

	FIX_IDX
	INC	C			; Set to control address

	WR_REG	5,0xEA			; WR5: 8-bit, Tx enabled, RTS
	WR_REG	1,0x1A			; WR1: Rx and Tx interrupts enabled

	XOR 	A
	LD	(TX_OFF),A

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
;               5: Tx Buffer Empty
;               4: Reserved
;               3: Reserved
;               2: Reserved
;               1: CTS
;               0: DCD
; Registers:  A,B,C,D
; ------------------------------------------------------------------------------
COM_STATUS:
	FIX_IDX
	INC	C			; Set to control address
	LD	D,0x00			; Reset result

	RD_REG	1
	AND	0x70
	JP	Z,COM_ST_1
	SET	7,D			; Error
COM_ST_1:
	RD_REG	0
	BIT	5,A			; Clear To Send
	JP	Z,COM_ST_2
	SET	1,D
COM_ST_2:
	BIT	3,A			; Data Carrier Detect
	JP	Z,COM_ST_3
	SET	0,D
COM_ST_3:
	BIT	0,A			; Character Received
	JP	Z,COM_ST_4
	SET	6,D
COM_ST_4:
	BIT	2,A			; Character Received
	JP	Z,COM_ST_5
	SET	5,D
COM_ST_5:
	LD	A,D			; Copy result to A
	RET

; ------------------------------------------------------------------------------
; Title:      Write a character to the COM channel
; Name:       COM_WRITE
;
; Entry:      C = Channel Index (0..1), B = Character to send
; Exit:       [No value]
; Registers:  A,B,C 
; ------------------------------------------------------------------------------
COM_WRITE:
	FIX_IDX
	LD	A,B
	OUT	(C),A
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Read a character from the COM channel
; Name:       SIO_READ
;
; Entry:      C = Channel Index (0..1)
; Exit:       A = Character
; Registers:  A,C 
; ------------------------------------------------------------------------------
COM_READ:
	FIX_IDX
	IN	A,(C)			; Read character
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Driver
; ------------------------------------------------------------------------------
