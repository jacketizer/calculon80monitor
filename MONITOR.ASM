; DEVICE ADDRESSES
; ----------------
BANK		EQU	0x00	; Bank Switching Device
OUTP		EQU	0x0C	; Output Port A
OUT_A		EQU	0x0C	; Output Port A
DART_D		EQU	0x10	; Z80DART Data register
DART_C		EQU	0x11	; Z80DART Control register
HDD_DATA	EQU	0x18	; IDE Host interface - Data
HDD_ERROR	EQU	0x19	; IDE Host interface - Error
HDD_SECT_COUNT	EQU	0x1A	; IDE Host interface - Sector count
HDD_SECTOR	EQU	0x1B	; IDE Host interface - Sector number
HDD_CYLINDER1	EQU	0x1C	; IDE Host interface - Cyliner low
HDD_CYLINDER2	EQU	0x1D	; IDE Host interface - Cyliner high
HDD_HEAD	EQU	0x1E	; IDE Host interface - Head/Device
HDD_STATUS	EQU	0x1F	; IDE Host interface - Status
HDD_CMD		EQU	0x1F	; IDE Host interface - Command
HDD_DATA2	EQU	0x20	; IDE Host interface, High 8-bit
STACK		EQU	0xFFFF	; Start of stack

; PROGRAM START
; -----------------------------------------------------------------------------
	ORG	0	; Use this address in case of stand alone program
	;ORG	0xE000	; Use this address in case of ROM resident program
PRG:	EQU	$
; -----------------------------------------------------------------------------

	; DISPLAY 02H
	LD	A,0x02
	OUT	(OUTP),A

	; SWITCH OUT ROM
	LD	A,1
	OUT	(BANK),A

	; Set Stack Pointer
	LD	SP,STACK

	; Run
	JP	RUN_DART

; ASCII Definitions
NULL	 	EQU	0x00
BELL		EQU	0x07
CLRSCR		EQU	0x0C
ASCII_CR	EQU	0x0D
ASCII_LF	EQU	0x0A
ASCII_BS	EQU	0x08
ASCII_TAB	EQU	0x09
ASCII_CRLF	EQU	0x0D0A

; Welcome text
WTEXT:	DB	"J89 Computer ROM Monitor Version 0.2.8"
	DEFB	NULL

; Promt text
PROMPT:	DB	"CALCULON/80> "
	DEFB	BELL	; Bell
	DEFB	NULL

; Copyright text
CTEXT:	DB	"Copyright (c) 2016-2017 Jack Engqvist Johansson"
	DEFW	ASCII_CRLF
	DEFB	NULL

; Help text
HTEXT:	DB	"Available commands:"
	DEFW	ASCII_CRLF
	DEFW	ASCII_CRLF
	DB	"  HELP"
	DEFW	ASCII_CRLF
	DB	"  LOAD)"
	DEFW	ASCII_CRLF
	DB	"  RESET"
	DEFW	ASCII_CRLF
	DB	"  DISKS"
	DEFW	ASCII_CRLF
	DB	"  DISKID"
	DEFW	ASCII_CRLF
	DB	"  DSKCAL"
	DEFW	ASCII_CRLF
	DB	"  DSKWR"
	DEFW	ASCII_CRLF
	DB	"  DSKRD"
	DEFW	ASCII_CRLF
	DEFB	NULL

; Invalid command text
ITEXT:	DB	"Invalid command"
	DEFB	NULL

; Commands:
CMDTBL	EQU	$
C_HLP:	DB	"HELP"
	DEFB	NULL
C_LOAD:	DB	"LOAD"
	DEFB	NULL
C_DSKS:	DB	"DISKS"
	DEFB	NULL
C_DSKID:	DB	"DISKID"
	DEFB	NULL
C_DSKCAL:	DB	"DSKCAL"
	DEFB	NULL
C_DSKWR:	DB	"DSKWR"
	DEFB	NULL
