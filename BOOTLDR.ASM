; DEFINITIONS
; -----------------------------------------------------------------------------
PSTART:	EQU	0x0200
PDEST:	EQU	0xE000
PCOUNT:	EQU	0x0FFF
	ORG	0

; Wait a few nops to make sure that all devices have been brought out of reset
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP

	JR	MAIN

; MEMORY TEST
; -----------------------------------------------------------------------------
MTEXT	DB	"Testing Memory..."
	DEFB	NULL
ETEXT	DB	"Found memory error!"
	DEFB	NULL
DTEXT	DB	"Done"
	DEFB	NULL

ERROR	EQU	$
	LD	HL,ETEXT
	CALL	PRL
	HALT

DONE	EQU	$
	LD	HL,DTEXT
	CALL	PRL
	JR	COPY

MAIN	EQU	$
	LD	HL,MTEXT
	CALL	PRL

	DI

	; Set pointer to 0xFFFF, top of address space
	LD	HL,0xFFFF
TEST	EQU	$
	; Store 0x55
	LD	(HL),0x55
	; Load byte and verify
	LD	A,(HL)
	CP	0x55
	JP	NZ,ERROR
	; Store 0xAA
	LD	(HL),0xAA
	; Load byte and verify
	LD	A,(HL)
	CP	0xAA
	JR	NZ,ERROR
	; Bottom of memory?
	LD	A,0x20
	CP	H	; Check H for 0
	JP	NZ,NEXT
	XOR	A
	CP	L	; Check L for 0
	JP	NZ,NEXT
	JR	DONE
NEXT:	EQU	$
	; Next byte
	DEC	HL
	JR	TEST


; COPY BIOS TO HIGHER RAM 
; -----------------------------------------------------------------------------
COPY	EQU	$
	LD	HL,PSTART	; Source
	LD	DE,PDEST	; Destination
	LD	BC,PCOUNT	; Number of bytes
	LDIR

	JP	PDEST		; Run from higher RAM

	DS	PSTART - $	; Fill up unused space
