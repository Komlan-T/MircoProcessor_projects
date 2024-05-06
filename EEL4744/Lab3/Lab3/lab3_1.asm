;*****************************************************************
;  File name: lab3_1.asm
;  Author:  Komlan Tchoukou
;  Created: 26 September 2023 9:57 PM
;  Description: Toggles an LED by using a software delay via 
;				an overflow interrput.
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial = 0x3FFF
.equ BIT0 = 0x01

.cseg

.org 0x00				
	rjmp MAIN			

.org TCC0_OVF_vect
	rjmp SIMPLE_OVERFLOW_ISR

.org 0x0100				
MAIN:
	;initialize stack pointer
	ldi r16, low(stack_initial)
	sts CPU_SPL, r16 
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16
	
	rcall INITIALIZE_IO
	rcall INITIALIZE_TC
	rcall INITIALIZE_INTERRUPT

	;start timer/counter
	ldi r16, TC_CLKSEL_DIV8_gc
	sts TCC0_CTRLA, r16

	DONE:
		rjmp DONE

/************************************************************************************
* Name:     INITIALIZE_IO
* Purpose:  Subroutine to initialize one of the LEDs as an output
* Inputs:   None			 
* Outputs:  None
* Affected: PORTC_OUTCLR, PORTC_DIRSET
 ***********************************************************************************/

INITIALIZE_IO:

	push r16

	ldi r16, BIT0

	;drive LED low
	sts PORTC_OUTCLR, r16

	;set LED as an output
	sts PORTC_DIRSET, r16

	pop r16

	ret

/************************************************************************************
* Name:     INITIALIZE_TC
* Purpose:  Subroutine to initialize the first timer/counter in PORTC
* Inputs:   None			 
* Outputs:  None
* Affected: TCC0_PER
 ***********************************************************************************/

INITIALIZE_TC:

	push r16

	
	ldi r16, low(((2000000 / 8) * 72) / 1000)
	sts TCC0_PER, r16

	ldi r16, high(((2000000 / 8) * 72) / 1000)
	sts (TCC0_PER+1), r16

	pop r16

	ret

/************************************************************************************
* Name:     INITIALIZE_INTERRUPT
* Purpose:  Subroutine to initialize the PortD external pin interrupt PD0 using INT0
* Inputs:   None			 
* Outputs:  None
* Affected: TCC0_INTCTRLA, PMIC_CTRL
 ***********************************************************************************/

INITIALIZE_INTERRUPT:

	push r16

	;enable low level overflow interrputs
	ldi r16, TC_OVFINTLVL_LO_gc
	sts TCC0_INTCTRLA, r16

	;enable low level interrputs
	ldi r16, PMIC_LOLVLEN_bm
	sts PMIC_CTRL, r16

	;enable global interrputs
	sei

	pop r16

	ret

/************************************************************************************
* Name:     SIMPLE_OVERFLOW_ISR
* Purpose:  Subroutine to toggle one of the LEDs whenever the overflow flag is set
* Inputs:   None			 
* Outputs:  None
* Affected: PORTC_OUTTGL
 ***********************************************************************************/

SIMPLE_OVERFLOW_ISR:
	
	push r16
	lds r16, CPU_SREG
	push r16

	;toggle LED
	ldi r16, BIT0
	sts PORTC_OUTTGL, r16

	pop r16
	sts CPU_SREG, r16
	pop r16
	reti				