C_DSKRD:	DB	"DSKRD"
	DEFB	NULL
C_RST:	DB	"RESET"
	DEFB	NULL


; SETUP DART
; -----------------------------------------------------------------------------
RUN_DART:
	LD	C,DART_C	; Reset DART
	CALL	DART_RST

	; 8 bits/char, enable Rx
	LD	A,3
	OUT	(DART_C),A
	LD	A,0b11000001
	OUT	(DART_C),A
	
	; 8 bits/char, enable Tx, RTS
	LD	A,5
	OUT	(DART_C),A
	LD	A,0b01101010
	OUT	(DART_C),A

	; Parity and clock speed
	LD	A,4
	OUT	(DART_C),A
	LD	A,0b10001111	; x32 clock speed, 2 stop bits, even parity
	OUT	(DART_C),A

; PRINT WELCOME TEXT
; -----------------------------------------------------------------------------
	LD	A,CLRSCR	; Clear screen
	CALL	PRINT
	LD	HL,WTEXT
	CALL	PRL
	LD	HL,CTEXT
	CALL	PRL
	LD	HL,HTEXT
	CALL	PRL

; CONSOLE COMMAND PROCESSOR
; -----------------------------------------------------------------------------
CMD_P:	DEFS	2	; Pointer to command buffer next char
CMD_W:	DS	128	; Command buffer

CMD:	EQU	$
	; Print prompt
	LD	HL,PROMPT
	CALL	PR
	; Reset cmd word pointer
	LD	HL,CMD_W
	LD	(CMD_P),HL
	; NULL terminate
	XOR	A
	LD	(CMD_W),A

	; Read char
RCHR:	CALL	READ
	LD	C,A		; Backup char in register C
	; Check if not letter
	AND	A
	LD	A,C
	CP	20
	JR	C,NCHR
	; Echo back
	CALL	PRINT
	; Letter, store it
	LD	A,C
	LD	HL,(CMD_P)	; Store char
	LD	(HL),A
	INC	HL		; Increase pointer
	LD	(HL),NULL	; NULL terminate
	LD	(CMD_P),HL	; Store pointer
	JR	RCHR		; Next character

	; Not letter, check if CR or BS
NCHR:	EQU	$
	AND	A		; Check if BS
	LD	A,C
	CP	ASCII_BS
	JP	Z,BSPACE	; Backspace
	AND	A		; Check if CR
	LD	A,C
	CP	ASCII_CR
	JP	NZ,RCHR		; Not CR, next char
	; Enter was pressed
	LD	A,ASCII_CR
	CALL	PRINT
	LD	A,ASCII_LF
	CALL	PRINT
	; Try DISKID command:
	LD	HL,CMD_W	; Point to start of string 1
	LD	DE,C_DSKID	; Point to start of string 2
	LD	C,6
	CALL	SNCMP
	JP	JID
	; Try DISKS command:
	LD	HL,CMD_W	; Point to start of string 1
	LD	DE,C_DSKS	; Point to start of string 2
	LD	C,5
	CALL	SNCMP
	JP	JDSKS
	; Try DISKCAL command:
	LD	HL,CMD_W	; Point to start of string 1
	LD	DE,C_DSKCAL	; Point to start of string 2
	CALL	SCMP
	JP	JCAL
	; Try DSKWR command:
	LD	HL,CMD_W	; Point to start of string 1
	LD	DE,C_DSKWR	; Point to start of string 2
	LD	C,5		; Length of comparison
	CALL	SNCMP
	JP	JDSKWR
	; Try DSKRD command:
	LD	HL,CMD_W	; Point to start of string 1
	LD	DE,C_DSKRD	; Point to start of string 2
	LD	C,5		; Length of comparison
	CALL	SNCMP
	JP	JDSKRD
	; Try DSKCAL command:
	LD	HL,CMD_W	; Point to start of string 1
	LD	DE,C_DSKCAL	; Point to start of string 2
	LD	C,6		; Length of comparison
	CALL	SNCMP
	JP	JCAL
	; Try LOAD command:
	LD	HL,CMD_W	; Point to start of string 1
	LD	DE,C_LOAD	; Point to start of string 2
	LD	C,4		; Length of comparison
	CALL	SNCMP
	JP	JLOAD
	; Invalid command
	LD	HL,CMD_W
	CALL	PR
	LD	A,63		; ?
	CALL	PRINT
	LD	A,ASCII_CR
	CALL	PRINT
	LD	A,ASCII_LF
	CALL	PRINT
	JP	CMD

