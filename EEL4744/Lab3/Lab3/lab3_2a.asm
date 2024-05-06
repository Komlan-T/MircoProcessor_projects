;*****************************************************************
;  File name: lab3_2a.asm
;  Author:  Komlan Tchoukou
;  Created: 27 September 2023 12:11 PM
;  Description: Pressing S1 triggers an IO interrput that 
;				increments a register and displays the value
;				in binary through the LEDs
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial = 0x3FFF
.equ BIT2 = 0x04
.equ BIT4 = 0x10

.cseg 

.org 0x00				
	rjmp MAIN			

.org PORTF_INT0_vect
	rjmp PRESS_OOTB_SLB_S1_ISR

.org 0x0100				
MAIN:
	;initialize stack pointer
	ldi r16, low(stack_initial)
	sts CPU_SPL, r16 
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16
	
	rcall INITIALIZE_IO
	rcall INITIALIZE_INTERRUPT

	clr r17
	
	;update count to LEDs and toggle red LED as fast as possible
	LOOP:
		sts PORTC_OUTCLR, r17
		sts PORTD_OUTTGL, r18
		rjmp LOOP

	DONE:
		rjmp DONE

/************************************************************************************
* Name:     INITIALIZE_IO
* Purpose:  Subroutine to initialize the LEDs and red LED as outputs
* Inputs:   None			 
* Outputs:  None
* Affected: PORTC_OUTSET, PORTC_DIRSET, PORTD_OUTSET, PORTD_DIRSET
 ***********************************************************************************/

INITIALIZE_IO:

	push r16

	ser r16

	;drive LEDs high
	sts PORTC_OUTSET, r16

	;set LEDs as outputs
	sts PORTC_DIRSET, r16

	ldi r18, BIT4

	;drive the red LED low
	sts PORTD_OUTSET, r18

	;set the red LED as an output
	sts PORTD_DIRSET, r18

	pop r16

	ret

/************************************************************************************
* Name:     INITIALIZE_INTERRUPT
* Purpose:  Subroutine to initialize the PortF external pin interrupt PD2 using INT
* Inputs:   None			 
* Outputs:  None
* Affected: PORTF_INT0MASK, PORTF_DIRCLR, PORTF_INTCTRL, PORTF_PIN2CTRL, 
			PMIC_CTRL
 ***********************************************************************************/

INITIALIZE_INTERRUPT:

		push r16

		;interrput source
		ldi r16, BIT2
		sts PORTF_INT0MASK, r16 

		;set interrput as an input
		sts PORTF_DIRCLR, r16	

		;set priority to low
		ldi r16, PORT_INT0LVL_LO_gc
		sts PORTF_INTCTRL, r16	

		;sense falling edges
		ldi r16, PORT_ISC_FALLING_gc
		sts PORTF_PIN2CTRL, r16 

		;enable low level interrputs
		ldi r16, PMIC_LOLVLEN_bm
		sts PMIC_CTRL, r16		

		;turn on global interrputs
		sei						

		pop r16

		ret

/************************************************************************************
* Name:     PRESS_OOTB_SLB_S1_ISR
* Purpose:  Interrput service routine that increments register 17 whenever S1 is
			is pressed
* Inputs:   None			 
* Outputs:  None
* Affected: N/A
 ***********************************************************************************/

PRESS_OOTB_SLB_S1_ISR:
	
	push r16
	lds r16, CPU_SREG
	push r16

	inc r17

	pop r16
	sts CPU_SREG, r16
	pop r16
	reti				