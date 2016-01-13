;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sega-xydiag-u25.asm
Sega XY Diagnostic ROM
v1.0 August 22, 2015
David Shuman (davidshuman@gmail.com)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
XPOS	EQU	0e2fch
YPOS	EQU	0e2feh

	LD	SP,0e010h	; have to set valid SP for INT to work
	IM	1
	EI
	HALT				; wait for hardware interrupt
	DI
	JP	INIT
	
	ORG	16h
	;assembler puts stroke instructions in CPU board ROM U25 at 16h
	DEFB	01111001b,05fh,00h,02h
	DEFB	01111001b,02eh,00h,01h
	DEFB	01111001b,05fh,00h,00h
	DEFB	11111001b,02eh,00h,03h	; end 4 strokes for "0"
	DEFB	01111000b,017h,00h,01h
	DEFB	11111001b,05fh,00h,02h	; end 2 strokes for "1"
	DEFB	01111111b,0feh,00h,01h
	DEFB	11111111b,0feh,00h,01h  ; end 2 strokes for line
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ORG	38h			; INT handler
	; interrupts are enabled only immediately before a HALT.
	; by default, return address is that of HALT instruction itself.
	; we want return point to be the next byte after HALT:
	POP	DE
	INC	DE
	PUSH	DE
	RETI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ORG	66h			; NMI handler
	JP	CHANGE_COLOR		; NMI causes grid color to change
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ORG	70h		; LED flash_word lookup table
	DEFB	16h,0eh		; 1 flash, long pause = all RAM good
	DEFB	16h,1eh		; C.26: 1 flash, 6 spaces, 1 flash, 14 sp
	DEFB	16h,2eh		; C.27 (1,2)
	DEFB	16h,3eh		; C.28 (1,3)
	DEFB	16h,4eh		; C.29 (1,4)
	DEFB	26h,1eh		; V.31 (2,1)
	DEFB	26h,2eh		; V.30 (2,2)
	DEFB	26h,3eh		; V.29 (2,3)
	DEFB	26h,4eh		; V.28 (2,4)
	DEFB	36h,1eh		; V.27 (3,1)
	DEFB	36h,2eh		; V.26 (3,2)
	DEFB	36h,3eh		; V.25 (3,3)
	DEFB	36h,4eh		; V.24 (3,4)	
	DEFB	46h,1eh		; S.51 (4,1)
	DEFB	46h,2eh		; S.50 (4,2)
	DEFB	46h,3eh		; reserved (4,3)
	DEFB	46h,4eh		; reserved (4,4)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ORG	0a0h
