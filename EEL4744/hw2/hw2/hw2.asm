;*****************************************************************
;  File name: hw2.asm
;  Author:  Komlan Tchoukou
;  Created: 2 October 2023 10:13 PM
;  Description: Set the intensities of each RGB LED by specifiying 
;				the duty cycle through the DIP switches. S1 on the 
;				SLB sets the duty cycle of the red led. S2 on the 
;				SLB sets the duty cycle of the blue led. S1 on the 
;				MB sets the duty cycle of the green led. 
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial = 0x3FFF
.equ BIT012 = 0x07
.equ BIT456 = 0x70
.equ SINGLE_SLOPE_PWM = 0x73

.cseg

.org 0x00				
	rjmp MAIN		

.org 0x0100				
MAIN:

	ldi r16, low(stack_initial)
	sts CPU_SPL, r16 
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16

	rcall INITIALIZE_IO
	rcall INITIALIZE_TC

	LOOP:

		lds r16, PORTA_IN
		sts PORTC_OUT, r16

		lds r16, PORTF_IN
		sbrs r16, 2
		rcall RED 

		lds r16, PORTF_IN
		sbrs r16, 3
		rcall BLUE 

		lds r16, PORTE_IN
		sbrs r16, 0
		rcall GREEN
		
		rjmp LOOP 

/************************************************************************************
* Name:     INITIALIZE_IO
* Purpose:  Subroutine to initialize the LEDs, RGB LEDs as outputs, and the DIP
			switches, SLB S1, SLB S2, and MB S1 as inputs. It also enables the 
			compare capture channels and remaps the TC to the nessesary pins
* Inputs:   None			 
* Outputs:  None
* Affected: PORTA_DIRCLR, PORTC_OUTSET, PORTC_DIRSET, PORTD_OUTSET, PORTD_DIRSET
			TCD0_CTRLB, PORTD_REMAP
 ***********************************************************************************/

INITIALIZE_IO:

	push r16

	ser r16

	;drive switches as inputs
	sts PORTA_DIRCLR, r16

	;drive LEDs high to keep them off initially
	sts PORTC_OUTSET, r16

	;set LEDs as outputs
	sts PORTC_DIRSET, r16

	ldi r16, BIT456

	;drive the red, blue, and green LEDs high to keep them off initially
	sts PORTD_OUTSET, r16

	;set the red, blue, green LEDs as outputs
	sts PORTD_DIRSET, r16

	;enable compare capture
	ldi r16, SINGLE_SLOPE_PWM 
	sts TCD0_CTRLB, r16

	;remap pins
	ldi r16, BIT012
	sts PORTD_REMAP, r16

	pop r16

	ret

/************************************************************************************
* Name:     INITIALIZE_TC
* Purpose:  Subroutine to initialize timer counter for the duty cycle / intensities
* Inputs:   None			 
* Outputs:  None
* Affected: TCD0_PER, TCD0_CTRLA
 ***********************************************************************************/

INITIALIZE_TC:

	push r16

	ldi r16, low(255)
	sts TCD0_PER, r16

	ldi r16, high(255)
	sts (TCD0_PER+1), r16

	ldi r16, TC_CLKSEL_DIV4_gc
	sts TCD0_CTRLA, r16

	pop r16

	ret

/************************************************************************************
* Name:     RED
* Purpose:  Subroutine to set the duty cycle for the red LED
* Inputs:   None			 
* Outputs:  None
* Affected: TCD0_CCA
 ***********************************************************************************/

RED:
	
	push r16
	
	lds r16, PORTA_IN
	sts TCD0_CCA, r16

	clr r16
	sts (TCD0_CCA+1), r16

	pop r16

	ret

/************************************************************************************
* Name:     BLUE
* Purpose:  Subroutine to set the duty cycle for the blue LED
* Inputs:   None			 
* Outputs:  None
* Affected: TCD0_CCB
 ***********************************************************************************/

BLUE:

	push r16
	
	lds r16, PORTA_IN
	sts TCD0_CCB, r16

	clr r16
	sts (TCD0_CCB+1), r16

	pop r16

	ret

/************************************************************************************
* Name:     GREEN
* Purpose:  Subroutine to set the duty cycle for the green LED
* Inputs:   None			 
* Outputs:  None
* Affected: TCD0_CCC
 ***********************************************************************************/

GREEN:

	push r16
	
	lds r16, PORTA_IN
	sts TCD0_CCC, r16

	clr r16
	sts (TCD0_CCC+1), r16

	pop r16

	ret
