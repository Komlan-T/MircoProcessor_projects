;*****************************************************************
;  File name: lab2_2.asm
;  Author:  Komlan Tchoukou
;  Created: 21 September 2023 9:03 AM
;  Description: To filter data stored within a predefined input  
;				table based on a set of given conditions and  
;				store a subset of filtered values into an output
;				table.
;*****************************************************************
.include "ATxmega128A1Udef.inc"

.equ stack_initial = 0x3FFF

 .org 0x0
	rjmp MAIN
MAIN:
	ldi r16, low(stack_initial)      ; initialize stack pointer
	sts CPU_SPL, r16
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16
	
	ser r16
	sts PORTC_OUTSET, r16            ; drive pins high
	sts PORTC_DIRSET, r16            ; make LEDs outputs

	ser r20
	ldi r21, 0b01111111
	TOGGLE:
		sts PORTC_OUT, r21          ; turn on LED
		ldi r22, 2
		rcall DELAY_X_10MS          ; delay for 10 ms x amount of times
		sts PORTC_OUT, r20          ; turn LED off
		ldi r22, 2
		rcall DELAY_X_10MS
		rjmp TOGGLE
	
DONE:
	rjmp DONE

DELAY_10MS:

clr r18
LOOP1:
	clr r17             ; reinitialize inorder to run this loop as long as loop 1 is
	LOOP2:
		clr r16             ; reinitialize inorder to run this loop as long as loop 2 is
		LOOP3:
			inc r16
			cpi r16, 0x12   ;repeat loop 0x12 times
			brlo LOOP3
		inc r17
		cpi r17, 0x11
		brlo LOOP2
	inc r18
	cpi r18, 0x10
	brlo LOOP1
	ret

DELAY_X_10MS:

LOOP4:
	rcall DELAY_10MS         ; run for 10ms x amount of times
	dec r22
	cpi r22, 1
	brge LOOP4
	ret