INIT:
	LD	A,81h
	LD	HL,0e000h
	LD	(HL),A		; blank the screen
	LD	A,0ffh		; LSB must be 1 for panel switch read
	OUT	(0f8h),A	; read panel switches, not spinner
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN:	
	CALL	CPU_RAM_U26
	CALL	CPU_RAM_U27
	CALL	CPU_RAM_U28
	CALL	CPU_RAM_U29	
	CALL	VRAM_U31
	CALL	VRAM_U30
	CALL	VRAM_U29
	CALL	VRAM_U28
	CALL	VRAM_U27
	CALL	VRAM_U26
	CALL	VRAM_U25
	CALL	VRAM_U24
	CALL	SOUND_RAM_U51
	CALL	SOUND_RAM_U50
	LD	SP,0e400h	; relocate stack
				; load the stroke table into VRAM
	LD	BC,32		; 32 bytes to load
	LD	DE,0e316h	; pointer to LDI destination
	LD	HL,00016h	; pointer to LDI source 
	LDIR			; load 32 bytes at $E316
	CALL	DRAW_STATUS_WORD	; draw results of RAM tests
	JP	INIT_FLASH		; flash RAM test results on LED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_GRID:
	LD	IX,0e000h	; address of first 10-byte symbol word
				; horiz lines
	LD	HL,541		; draw from left edge to right
	LD	(XPOS),HL
	LD	HL,1431		; draw from top to bottom
	LD	(YPOS),HL
	LD	B,12		; make this many horizontal lines
	CALL	DRAW_HORIZ
	CALL	CENTER_BEAM
				; vert lines
	LD	HL,1503		; draw from right to left
	LD	(XPOS),HL
	LD	HL,1430		; draw from top to bottom
	LD	(YPOS),HL
	LD	B,15		; draw this many vertical lines
	CALL	DRAW_VERT
	CALL	CENTER_BEAM
	
	CALL	FLAG_LAST_SYMBOL_INSTRUCTION
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_HORIZ:
	LD	(IX+0),21h	; 21h: symbol_group=2, draw=1=yes
	LD	HL,(XPOS)
	LD	(IX+1),L
	LD	(IX+2),H	; bytes 2-3 are x-address, low byte first
	LD	HL,(YPOS)
	LD	(IX+3),L
 	LD	(IX+4),H	; bytes 4-5 are y-address, low byte first
	LD	HL,0e32eh
	LD	(IX+5),L
	LD	(IX+6),H	; bytes 6-7 are pointer to first line of stroke instructions
	LD	(IX+7),0	; bytes 8-9 are rotation bytes, first byte always 0
	LD	(IX+8),0	; no rotation of this symbol
	LD	(IX+9),0f2h	; tenth byte is scale/size

	LD	DE,10
	ADD	IX,DE		; increment index address by 10
	
	LD	HL,(YPOS)	; put current y-address in HL
	LD	DE,-74		; new y-address will be y-74
	ADD	HL,DE		; add DE to HL, put result in HL
	LD	(YPOS),HL	; store new y-address

	DJNZ	DRAW_HORIZ	; decrement line counter, loop again if not 0
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_VERT:
	LD	(IX+0),31h	; 31h:  symbol_group=3, draw=1=yes
	LD	HL,(XPOS)
	LD	(IX+1),L
	LD	(IX+2),H	; bytes 2-3 are x-address, low byte first
	LD	HL,(YPOS)
	LD	(IX+3),L
	LD	(IX+4),H	; bytes 4-5 are y-address, low byte first
	LD	HL,0e32eh
	LD	(IX+5),L
	LD	(IX+6),H	; bytes 6-7 are pointer to first line of stroke instructions
	LD	(IX+7),0	; bytes 8-9 are rotation bytes, first byte always 0
	LD	(IX+8),1	; all strokes in this symbol rotated 90 deg cw
	LD	(IX+9),0ceh	; tenth byte is scale/size
	
	LD	DE,10
	ADD	IX,DE		; increment index address by 10
	
	LD	HL,(XPOS)	; put current x-address in HL
	LD	DE,-74		; new x-address will be x-74
	ADD	HL,DE
	LD	(XPOS),HL	; store new x-address

	DJNZ	DRAW_VERT	; decrement line counter, loop again if not 0
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CENTER_BEAM:
	; return beam to center 
	LD	(IX+0),41h	; symbol_group=4, draw=1=yes
	LD	(IX+1),0
	LD	(IX+2),4	; xpos = 400h
	LD	(IX+3),0
	LD	(IX+4),4	; ypos = 400h
	LD	(IX+5),32h
	LD	(IX+6),0e3h
	LD	(IX+7),0
	LD	(IX+8),0
	LD	(IX+9),1	; size/scale = 1, draws a dot
	
	LD	DE,10
	ADD	IX,DE		; increment index address by 10
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FLAG_LAST_SYMBOL_INSTRUCTION:
	LD	DE,-10
	ADD	IX,DE		; decrement index address by 10
	SET	7,(IX+0)	; set bit 7 at address IX+0
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
POLL:
	IN	A,(0f9h)	; read state of P1 Start (E2P,SF)
	BIT	5,A		; button pressed? (E2P,SF)
	JR	Z,CHANGE_COLOR	; port 0xf9 is active LOW
	IN	A,(0fch)	; read state of P1 Start (ST,Z,TS)
	BIT	0,A		; button pressed?  (ST,Z,TS)
	JR	NZ,CHANGE_COLOR	; port 0xfc is active HIGH
	JR	POLL		; if not, continue polling
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHANGE_COLOR:
	; see if we're in test mode, and if so, switch to grid mode
	LD	A,(0e000h)	; load first byte of symbol table
	CP	11h		; A=11h? (it is if we've been in RAM test mode)
	JR	NZ,TEST_GRID_COLOR	; if not, jump ahead
	CALL	DRAW_GRID	; else, draw the grid
	LD	C,232
	CALL	DELAY		; debounce and delay
	JR	POLL
TEST_GRID_COLOR:	
	LD	A,(0e32eh)	; this location has current color of grid
CASE_WHITE:
		LD	B,01111111b
		CP	B
		JR	NZ,CASE_RED
		LD	A,110000b	; next color is red
		JR	END_CASE
CASE_RED:
		LD	B,01100001b
		CP	B
		JR	NZ,CASE_GREEN
		LD	A,001100b	; next color is green
		JR	END_CASE
CASE_GREEN:
		LD	B,00011001b
		CP	B
		JR	NZ,CASE_BLUE
		LD	A,000011b	; next color is blue
		JR	END_CASE
CASE_BLUE:
		LD	B,00000111b
		CP	B
		JR	NZ,CASE_YELLOW
		LD	A,111100b	; next color is yellow
		JR	END_CASE
CASE_YELLOW:
		LD	B,01111001b
		CP	B
		JR	NZ,CASE_PURPLE
		LD	A,110011b	; next color is purple
		JR	END_CASE
CASE_PURPLE:
		LD	B,01100111b
		CP	B
		JR	NZ,CASE_AQUA
		LD	A,001111b	; next color is aqua
		JR	END_CASE
CASE_AQUA:
		LD	A,01111111b	; next color is white
END_CASE:			; change color of 2 strokes in "line"
	RLCA
	SET	0,A		; draw = yes
	RES	7,A		; last stroke = no
	LD	HL,0e32eh	; address of first stroke in "line"
	LD	(HL),A
	SET	7,A		; last stroke = yes
	LD	HL,0e332h	; address of second stroke in "line"
	LD	(HL),A
	
	LD	C,232
	CALL	DELAY		; debounce and delay
	JP	POLL	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY:				; input: C.  Count from 255 to 0, do that C times
	LD	B,255
SUBDELAY:
	DJNZ	SUBDELAY
	DEC	C
	JR	NZ,DELAY
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WRITE_RAM:			; write 256-byte block
				; inputs to this function: B=last byte in block,
				; D=bit pattern, HL=base address
	LD	A,D
	LD	(HL),A		; write byte to RAM
	LD	A,L		; put low byte of address in A
	CP	B		; was this the last byte?
	RET	Z		; if yes, return
	DEC	L		; else, decrement low byte
	JR	WRITE_RAM	; and loop again
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
TEST_2114_NIBBLE:
				; operates on 256-byte block
				; inputs: C=status, D=high byte of base address,
				; B=number of bytes,
				; E=mask: 00001111b tests only D[3..0]
				;         11110000b tests only D[7..4]
				; (mask is used only in read subroutine)
				
	;; first bit pattern -- all AA's
	LD	D,0aah		; bit pattern
	CALL	WRITE_RAM
	LD	L,0ffh		; reset low byte
	CALL	READ_2114_NIBBLE
	
	;; second bit pattern -- all 55's
	LD	D,055h		; bit pattern
	CALL	WRITE_RAM
	LD	L,0ffh		; reset low byte
	CALL	READ_2114_NIBBLE
	
	;; third bit pattern -- all FF's
	LD	D,0ffh		; bit pattern
	CALL	WRITE_RAM
	LD	L,0ffh		; reset low byte
	CALL	READ_2114_NIBBLE
	
	;; fourth bit pattern -- all 00's
	LD	D,0h		; bit pattern
	CALL	WRITE_RAM
	LD	L,0ffh		; reset low byte
	CALL	READ_2114_NIBBLE
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
READ_2114_NIBBLE:		; read high or low nibbles from 256 addresses
				; inputs to this function:  C=status,
				; B=1ast byte in block, HL=base address,
				; E=mask: 00001111b tests only D[3..0]
				;         11110000b tests only D[7..4]
	LD	A,D		; put unmasked bit pattern in A
	AND	E		; apply mask
	LD	D,A		; put masked bit pattern in D
	
	LD	A,(HL)		; load A from address HL
	AND	E		; apply mask - if high nibble is wrong, we don't care
	CP	D		; does A match D?
	RET	NZ		; if not, return without decrementing C
	
	LD	A,L		; put low byte of address in A
	CP	B		; was this the last byte?
	JR	BLOCK_PASSED_2114	; if yes, jump
	DEC	L			; else, decrement low byte
	JR	READ_2114_NIBBLE	; and loop again
BLOCK_PASSED_2114:
	DEC	C		; all of tested nibbles in this block passed
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CPU_RAM_U26:
	; CPU_RAM_U26 stores low nibble of $CC00-$CFFF
	LD	E,00001111b	; CPU U26 is low-nibble RAM so mask high nibble
	LD	C,15
	LD	HL,0ccffh
	CALL	TEST_2114_NIBBLE; each test will subtract 4 from C if successful
	LD	HL,0cdffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0ceffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0cfffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts a 1 in the LSB
	AND	1		; zero all but LSB
	RRCA			; now A = 0000 0000 or 1000 0000
	EXX
	LD	H,A		; bit 7 of H' is status of CPU_RAM_U26
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CPU_RAM_U27:
	; CPU_RAM_U27 stores high nibble of $CC00-$CFFF
	LD	E,11110000b	; CPU U29 is high-nibble RAM so mask low nibble
	LD	C,15
	LD	HL,0ccffh
	CALL	TEST_2114_NIBBLE; each test will subtract 4 from C if successful
	LD	HL,0cdffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0ceffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0cfffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts a 1 in the LSB
	AND	1		; zero all but LSB
	RRCA
	RRCA			; now A = 0000 0000 or 0100 0000
	EXX
	LD	B,A
	LD	A,H
	OR	B
	LD	H,A		; bit 6 of H' is status of CPU_RAM_27
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CPU_RAM_U28:
	; CPU_RAM_U28 stores high nibble of $C800-$CBFF
	LD	E,11110000b	; CPU U28 is high-nibble RAM so mask low nibble
	LD	C,15
	LD	HL,0c8ffh
	CALL	TEST_2114_NIBBLE; each test will subtract 4 from C if successful
	LD	HL,0c9ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0caffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0cbffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 7 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts a 1 in the LSB
	AND	1		; zero all but LSB
	RRCA
	RRCA
	RRCA			; now A = 0000 0000 or 0010 0000
	EXX
	LD	B,A
	LD	A,H
	OR	B
	LD	H,A		; bit 5 of H' is status of CPU_RAM_U28
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CPU_RAM_U29:
	; CPU_RAM_U29 stores low nibble of $C800-$CBFF
	LD	E,00001111b	; CPU U29 is low-nibble RAM so mask high nibble
	LD	C,15
	LD	HL,0c8ffh
	CALL	TEST_2114_NIBBLE; each test will subtract 4 from C if successful
	LD	HL,0c9ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0caffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0cbffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts a 1 in the LSB
	AND	1		; zero all but LSB
	RLCA
	RLCA
	RLCA
	RLCA			; now A = 0000 0000 or 0001 0000
	EXX
	LD	B,A
	LD	A,H
	OR	B
	LD	H,A		; bit 4 of H' is status of CPU_RAM_29
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VRAM_U31:
	; VRAM U31 stores low nibble of $E000-$E3FF
	LD	E,00001111b	; VRAM U31 is low-nibble RAM, so mask high nibble
	
	LD	C,15		; initialize status byte
	LD	B,16		; for $E000 block, stop r/w at $E010
				; (reserve 16 bytes at $E000)
	LD	HL,0e0ffh
	CALL	TEST_2114_NIBBLE
	LD	B,0		; for $E100 block & others, stop r/w at byte $xx00
	LD	HL,0e1ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e2ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e3ffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts a 1 in the LSB
	AND	1		; zero all but LSB
	RLCA
	RLCA
	RLCA			; now A = 0000 0000 or 0000 1000
	EXX
	LD	B,A
	LD	A,H
	OR	B
	LD	H,A		; bit 3 of H' is status of VRAM_U31
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VRAM_U30:
	; VRAM U30 stores low nibble of $E400-$E7FF
	LD	E,00001111b	; VRAM U30 is low-nibble RAM, so mask high nibble
	LD	C,15		; initialize status byte
	LD	B,0		
	LD	HL,0e4ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e5ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e6ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e7ffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts a 1 in the LSB
	AND	1		; zero all but LSB
	RLCA
	RLCA			; now A = 0000 0000 or 0000 0100
	EXX
	LD	B,A
	LD	A,H
	OR	B
	LD	H,A		; bit 2 of H' is status of VRAM_U30
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VRAM_U29:
	; VRAM U29 stores low nibble of $E800-$EBFF
	LD	E,00001111b	; VRAM U29 is low-nibble RAM, so mask high nibble
	
	LD	C,15		; initialize status byte
	LD	B,0
	LD	HL,0e8ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e9ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0eaffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0ebffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts a 1 in the LSB
	AND	1		; zero all but LSB
	RLCA			; now A = 0000 0000 or 0000 0010
	EXX
	LD	B,A
	LD	A,H
	OR	B
	LD	H,A		; bit 1 of H' is status of VRAM_U29
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VRAM_U28:
	; VRAM U28 stores low nibble of $EC00-$EFFF
	LD	E,00001111b	; VRAM U28 is low-nibble RAM, so mask high nibble
	LD	C,15		; initialize status byte
	LD	B,0
	LD	HL,0ecffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0edffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0eeffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0efffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts a 1 in the LSB
	AND	1		; zero all but LSB
	EXX
	LD	B,A
	LD	A,H
	OR	B
	LD	H,A		; bit 0 of H' is status of VRAM_U28
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VRAM_U27:
	; VRAM U27 stores high nibble of $E000-$E3FF
	LD	E,11110000b	; VRAM U27 is high-nibble RAM, so mask low nibble
	
	LD	C,15		; initialize status byte
	LD	B,16		; for $E000 block, stop r/w at $E010
				; (reserve 16 bytes at $E000)
	LD	HL,0e0ffh
	CALL	TEST_2114_NIBBLE
	LD	B,0		; for $E100 block & others, stop r/w at byte $xx00
	LD	HL,0e1ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e2ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e3ffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	
	LD	A,C
	RLCA			; only C=FF puts 1 in LSB
	AND	1		; zero all but LSB
	RRCA			; now A = 0000 0000 or 1000 0000
	EXX
	LD	L,A		; bit 7 of L' is status of VRAM_U27
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VRAM_U26:
	; VRAM U26 stores high nibble of $E400-$E7FF
	LD	E,11110000b	; VRAM U26 is high-nibble RAM, so mask low nibble
	
	LD	C,15		; initialize status byte
	LD	B,0
	LD	HL,0e4ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e5ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e6ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e7ffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts 1 in LSB
	AND	1		; zero all but LSB
	RRCA
	RRCA			; now A = 0000 0000 or 0100 0000
	EXX
	LD	B,A
	LD	A,L
	OR	B
	LD	L,A		; bit 6 of L' is status of VRAM_U26
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VRAM_U25:
	; VRAM U25 stores high nibble of $E800-$EBFF
	LD	E,11110000b	; VRAM U25 is high-nibble RAM, so mask low nibble
	
	LD	C,15		; initialize status byte
	LD	B,0
	LD	HL,0e8ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0e9ffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0eaffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0ebffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts 1 in LSB
	AND	1		; zero all but LSB
	RRCA
	RRCA
	RRCA			; now A = 0000 0000 or 0010 0000
	EXX
	LD	B,A
	LD	A,L
	OR	B
	LD	L,A		; bit 5 of L' is status of VRAM_U25
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VRAM_U24:
	; VRAM U24 stores high nibble of $EC00-$EFFF
	LD	E,11110000b	; VRAM U25 is high-nibble RAM, so mask low nibble
	
	LD	C,15		; initialize status byte
	LD	B,0
	LD	HL,0ecffh
	CALL	TEST_2114_NIBBLE
	LD	B,0		; for $E100 block & others, stop r/w at byte $xx00
	LD	HL,0edffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0eeffh
	CALL	TEST_2114_NIBBLE
	LD	HL,0efffh
	CALL	TEST_2114_NIBBLE
				; C=0ffh if all reads passed
				; C=0 to 15 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts 1 in LSB
	AND	1		; zero all but LSB
	RRCA
	RRCA
	RRCA
	RRCA			; now A = 0000 0000 or 0001 0000
	EXX
	LD	B,A
	LD	A,L
	OR	B
	LD	L,A		; bit 4 of L' is status of VRAM_U24
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TEST_6116_BYTE:			
				; operates on 256-byte block
				; inputs: C=status, H=high byte of base address,
				; L = low byte of base address
	
	; initialize write and let bus and chip select stabilize
	LD	(HL),0aah
	NOP
	NOP
	NOP
	NOP
				
	;; first bit pattern -- all AA's
	LD	D,0aah		; bit pattern
	CALL	WRITE_RAM
	NOP
	NOP
	LD	L,0ffh		; reset low byte
	CALL	READ_6116_BYTE
	
	;; second bit pattern -- all 55's
	LD	D,055h		; bit pattern
	CALL	WRITE_RAM
	NOP
	NOP
	LD	L,0ffh		; reset low byte
	CALL	READ_6116_BYTE
	
	;; third bit pattern -- all FF's
	LD	D,0ffh		; bit pattern
	CALL	WRITE_RAM
	NOP
	NOP
	LD	L,0ffh		; reset low byte
	CALL	READ_6116_BYTE
	
	;; fourth bit pattern -- all 00's
	LD	D,0h		; bit pattern
	CALL	WRITE_RAM
	NOP
	NOP
	LD	L,0ffh		; reset low byte
	CALL	READ_6116_BYTE
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
READ_6116_BYTE:			; read 8-bit bytes from 256 addresses
				; inputs to this function:  C = status,
				; D = bit pattern, HL = address to be read
	;; initialize read, allow bus and chip select to stabilize
	LD	A,(HL)
	NOP
	NOP
	NOP
	NOP
	
	LD	A,D		; put bit pattern in A
	CP	(HL)		; does byte at (HL) match A?
	RET	NZ		; if not, return without decrementing C
	LD	A,L		; put low byte of address in A
	CP	0		; was this the last byte?
	JR	BLOCK_PASSED_6116	; if yes, jump
	DEC	L		; else, decrement low byte
	JR	READ_6116_BYTE	; and loop again
BLOCK_PASSED_6116:				
	DEC	C		; all bytes in this block passed
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SOUND_RAM_U51:
				; U50 stores bytes at $D000-$D7FF
	;; initialize write, allow bus and chip select to stabilize
	LD	HL,0d000h
	LD	(HL),0aah
	NOP
	NOP
	NOP
	NOP
	
	LD	C,31		; initialize status byte
	LD	HL,0d0ffh
	CALL	TEST_6116_BYTE
	LD	HL,0d1ffh
	CALL	TEST_6116_BYTE
	LD	HL,0d2ffh
	CALL	TEST_6116_BYTE
	LD	HL,0d3ffh
	CALL	TEST_6116_BYTE
	LD	HL,0d4ffh
	CALL	TEST_6116_BYTE
	LD	HL,0d5ffh
	CALL	TEST_6116_BYTE
	LD	HL,0d6ffh
	CALL	TEST_6116_BYTE
	LD	HL,0d7ffh
	CALL	TEST_6116_BYTE
				; C=0ffh if all blocks passed
				; C=0 to 31 means at least one block failed
	LD	A,C
	RLCA			; only C=FF puts 1 in LSB
	AND	1		; zero all but LSB
	RLCA
	RLCA
	RLCA			; now A = 0000 0000 or 0000 1000
	EXX
	LD	B,A
	LD	A,L
	OR	B
	LD	L,A		; bit 3 of L' is status of SOUND_RAM_U51
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SOUND_RAM_U50:
				; U50 stores bytes at $D800-$DFFF
	;; initialize write, allow bus and chip select to stabilize
	LD	HL,0d800h
	LD	(HL),0aah
	NOP
	NOP
	NOP
	NOP
	
	LD	C,31		; initialize status byte
	LD	HL,0d8ffh
	CALL	TEST_6116_BYTE
	LD	HL,0d9ffh
	CALL	TEST_6116_BYTE
	LD	HL,0daffh
	CALL	TEST_6116_BYTE
	LD	HL,0dbffh
	CALL	TEST_6116_BYTE
	LD	HL,0dcffh
	CALL	TEST_6116_BYTE
	LD	HL,0ddffh
	CALL	TEST_6116_BYTE
	LD	HL,0deffh
	CALL	TEST_6116_BYTE
	LD	HL,0dfffh
	CALL	TEST_6116_BYTE
				; C=0ffh if all reads passed
				; C=0 to 31 means at least one read failed
	LD	A,C
	RLCA			; only C=FF puts 1 in LSB
	AND	1		; zero all but LSB
	RLCA
	RLCA			; now A = 0000 0000 or 0000 0100
	EXX
	LD	B,A
	LD	A,L
	OR	B
	LD	L,A		; bit 2 of L' is status of SOUND_RAM_U50
	EXX
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_STATUS_WORD:
	LD	HL,2b8h		; initial xpos
	LD	DE,2bh		; increment for xpos
		
	EXX
	LD	A,H		; load A from H'
	EXX
	LD	B,A		; put high byte of status word into B
	RRCA
	RRCA
	RRCA			; put bit 7 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e000h	; address for symbol
	CALL	DRAW_CHAR	; draw 1st char of status word
	ADD	HL,DE		; increment xpos by DE

	LD	A,B		; put high byte of status word into A
	RRCA
	RRCA			; put bit 6 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e00ah	; address for symbol
	CALL	DRAW_CHAR	; draw 2nd char of status word
	ADD	HL,DE		; increment xpos by DE
	
	LD	A,B		; put high byte of status word into A
	RRCA			; put bit 5 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e014h	; address for symbol
	CALL	DRAW_CHAR	; draw 3rd char of status word
	ADD	HL,DE		; increment xpos by DE
	
	LD	A,B		; put high byte of status word into A
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e01eh	; address for symbol
	CALL	DRAW_CHAR	; draw 4th char of status word
	ADD	HL,DE		; increment xpos by DE
	ADD	HL,DE		; increment xpos by DE (add a space)
	
	LD	A,B		; put high byte of status word into A
	RLCA			; put bit 3 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e028h	; address for symbol
	CALL	DRAW_CHAR	; draw 5th char of status word
	ADD	HL,DE		; increment xpos by DE

	LD	A,B		; put high byte of status word into A
	RLCA
	RLCA			; put bit 2 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e032h	; address for symbol
	CALL	DRAW_CHAR	; draw 6th char of status word
	ADD	HL,DE		; increment xpos by DE

	LD	A,B		; put high byte of status word into A
	RLCA
	RLCA
	RLCA			; put bit 1 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e03ch	; address for symbol
	CALL	DRAW_CHAR	; draw 7th char of status word
	ADD	HL,DE		; increment xpos by DE

	LD	A,B		; put high byte of status word into A
	RLCA
	RLCA
	RLCA
	RLCA			; put bit 0 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e046h	; address for symbol
	CALL	DRAW_CHAR	; draw 8th char of status word
	ADD	HL,DE		; increment xpos by DE
		
	EXX
	LD	A,L		; load a from L'
	EXX
	LD	B,A		; put low byte of status word into B
	RRCA
	RRCA
	RRCA			; put bit 7 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e050h	; address for symbol
	CALL	DRAW_CHAR	; draw 9th char of status word	
	ADD	HL,DE		; increment xpos by DE
	
	LD	A,B		; put low byte of status word into A
	RRCA
	RRCA			; put bit 6 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e05ah	; address for symbol
	CALL	DRAW_CHAR	; draw 10th char of status word
	ADD	HL,DE		; increment xpos by DE

	LD	A,B		; put low byte of status word into A
	RRCA			; put bit 5 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e064h	; address for symbol
	CALL	DRAW_CHAR	; draw 11th char of status word
	ADD	HL,DE		; increment xpos by DE
	
	LD	A,B		; put low byte of status word into A
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e06eh	; address for symbol
	CALL	DRAW_CHAR	; draw 12th char of status word
	ADD	HL,DE		; increment xpos by DE
	ADD	HL,DE		; increment xpos by DE (insert a space)

	LD	A,B		; put low byte of status word into A
	RLCA			; put bit 3 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e078h	; address for symbol
	CALL	DRAW_CHAR	; draw 13th char of status word
	ADD	HL,DE		; increment xpos by DE
	
	LD	A,B		; put low byte of status word into A
	RLCA
	RLCA			; put bit 2 into bit 4
	AND	10000b		; zero all but bit 4
	ADD	A,16h		; make A into 16h or 26h
	LD	C,A
	LD	IX,0e082h	; address for symbol
	CALL	DRAW_CHAR	; draw 14th char of status word
	
	LD	HL,0e082h
	SET	7,(HL)		; set "last symbol" flag
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DRAW_CHAR:
	; inputs to this function are C,IX,HL
	LD	A,11h		; 11h:  symbol_group=1, draw=1=yes
	LD	(IX+0),A
	LD	A,L		; xpos low byte
	LD	(IX+1),A
	LD	A,H		; xpos high byte
	LD	(IX+2),A
	LD	A,0bh		; ypos low byte
	LD	(IX+3),A
	LD	A,04h		; ypos high byte
	LD	(IX+4),A
	LD	A,C		; low byte of stroke address
	LD	(IX+5),A
	LD	A,0e3h		; high byte of stroke address
	LD	(IX+6),A
	LD	A,0		; next 2 bytes are rotate info
	LD	(IX+7),A
	LD	(IX+8),A
	LD	A,40h		; size/scale
	LD	(IX+9),A
	RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_FLASH:
	; input to this function is H'L', the RAM status word
	; H = 42h means 4 flashes, 2 pause intervals
	; L = 18h means 1 flash, 8 pause intervals
	; input to this function is H'L'
	; go through status word H'L' left to right
	; identify first bad chip
	
	; first, put H'L' into HL
	EXX
	LD	A,H
	EXX
	LD	H,A
	EXX
	LD	A,L
	EXX
	LD	L,A		; now HL = H'L'
	
	LD	C,1		; initialize bit counter
				; 1...............14
TEST_MSB:
	LD	A,C		; put counter into A
				; if C=15 then we found no zeroes in first
				; 14 digits of RAM status word
	SUB	15		; A=A-15.  No zeroes found in HL?
	JR	Z,GET_FLASH_WORD	; if so, jump ahead with A=0
	LD	A,C		; else, reload A with C
	BIT	7,H		; test MSB of HL
	JR	Z,GET_FLASH_WORD ; is MSB a zero (found bad RAM)? if so, jump
	ADD	HL,HL		; else, shift HL left one bit
	INC	C		; increment bit counter
	JR	TEST_MSB 	; loop to test next bit
GET_FLASH_WORD:			; read flash_word from lookup table stored in ROM
	ADD	A,A		; multiply A by 2, result is offset from base addr
	ADD	A,70h		; add offset A to base addr of lookup table
	LD	D,0		; high byte of lookup table addr is $00
	LD	E,A		; low byte of lookup table addr is A
	LD	A,(DE)		; DE is location of first byte of flash_word
	LD	B,A		; put first byte of flash_word into B
	INC	E		; increment address DE
	LD	A,(DE)		; now DE is location of second byte of flash_word
	LD	C,A		; put second byte of flash_word into C
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DO_FLASH:	; do LED-on and LED-off intervals as specified by flash_word
FIRST_DIGIT:			; input: BC = flash_word - do not overwrite BC!
	LD	A,B		; load first byte of flash_word into A
	SRL	A
	SRL	A
	SRL	A
	SRL	A		; shift A four places to the right
	LD	H,A		; now H is number of times to do first digit flash	
FIRST_DIGIT_LOOP:		; input: H = flash counter
	LD	A,H
	CP	0		; done flashing out first digit?
	JR	Z,FIRST_DELAY	; if so, jump
	LD	L,5		; else, initialize interrupt counter
LED_ON1:
	EI			; enable interrupts
	HALT			; turn LED on and wait for interrupt
	DI
				; after each interrupt, do a poll
	IN	A,(0f9h)	; read state of P1 Start (E2P,SF)
	BIT	5,A		; button pressed? (E2P,SF)
	JP	Z,CHANGE_COLOR	; port 0xf9 is active LOW
	IN	A,(0fch)	; read state of P1 Start (ST,Z,TS)
	BIT	0,A		; button pressed?  (ST,Z,TS)
	JP	NZ,CHANGE_COLOR	; port 0xfc is active HIGH

	DEC	L		; decrement interrupt counter
	JR	NZ,LED_ON1	; counter != 0? if so,
				; loop to keep LED On
LED_OFF1:
				; do counter-based delay
	LD	D,238		; initialize outer loop counter
FDELAY1_OUTER:
	LD	E,238		; initialize inner loop counter
FDELAY1_INNER:
	DEC	E
	JR	NZ,FDELAY1_INNER	; next inner
	DEC	D
	JR	NZ,FDELAY1_OUTER	; next outer
				; when done counting, do a poll
	IN	A,(0f9h)	; read state of P1 Start (E2P,SF)
	BIT	5,A		; button pressed? (E2P,SF)
	JP	Z,CHANGE_COLOR	; port 0xf9 is active LOW
	IN	A,(0fch)	; read state of P1 Start (ST,Z,TS)
	BIT	0,A		; button pressed?  (ST,Z,TS)
	JP	NZ,CHANGE_COLOR	; port 0xfc is active HIGH

	DEC	H		; decrement flash counter
	JR	FIRST_DIGIT_LOOP
FIRST_DELAY:
			; do some number of delay intervals
	LD	A,B	; load first byte of flash_word into A
	AND	00001111b	; mask four high bits
	LD	H,A	; now H is number of delay intervals
FIRST_DELAY_LOOP:
	LD	A,H
	CP	0		; done counting delay intervals?
	JR	Z,SECOND_DIGIT	; if so, jump
		
	LD	D,191		; initialize outer loop counter
FDELAY2_OUTER:
	LD	E,191		; initialize inner loop counter
FDELAY2_INNER:
	DEC	E
	JR	NZ,FDELAY2_INNER	; next inner
	DEC	D
	JR	NZ,FDELAY2_OUTER	; next outer
				; when done counting, do a poll
	IN	A,(0f9h)	; read state of P1 Start (E2P,SF)
	BIT	5,A		; button pressed? (E2P,SF)
	JP	Z,CHANGE_COLOR	; port 0xf9 is active LOW
	IN	A,(0fch)	; read state of P1 Start (ST,Z,TS)
	BIT	0,A		; button pressed?  (ST,Z,TS)
	JP	NZ,CHANGE_COLOR	; port 0xfc is active HIGH

	DEC	H		; decrement interval counter
	JR	FIRST_DELAY_LOOP
SECOND_DIGIT:
	LD	A,C	; load second byte of flash_word into A
	SRL	A
	SRL	A
	SRL	A
	SRL	A		; shift A four places to the right
	LD	H,A	; now H is number of times to do second digit flash	
SECOND_DIGIT_LOOP:
	LD	A,H
	CP	0		; done flashing out second digit?
	JR	Z,SECOND_DELAY	; if so, jump
	LD	L,5		; else, initialize interrupt counter
LED_ON2:
	EI
	HALT			; turn LED on and wait for interrupt
	DI
				; after each interrupt, do a poll
	IN	A,(0f9h)	; read state of P1 Start (E2P,SF)
	BIT	5,A		; button pressed? (E2P,SF)
	JP	Z,CHANGE_COLOR	; port 0xf9 is active LOW
	IN	A,(0fch)	; read state of P1 Start (ST,Z,TS)
	BIT	0,A		; button pressed?  (ST,Z,TS)
	JP	NZ,CHANGE_COLOR	; port 0xfc is active HIGH

	DEC	L		; decrement interrupt counter
	JR	NZ,LED_ON2	; counter != 0? if so,
				; loop to keep LED on
LED_OFF2:
				; do counter-based delay
	LD	D,238		; initialize outer loop counter
FDELAY3_OUTER:
	LD	E,238		; initialize inner loop counter
FDELAY3_INNER:
	DEC	E
	JR	NZ,FDELAY3_INNER	; next inner
	DEC	D
	JR	NZ,FDELAY3_OUTER	; next outer
				; when done counting, do a poll
	IN	A,(0f9h)	; read state of P1 Start (E2P,SF)
	BIT	5,A		; button pressed? (E2P,SF)
	JP	Z,CHANGE_COLOR	; port 0xf9 is active LOW
	IN	A,(0fch)	; read state of P1 Start (ST,Z,TS)
	BIT	0,A		; button pressed?  (ST,Z,TS)
	JP	NZ,CHANGE_COLOR	; port 0xfc is active HIGH

	DEC	H		; decrement flash counter
	JR	SECOND_DIGIT_LOOP
SECOND_DELAY:
				; do some number of delay intervals
	LD	A,C		; load second byte of flash_word into A
	AND	00001111b 	; mask four highest bits
	LD	H,A		; now H is number delay intervals
SECOND_DELAY_LOOP:
	LD	A,H
	CP	0		; done counting delay intervals?
	JP	Z,FIRST_DIGIT	; if so, jump back to first digit	
	LD	D,191		; initialize outer loop counter
FDELAY4_OUTER:
	LD	E,191		; initialize inner loop counter
FDELAY4_INNER:
	DEC	E
	JR	NZ,FDELAY4_INNER	; next inner
	DEC	D
	JR	NZ,FDELAY4_OUTER	; next outer
				; when done counting, do a poll
	IN	A,(0f9h)	; read state of P1 Start (E2P,SF)
	BIT	5,A		; button pressed? (E2P,SF)
	JP	Z,CHANGE_COLOR	; port 0xf9 is active LOW
	IN	A,(0fch)	; read state of P1 Start (ST,Z,TS)
	BIT	0,A		; button pressed?  (ST,Z,TS)
	JP	NZ,CHANGE_COLOR	; port 0xfc is active HIGH
	
	DEC	H		; decrement interval counter
	JR	SECOND_DELAY_LOOP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
; RAM fail codes:
;       first digit =>       1      2      3      4
;   second digit       1    C.26   V.31   V.27   S.51
;        |             2    C.27   V.30   V.26   S.50
;        V             3    C.28   V.29   V.25    --
;                      4    C.29   V.28   V.24    --
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	