; BACKSPACE
BSPACE:	LD	HL,(CMD_P)
	DEC	HL
	LD	(CMD_P),HL
	LD	A,65
	CALL	PRINT
	JP	RCHR

; PRINT HELP TEXT
JHELP:	LD	HL,HTEXT
	CALL	PRL
	JP	CMD

; WARM BOOT
JRST:	JP	PRG

; LIST DISK STATUS
; ----------------
OK_TXT		DB	"  [ ] "
		DEFB	NULL
FAIL_TXT	DB	"  [x] "
		DEFB	NULL

STATUS_TXT	DB	"Checking status..."
		DEFW	ASCII_CRLF
		DEFB	NULL

DISK_ERR_0	DB	"ERR   ERROR"
		DEFB	NULL
DISK_ERR_1	DB	"IDX   INDEX"
		DEFB	NULL
DISK_ERR_2	DB	"CORR  CORRECTED DATA"
		DEFB	NULL
DISK_ERR_3	DB	"DRQ   DATA REQUEST"
		DEFB	NULL
DISK_ERR_4	DB	"DSC   DEVICE SEEK COMPLETE"
		DEFB	NULL
DISK_ERR_5	DB	"DF    DEVICE FAULT"
		DEFB	NULL
DISK_ERR_6	DB	"DRDY  DEVICE READY"
		DEFB	NULL
DISK_ERR_7	DB	"BSY   BUSY"
		DEFB	NULL

READING_TXT:	DB	"Reading..."
		DEFB	NULL
DONE_TXT:	DB	"Done"
		DEFB	NULL
EMPTY_TXT:	DB	NULL

DSK_ID:	DS	0xFF
DSK_C:	DB	0xFF

JDSKS:	EQU	$
	LD	HL,STATUS_TXT
	CALL	PRL

	CALL	DSK_ST
	LD	C,A

	BIT	7,C
	CALL	Z,DISK_OK
	CALL	NZ,DISK_ERR
	LD	HL,DISK_ERR_7
	CALL	PRL

	BIT	0,C
	CALL	Z,DISK_OK
	CALL	NZ,DISK_ERR
	LD	HL,DISK_ERR_0
	CALL	PRL

	BIT	1,C
	CALL	Z,DISK_OK
	CALL	NZ,DISK_ERR
	LD	HL,DISK_ERR_1
	CALL	PRL

	BIT	2,C
	CALL	Z,DISK_OK
	CALL	NZ,DISK_ERR
	LD	HL,DISK_ERR_2
	CALL	PRL

	BIT	3,C
	CALL	Z,DISK_OK
	CALL	NZ,DISK_ERR
	LD	HL,DISK_ERR_3
	CALL	PRL

	BIT	4,C
	CALL	Z,DISK_OK
	CALL	NZ,DISK_ERR
	LD	HL,DISK_ERR_4
	CALL	PRL

	BIT	5,C
	CALL	Z,DISK_OK
	CALL	NZ,DISK_ERR
	LD	HL,DISK_ERR_5
	CALL	PRL

	BIT	6,C
	CALL	Z,DISK_OK
	CALL	NZ,DISK_ERR
	LD	HL,DISK_ERR_6
	CALL	PRL

	LD	HL,EMPTY_TXT
	CALL	PRL

	CALL	DSK_ST
	CALL	PR_BINARY
	CALL	DSK_ERR
	CALL	PR_BINARY

	LD	HL,EMPTY_TXT
	CALL	PRL
	RET
	JP	CMD

