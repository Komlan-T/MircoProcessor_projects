;*****************************************************************
;  File name: lab1.asm
;  Author:  Komlan Tchoukou
;  Created: 14 September 2023 11:49 AM
;  Description: To filter data stored within a predefined input  
;				table based on a set of given conditions and  
;				store a subset of filtered values into an output
;				table.
;*****************************************************************
;INCLUDES
.include "ATxmega128a1udef.inc"
;END OF INCLUDES
;*****************************************************************
;EQUATES
; potentially useful expressions
.equ NULL = 0
.equ ThirtySeven = 3*7 + 37/3 - (3-7)  ; 21 + 12 + 4
;END OF EQUATES
;*****************************************************************
;MEMORY CONFIGURATION
; program memory constants (if necessary)
.cseg
.org 0xF3A2
; Byte equivalent is 0x1E744
IN_TABLE:
.db 0xB0, 130, '6', 0b11001100, 208, 0xD4, 0b00101111, 0xCC, 52, '@', 0b00110100, 240, 0x00, '?'
.db NULL
; label below is used to calculate size of input table
IN_TABLE_END: 
; data memory allocation (if necessary)
.dseg
; initialize the output table starting address
.org 0x2345
OUT_TABLE:
.byte (IN_TABLE_END - IN_TABLE)
;END OF MEMORY CONFIGURATION
;*****************************************************************
;MAIN PROGRAM
.cseg
; configure the reset vector 
;	(ignore meaning of "reset vector" for now)
.org 0x0
	rjmp MAIN

; place main program after interrupt vectors 
;	(ignore meaning of "interrupt vectors" for now)
.org 0x100
MAIN:
; point appropriate indices to input/output tables (is RAMP needed?)
ldi ZL, low(IN_TABLE << 1)
ldi ZH, high(IN_TABLE << 1)
ldi r16, byte3(IN_TABLE << 1)
sts CPU_RAMPZ, r16

ldi YL, low(OUT_TABLE)
ldi YH, high(OUT_TABLE)

; loop through input table, performing filtering and storing conditions
LOOP:
	; load value from input table into an appropriate register
	elpm r16, Z+
	; determine if the end of table has been reached (perform general check)
	ldi r17, NULL
	; if end of table (EOT) has been reached, i.e., the NULL character was 
	; encountered, the program should branch to the relevant label used to
	; terminate the program (e.g., DONE)
	cp r16, r17
	breq DONE

	; if EOT was not encountered, perform the first specified 
	; overall conditional check on loaded value (CONDITION_1)
CHECK_1:
	; check if the CONDITION_1 is met (bit 7 of # is clear); 
	;   if not, branch to FAILED_CHECK1
	bst r16, 7
	brts FAILED_CHECK1
	; since the CONDITION_1 is met, perform the specified operation
	;   (multiply # by 2 [unsigned])
	lsl r16
	; check if CONDITION_1a is met (result < 110); if so, then 
	;   jump to LESS_THAN_110; else store nothing and go back to LOOP
	cpi r16, 110
	brlo LESS_THAN_126
	rjmp LOOP

LESS_THAN_126:
	; add 4 and store the result
	ldi r19, 4
	add r16, r19
	st Y+, r16
	rjmp LOOP
	
FAILED_CHECK1:
	; since the CONDITION_1 is NOT met (bit 7 of # is not clear, 
	;    i.e., set), perform the second specified operation 
	;    (divide by 2)
	lsr r16
	; check if CONDITION_2b is met (bit 0 of result is clear); if so, jump to
	;    BIT0_CLR (and do the next specified operation);
	;    else store nothing and go back to LOOP	
	bst r16, 0
	brtc BIT0_CLR
	rjmp LOOP
	
BIT0_CLR:
	; subtract 5 and store the result 
	ldi r19, 5
	neg r19
	add r16, r19
	st Y+, r16
	;go back to LOOP
	rjmp LOOP
	
; end of program (infinite loop)
DONE: 
	rjmp DONE
;END OF MAIN PROGRAM 