;*****************************************************************
;  File name: lab3_2a.asm
;  Author:  Komlan Tchoukou
;  Created: 27 September 2023 12:11 PM
;  Description: Pressing S1 triggers an IO interrput that 
;				increments a register and displays the value
;				in binary through the LEDs however the S1 switch
;				is now debounced to keep track of incrementation
;				properly and display the correct count
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial = 0x3FFF
.equ BIT2 = 0x04
.equ BIT4 = 0x10

.cseg

.org 0x00				
	rjmp MAIN			

.org PORTF_INT0_vect
	rjmp DEBOUNCE_S1_ISR

.org TCC0_OVF_vect
	rjmp RESET_ISR

.org 0x0100				
MAIN:
	;initialize stack pointer
	ldi r16, low(stack_initial)
	sts CPU_SPL, r16 
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16
	
	rcall INITIALIZE_IO
	rcall INITIALIZE_TC
	rcall INITIALIZE_IO_INTERRUPT
	rcall INITIALIZE_TC_INTERRPUT

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
* Name:     INITIALIZE_TC
* Purpose:  Subroutine to initialize the timer/counter in port C but does not start
			it yet.
* Inputs:   None			 
* Outputs:  None
* Affected: TCC0_PER
 ***********************************************************************************/

INITIALIZE_TC:

	push r16

	ldi r16, low(((2000000 / 8) * 30) / 1000)
	sts TCC0_PER, r16

	ldi r16, high(((2000000 / 8) * 30) / 1000)
	sts (TCC0_PER+1), r16

	pop r16

	ret

/************************************************************************************
* Name:     INITIALIZE_TC_INTERRUPT
* Purpose:  Subroutine to initialize an overflow interrput but does not enable it.
* Inputs:   None			 
* Outputs:  None
* Affected: TCC0_INTCTRLA, PMIC_CTRL
 ***********************************************************************************/

 INITIALIZE_TC_INTERRPUT:

	push r16

	;disable TC interrput
	ldi r16, TC_OVFINTLVL_OFF_gc
	sts TCC0_INTCTRLA, r16

	;enable low level interrputs
	ldi r16, PMIC_LOLVLEN_bm
	sts PMIC_CTRL, r16

	sei

	pop r16

	ret

/************************************************************************************
* Name:     INITIALIZE_IO_INTERRUPT
* Purpose:  Subroutine to initialize S1 on the SLB as an interrput source
* Inputs:   None			 
* Outputs:  None
* Affected: PORTF_INT0MASK, PORTF_DIRCLR, PORTF_INTCTRL, PORTF_PIN2CTRL, 
			PMIC_CTRL, 
 ***********************************************************************************/


INITIALIZE_IO_INTERRUPT:

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

		;enable low level interrupts
		ldi r16, PMIC_LOLVLEN_bm
		sts PMIC_CTRL, r16		

		;turn on global interrputs
		sei					

		pop r16

		ret

/************************************************************************************
* Name:     DEBOUCE_S1_ISR
* Purpose:  Interrput service routine to debounce the S1 switch by delaying for as long as the 
			bouncing is occuring for
* Inputs:   None			 
* Outputs:  None
* Affected: PORTF_INTCTRL, TCC0_CTRLA, TCC0_INTCTRLA
 ***********************************************************************************/

DEBOUNCE_S1_ISR:
	
	push r16
	lds r16, CPU_SREG
	push r16

	;disable I/O interrput
	ldi r16, PORT_INT0LVL_OFF_gc  
	sts PORTF_INTCTRL, r16

	;enable TC
	ldi r16, TC_CLKSEL_DIV8_gc
	sts TCC0_CTRLA, r16

	;enable TC interrupt
	ldi r16, TC_OVFINTLVL_LO_gc
	sts TCC0_INTCTRLA, r16

	pop r16
	sts CPU_SREG, r16
	pop r16

	reti		

/************************************************************************************
* Name:     RESET_ISR
* Purpose:  Interrput service routine to disable the timer counter, timer counter 
			interrput, and enable the I/O interrput for the next time the button is
			pressed. This subroutine essentially resets the nessesary registers to 
			prepare for the next button press.
* Inputs:   None			 
* Outputs:  None
* Affected: TCC0_CTRLA, TCC0_INTCTRLA, TCC0_CNT, TCC0_INTFLAGS, PORTF_INTCTRL
 ***********************************************************************************/

RESET_ISR:
	
	push r16
	lds r16, CPU_SREG
	push r16

	;disable TC
	ldi r16, TC_CLKSEL_OFF_gc
	sts TCC0_CTRLA, r16

	;disable TC overflow interrupt
	ldi r16, TC_OVFINTLVL_OFF_gc
	sts TCC0_INTCTRLA, r16

	;reset count value
	clr r16
	sts TCC0_CNT, r16
	sts (TCC0_CNT+1), r16

	;reset overflow flag
	ldi r16, TC1_OVFIF_bm
	sts TCC0_INTFLAGS, r16

	;is the switch being pressed?
	lds r16, PORTF_IN
	sbrs r16, 2
	inc r17
	mov r18, r17
	com r18
	sts PORTC_OUTSET, r18

	;reset I/O interrput
	ldi r16, PORT_INT0LVL_LO_gc
	sts PORTF_INTCTRL, r16

	pop r16
	sts CPU_SREG, r16
	pop r16

	reti						