DISK_OK:
	LD	HL,OK_TXT
	CALL	PR
	RET

DISK_ERR:
	LD	HL,FAIL_TXT
	CALL	PR
	RET

; PRINT DISK INFO
; ---------------
DSK_INF_TXT	DB	"Reading disk info..."
		DEFB	NULL
DSK_INF_TXT2	DB	"Please wait..."
		DEFB	NULL
DSK_INF_PR_TXT	DB	"Printing disk info..."
		DEFB	NULL
JID:	EQU	$
	LD	HL,DSK_INF_TXT
	CALL	PRL
	LD	A,0xEC		; Identify drive
	OUT	(HDD_CMD),A	; IDE Register $7
;	LD	HL,DSK_INF_TXT2
;	CALL	PRL

	XOR	A
	XOR	A

	CALL	JDSKS
	CALL	DSK_ST
	LD	C,A
	BIT	7,C
	JP	NZ,$-3

	; READ 256 Sectors (512 bytes)
	LD	D,0xFF
	LD	HL,DSK_INF	; Where to store it
HDD_ID:	EQU	$
	IN	A,(HDD_DATA)	; Low byte
	CALL	PRINT
	LD	C,A
	IN	A,(HDD_DATA2)	; High byte
	CALL	PRINT
	LD	(HL),A
	INC	HL
	LD	(HL),C
	INC	HL
	DEC	D
	JP	Z,PR_ID
	JR	HDD_ID

PR_ID:	EQU	$
	LD	HL,DSK_INF_PR_TXT
	CALL	PRL
	LD	HL,DSK_INF	; Where to store it
	LD	DE,0x0036
	ADD	HL,DE		; Offset in dsk_info
	LD	D,0x28		; Number of bytes, 40 (0x28)
PR_ID2:	LD	A,(HL)
	CALL	PRINT
	INC	HL
	LD	A,(HL)
	CALL	PRINT
	INC	HL
	DEC	D
	JP	Z,CMD
	JR	PR_ID2

DSK_INF	EQU	$
	DEFS	512

; RECALIBRATE DISK
JCAL:	EQU	$
	; Set CHS 0
	LD	A,0x01
	OUT	(0x1B),A	; IDE Register $3
	; Set LBA 1
	LD	A,0x00
	OUT	(0x1C),A	; IDE Register $4
	; Set LBA 2
	LD	A,0x00
	OUT	(0x1D),A	; IDE Register $5
	; Set LBA 3
	LD	A,0x00		; Addr 0 and Master and LBA
	OUT	(0x1E),A	; IDE Register $6
	; Set number of sectors
	LD	A,0x01
	OUT	(0x1A),A	; IDE Register $2
	; Send recalibrate command
	LD	A,0x10		; Write sectors
	OUT	(0x1F),A	; IDE Register $7

	JP	CMD

; WRITE 256 WORDS TO SECTOR ONE
DSKWR_TXT	DB	"Writing to disk..."
		DEFW	ASCII_CRLF
		DEFB	NULL
DSKWT_TXT	DB	"Waiting for disk..."
		DEFW	ASCII_CRLF
		DEFB	NULL
JDSKWR:	EQU	$
	LD	HL,DSKWR_TXT
	CALL	PRL
	;
	LD	A,0x01
	OUT	(HDD_SECT_COUNT),A
	;
	LD	A,0x01
	OUT	(HDD_SECTOR),A
	;
	LD	A,0x01
	OUT	(HDD_CYLINDER1),A
	; 
	LD	A,0x00
	OUT	(HDD_CYLINDER2),A
	;
	LD	A,0x01
	OUT	(HDD_HEAD),A
	; Send write command
	LD	A,0x30		; Write sectors
	OUT	(HDD_CMD),A

	XOR	A

	; Wait for BSY 0
