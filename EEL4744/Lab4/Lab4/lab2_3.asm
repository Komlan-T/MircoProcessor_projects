;*****************************************************************
;  File name: lab1.asm
;  Author:  Komlan Tchoukou
;  Created: 22 September 2023 8:15 PM
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
	ldi r16, low(stack_initial) ; initialize stack pointer
	sts CPU_SPL, r16
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16
	

	ser r16                     
	sts PORTC_OUTSET, r16		; drive LEDs low
	sts PORTC_DIRSET, r16       ; make LEDs outputs

	ser r20
	ldi r21, 0b01111111

	rcall START_CLOCK

	START:

			ldi r17, 0b00000001   ; clear overflow flag
			sts TCC0_INTFLAGS, r17

		ON:
			sts PORTC_OUT, r21   
			lds r16, TCC0_INTFLAGS
			sbrs r16, 0          ; repeat the loop until the overflow flag is set
			rjmp ON

			ldi r17, 0b00000001  ; clear overflow flag
			sts TCC0_INTFLAGS, r17

		OFF: 
			sts PORTC_OUT, r20
			lds r16, TCC0_INTFLAGS
			sbrs r16, 0          ; repeat the loop until the overflow flag is set
			rjmp OFF
			rjmp START

START_CLOCK:

	push r16

	ldi r16, low(((2000000 / 4) * 30) / 1000)
	sts	TCC0_PER, r16
	ldi r16, high(((2000000 / 4) * 30) / 1000)
	sts	(TCC0_PER+1), r16

	ldi r16, TC_CLKSEL_DIV4_gc   ; make prescaler 4
	sts TCC0_CTRLA, r16          ; start clock

	pop r16

	ret

DONE:
	rjmp DONE