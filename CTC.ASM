; ******************************************************************************
; CTC DRIVER
; ******************************************************************************
; Driver:  Low level driver for the CTC
;          Controls the Z80 CTC by abstracting the use of the control register:
;          Bit 7: Interrupt, 1 = Enable, 0 = Disable
;          Bit 6: Mode, 1 = Counter, 0 = Timer
;          Bit 5: Prescaler, 1 = 256, 0 = 16
;          Bit 4: Edge Trg, 1 = Rising, 0 = Falling
;          Bit 3: Trigger, 1 = Pulse, 0 = Auto
;          Bit 2: Time Const Follow, 1 = True, 0 = False
;          Bit 1: Reset, 1 = Software, 0 = Continue Operation
;          Bit 0: Ctrl/Vector, 1 = Control, 0 = Vector
; ------------------------------------------------------------------------------

; Addresses
; ------------------------------------------------------------------------------
CTC_ADDR_CH0		EQU	0x28	; Physical CTC Channel Addresses
CTC_ADDR_CH1		EQU	0x29
CTC_ADDR_CH2		EQU	0x2A
CTC_ADDR_CH3		EQU	0x2B

; Variables
; ------------------------------------------------------------------------------
; Table structure: two bytes per item; Address and Control Byte.
; Address: The 8-bit address to the channel register.
; Control Register: Stores each timers configuration, bits 0, 1 and 2 should
;                   always be 0 except temporary when actually programming the
;                   CTC channel.
CTC_TBL:
			DEFB	CTC_ADDR_CH0,0x00
			DEFB	CTC_ADDR_CH1,0x00
			DEFB	CTC_ADDR_CH2,0x00
			DEFB	CTC_ADDR_CH3,0x00

CTC_DEFAULT_CONF	EQU	0x20	; Prescaler = 1 (256)

; ------------------------------------------------------------------------------
; Title:      Initiate a channel with the default values
; Name:       CTC_INIT
; Desc:       Stop the channel, set default values and set the interrupt vector.
;             The interrupt vector will be the channel index number shifted left
;             one bit:
;             Channel	Interrupt Vector
;                   0                  0
;                   1                  1
;                   2                  4
;                   3                  6
;
; Entry:      C = Channel Index (0..3)
; Exit:       [No value]
; Registers:  A,BC,HL 
; ------------------------------------------------------------------------------
CTC_INIT:
	LD	C,0x00			; Initiate timer 0
	CALL	CTC_CFG
	LD	C,0x01			; Initiate timer 1
	CALL	CTC_CFG
	LD	C,0x02			; Initiate timer 2
	CALL	CTC_CFG
	LD	C,0x03			; Initiate timer 3
	CALL	CTC_CFG
	RET

CTC_CFG:
	LD	B,0x00			; Clear B
	SLA	C			; Multiply timer index by two
	LD	HL,CTC_TBL		; Load timer table start to HL
	ADD	HL,BC			; Add desired timer offset to HL
	LD	C,(HL)			; Load address
	INC	HL			; Point to config byte

	LD	A,CTC_DEFAULT_CONF	; Set default values
	LD	(HL),A			; Save config

	INC	A			; Set temporary bit 0, 1 = Control
	OUT	(C),A			; Execute

	XOR	A			; Set interrupt vector
	OUT	(C),A
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Enable interrupts for a channel
; Name:       CTC_ENABLE_INT
;
; Entry:      C = Channel Index (0..3)
; Exit:       [No value]
; Registers:  A,BC,HL 
; ------------------------------------------------------------------------------
CTC_ENABLE_INT:
	LD	B,0x00			; Clear B
	SLA	C			; Multiply timer index by two
	LD	HL,CTC_TBL		; Load timer table start to HL
	ADD	HL,BC			; Add desired timer offset to HL
	LD	C,(HL)			; Load address
	INC	HL			; Point to config byte

	SET	7,(HL)			; Set interrupt bit
	LD	A,(HL)			; Load config to A

	INC	A			; Set temporary bit 0, 1 = Control
	OUT	(C),A			; Execute
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Disable interrupts for a channel
; Name:       CTC_DISABLE_INT
;
; Entry:      C = Channel Index (0..3)
; Exit:       [No value]
; Registers:  A,BC,HL
; ------------------------------------------------------------------------------
CTC_DISABLE_INT:
	LD	B,0x00			; Clear B
	SLA	C			; Multiply timer index by two
	LD	HL,CTC_TBL		; Load timer table start to HL
	ADD	HL,BC			; Add desired timer offset to HL
	LD	C,(HL)			; Load address
	INC	HL			; Point to config byte

	RES	7,(HL)			; Clear interrupt bit
	LD	A,(HL)			; Load config to A

	INC	A			; Set temporary bit 0, 1 = Control
	OUT	(C),A			; Execute
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Title:      Set a channel time constant value
; Name:       CTC_SET_VAL
;
; Entry:      D = Time Constant Value, C = Channel Index (0..3)
; Exit:       [No value]
; Registers:  A,BC,D,HL 
; ------------------------------------------------------------------------------
CTC_SET_VAL:
	LD	B,0x00			; Clear B
	SLA	C			; Multiply timer index by two
	LD	HL,CTC_TBL		; Load timer table start to HL
	ADD	HL,BC			; Add desired timer offset to HL
	LD	C,(HL)			; Load address
	INC	HL			; Point to config byte

	LD	A,(HL)			; Load config to A
	SET	2,A			; Time constant follows
	INC	A			; Set temporary bit 0 = Control
	OUT	(C),A			; Execute
	OUT	(C),D			; Set time constant value
	RET
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; END: Driver
; ------------------------------------------------------------------------------