;	CALL	DSK_ST
;	BIT	7,A
;	JP	NZ,$ - 2
	; Wait for DRQ 1
;	CALL	DSK_ST
;	BIT	3,A
;	JP	Z,$ - 2

	XOR	A

	LD	A,'U'
	OUT	(HDD_DATA),A
	; WRITE 256 WORDS
	LD	B,0xFF
HDD_WR:	EQU	$
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	LD	A,'S'
	OUT	(HDD_DATA),A
	LD	A,'.'
	CALL	PRINT
	DEC	B
	JP	Z,HDD_WR_DONE
	JR	HDD_WR
HDD_WR_DONE:
	LD	HL,DONE_TXT
	CALL	PRL
	JP	CMD

; READ 256 WORDS FROM SECTOR ONE
DSKRD_TXT	DB	"Reading from disk..."
		DEFW	ASCII_CRLF
		DEFB	NULL
DSK_ERR_TXT	DB	"Error!"
		DEFB	NULL
JDSKRD:	EQU	$
	LD	HL,DSKRD_TXT
	CALL	PRL
	;
	LD	A,0x01
	OUT	(HDD_SECT_COUNT),A
	;
	LD	A,0x01
	OUT	(HDD_SECTOR),A
	;
	LD	A,0x01
	OUT	(HDD_CYLINDER1),A
	; 
	LD	A,0x00
	OUT	(HDD_CYLINDER2),A
	;
	LD	A,0x01
	OUT	(HDD_HEAD),A
	; Send read command
	LD	A,0x20		; Read sectors
	OUT	(HDD_CMD),A	; IDE Register $7

	LD	B,0xFF
LOOP89:	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	XOR	A
	DEC	B
	JR	NZ,LOOP89

	; READ 256 WORDS
	IN	A,(HDD_DATA)
	CALL	PRINT
	IN	A,(HDD_DATA)
	CALL	PRINT
	LD	B,0xFF
HDD_RD:	EQU	$
	XOR	A
	XOR	A
	XOR	A
	IN	A,(HDD_DATA)
	CALL	PRINT
	DEC	B
	JP	Z,HDD_RD_DONE
	JP	HDD_RD
HDD_RD_DONE:
	LD	HL,DONE_TXT
	CALL	PRL
	JP	CMD
HDD_RD_ERR:
	LD	HL,DSK_ERR_TXT
	CALL	PRL
	JP	CMD


; LOAD DATA FROM SERIAL
SER_COUNT:	DW	0x0FFF
SER_DATA:	DW	0x0000
JLOAD:	EQU	$
	LD	BC,0x0FFF
	LD	(SER_COUNT),A
	LD	HL,0x0000
	LD	(SER_DATA),HL

JLOAD_NEXT:	EQU	$
	CALL	READ
	LD	HL,(SER_DATA)
	LD	(HL),A
	INC	HL
	LD	(SER_DATA),HL

	LD	A,(SER_COUNT)
	DEC	BC
	LD	A,B
	OR	C
	JP	Z,JLOAD_RUN
	LD	(SER_COUNT),BC
	LD	A,'.'		; Dot (.)
	CALL	PRINT
	JR	JLOAD_NEXT

JLOAD_RUN:	EQU	$
	CALL	0x0000
	JP	PRG


; DISK DRIVER

; DISK STATUS
; =============================================================================
; Reads the disk status. Result in register A.
; -----------------------------------------------------------------------------
DSK_ST:		EQU	$
		IN	A,(HDD_STATUS)	; Register 7
		RET
; -----------------------------------------------------------------------------

; DISK ERROR
; =============================================================================
; Reads the disk error register. Result in register A.
; -----------------------------------------------------------------------------
DSK_ERR:	EQU	$
		IN	A,(HDD_ERROR)	; Register 1
		RET
; -----------------------------------------------------------------------------


; DART DEVICE DRIVER

; RESET DART
; =============================================================================
; Resets the DART at startup or error condition. Dart control register address
; in C register.
; -----------------------------------------------------------------------------
DART_RST:	EQU	$
		LD	A,0b00011000	; Channel reset
		OUT	(C),A
		RET
; -----------------------------------------------------------------------------

; RESET ERROR DART
; =============================================================================
; Resets the DART at startup or error condition. Dart control register address
; in C register.
; -----------------------------------------------------------------------------
DART_ERR_RST:	EQU	$
		LD	A,0b00110000	; Error reset
		OUT	(C),A
		RET
; -----------------------------------------------------------------------------

; WRITE CHARACTER
; =============================================================================
; Prints a character stored in A. Blocks until character is sent.
; -----------------------------------------------------------------------------
; TODO: Make sure that TxBuffer is empty, polling...
PRINT:	OUT	(DART_D),A
	CALL	ISSENT
	RET
ISSENT: LD	A,1
	OUT	(DART_C),A
	IN	A,(DART_C)
	BIT	0,A
	JR	Z,ISSENT
	RET
; -----------------------------------------------------------------------------

; READ CHARACTER
; =============================================================================
; Reads character from serial and stores it in A. Blocking.
; -----------------------------------------------------------------------------
READ:	EQU	$
	; DISPLAY 00H
	LD	A,0x00
	OUT	(OUTP),A
	; Error check
	;LD	C,DART_C
	;CALL	DART_ERR_CHK
	;JP	READ_ERR	; Errors, reset DART
	LD	A,1
	OUT	(DART_C),A
	IN	A,(DART_C)
	BIT	4,A
	JR	NZ,READ_ERR	; Parity error
	BIT	6,A
	JR	NZ,READ_ERR	; Framing error
	; Character available check
	;LD	C,DART_C
	;CALL	DART_CHR_CHK
	LD	A,0
	OUT	(DART_C),A
	IN	A,(DART_C)
	BIT	0,A
	JR	Z,READ
	IN	A,(DART_D)
	RET
READ_ERR:
	LD	A,0x55
	OUT	(OUTP),A	; Display ERROR
	LD	C,DART_C
	CALL	DART_ERR_RST	; Error reset
	IN	A,(DART_D)	; Read faulty character
	JR	READ
; -----------------------------------------------------------------------------

; CHECK FOR CHARACTER
; =============================================================================
; Checks the DART for avaiable character. Dart control register address in C
; register.
; -----------------------------------------------------------------------------
DART_CHR_CHK:	EQU	$
		LD	A,0
		OUT	(C),A
		IN	A,(C)
		BIT	0,A	; Check if char is available
		RET	Z	; No, return
		POP	HL	; Yes
		INC	HL
		PUSH	HL
		RET
; -----------------------------------------------------------------------------

; CHECK FOR DART ERRORS
; =============================================================================
; Checks the DART for receiver errors. Dart control register address in C
; register. On error, return, otherwise jump over next instruction.
; -----------------------------------------------------------------------------
DART_ERR_CHK:	EQU	$
		LD	A,1
		OUT	(C),A
		IN	A,(C)
		BIT	4,A
		RET	NZ	; Parity error
		BIT	6,A
		RET	NZ	; Framing error
		POP	HL	; No errors
		INC	HL
		PUSH	HL
		RET
; -----------------------------------------------------------------------------


; FUNCTIONS

; STRING COMPARE
; =============================================================================
; Compare two strings pointed to by HL and DE.
; -----------------------------------------------------------------------------
SCMP:	EQU	$
	AND	A
TRY:	LD	A,(DE)		; Load test character
	CPI			; Test it against HL, and increase HL
	JR	NZ,NEQL		; Jump if mismatch
	AND	A		; Check for NULL
	RET	Z		; Return if NULL
	INC	DE
	JR	TRY		; Next character
NEQL:	POP	HL		; Not equal, return
	INC	HL
	PUSH	HL
	RET
; -----------------------------------------------------------------------------

; STRING COMPARE LIMITED BY LENGTH
; =============================================================================
; Compare two strings pointed to by HL and DE. Max length in C.
; -----------------------------------------------------------------------------
SNCMP:	EQU	$
	AND	A
SNCMP_TRY:
	LD	A,(DE)		; Load test character
	CPI			; Test it against HL, and increase HL
	JR	NZ,SNCMP_NEQL	; Jump if mismatch
	DEC	C		; Check C
	RET	Z		; Return if 0
	AND	A		; Check for NULL
	RET	Z		; Return if NULL
	INC	DE
	JR	SNCMP_TRY	; Next character
SNCMP_NEQL:
	POP	HL		; Not equal, return
	INC	HL
	PUSH	HL
	RET
; -----------------------------------------------------------------------------

; PRINT LINE
; =============================================================================
; Prints line until NULL character, address to first byte in HL.
; -----------------------------------------------------------------------------
PRL:	EQU	$
	CALL	PR
	LD	A,ASCII_CR	; CR
	CALL	PRINT
	LD	A,ASCII_LF	; LF
	CALL	PRINT
	RET
; -----------------------------------------------------------------------------

; PRINT BYTE AS BINARY
; =============================================================================
; -----------------------------------------------------------------------------
PR_BINARY	EQU	$
	LD	C,A
	LD	B,A

	LD	C,B
	BIT	7,C
	CALL	Z,PR_ZER
	LD	C,B
	BIT	7,C
	CALL	NZ,PR_ONE

	LD	C,B
	BIT	6,C
	CALL	Z,PR_ZER
	LD	C,B
	BIT	6,C
	CALL	NZ,PR_ONE

	LD	C,B
	BIT	5,C
	CALL	Z,PR_ZER
	LD	C,B
	BIT	5,C
	CALL	NZ,PR_ONE

	LD	C,B
	BIT	4,C
	CALL	Z,PR_ZER
	LD	C,B
	BIT	4,C
	CALL	NZ,PR_ONE

	LD	C,B
	BIT	3,C
	CALL	Z,PR_ZER
	LD	C,B
	BIT	3,C
	CALL	NZ,PR_ONE

	LD	C,B
	BIT	2,C
	CALL	Z,PR_ZER
	LD	C,B
	BIT	2,C
	CALL	NZ,PR_ONE

	LD	C,B
	BIT	1,C
	CALL	Z,PR_ZER
	LD	C,B
	BIT	1,C
	CALL	NZ,PR_ONE

	LD	C,B
	BIT	0,C
	CALL	Z,PR_ZER
	LD	C,B
	BIT	0,C
	CALL	NZ,PR_ONE

	LD	A,C
	RET

PR_ZER:	LD	A,'0'
	CALL	PRINT
	RET

PR_ONE:	LD	A,'1'
	CALL	PRINT
	RET
; -----------------------------------------------------------------------------

; PRINT STRING
; =============================================================================
; Prints string until NULL character, address to first byte in HL.
; -----------------------------------------------------------------------------
PR:	EQU	$
	LD	A,(HL)
	; Check if NULL terminator
	AND	A
	RET	Z	; Finished
	; Print
	CALL	PRINT
	INC	HL
	JR	PR
; -----------------------------------------------------------------------------

; PRINT STRING
; =============================================================================
; Prints string, address to first byte in HL, and last byte in BC.
; -----------------------------------------------------------------------------
PR2:	EQU	$
	LD	A,(HL)
	; Print
	CALL	PRINT
	; Increase pointer
	INC	HL
	; Check end of string
	AND	A		; Clear Carry
	SBC	HL,BC
	RET	NC
	JR	PR2
; -----------------------------------------------------------------------------

STOP:	HALT
	JR	STOP

	DS	0x0FFF - $	; Fill up the entire 2732 EPROM
	END
