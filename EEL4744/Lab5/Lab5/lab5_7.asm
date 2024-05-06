;*****************************************************************
;  File name:   lab5_7.asm
;  Author:      Komlan Tchoukou
;  Created:     23 October 2023 2:26 PM
;  Description: Configure interrupt-driven echo program for the
;				appropriate USART module
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial   = 0x3FFF

.cseg

.org 0x00				
	rjmp MAIN		
	
.org USARTD0_RXC_vect
	rjmp RXC_INTERRUPT_ISR	

.org 0x0100				
MAIN:

	;Initialize stack pointer
	ldi r16, low(stack_initial)
	sts CPU_SPL, r16 
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16

	rcall INITIALIZE_IO

	rcall USART_INIT

	rcall INITIALIZE_RECEIVER_INTERRUPT

	;Toggle BLUE LED on uPad
	LOOP:
		sts PORTD_OUTTGL, r18
		rjmp LOOP

	DONE:
		rjmp DONE


/************************************************************************************
* Name:     INITIALIZE_IO
* Purpose:  Subroutine to initialize BLUE LED as output
* Inputs:   None			 
* Outputs:  None
* Affected: PORTD_OUTCLR, PORTD_DIRSET
 ***********************************************************************************/

INITIALIZE_IO:

	push r16

	ldi r18, (1 << 6)

	;drive the BLUE LED low
	sts PORTD_OUTCLR, r18

	;set the BLUE LED as an output
	sts PORTD_DIRSET, r18

	pop r16

	ret

/************************************************************************************
* Name:     INITIALIZE_RECEIVER_INTERRUPT
* Purpose:  Initialize receiver interrupt
* Inputs:   None			 
* Outputs:  None
* Affected: USARTD0_CTRLA, PMIC_CTRL
 ***********************************************************************************/


INITIALIZE_RECEIVER_INTERRUPT:

		push r16

		;Enable low level interrupts for USART receiver interrupts
		ldi r16, USART_RXCINTLVL_LO_gc
		sts USARTD0_CTRLA, r16			
		
		;Enable low level interrupts at the peripheral level
		ldi r16, PMIC_LOLVLEN_bm
		sts PMIC_CTRL, r16	

		;Enable interrupts at the global level
		sei

		pop r16

		ret

/************************************************************************************
* Name:     USART_INIT
* Purpose:  Initialize USART module
* Inputs:   None			 
* Outputs:  None
* Affected: PORTD_OUTSET, PORTD_DIRSET, PORTD_DIRCLR, USART0_CTRLC, 
			USARTD0_BAUDCTRLA, USARTD0_BAUDCTRLB, USARTD0_CTRLB
***********************************************************************************/

USART_INIT:

	push r16

	;Set TXD0 high 
	ldi r16, (1 << 3)
	sts PORTD_OUTSET, r16

	;Set TXD0 as an output
	sts PORTD_DIRSET, r16

	;Set RXD0 as an input
	ldi r16, (1 << 2)
	sts PORTD_DIRCLR, r16

	;Asynchronous = 00, Odd Parity = 11, 1 Stop Bit = 0, 8 Bit Character Size = 011
	ldi r16, 0x33
	sts USARTD0_CTRLC, r16
	
	;BSEL = 1
	ldi r16, 0x01
	sts USARTD0_BAUDCTRLA, r16

	;BSCALE = 1
	ldi r16, 0x10
	sts USARTD0_BAUDCTRLB, r16
	
	;Enable transmitter & receiver
	ldi r16, (1 << 3 | 1 << 4)
	sts USARTD0_CTRLB, r16

	pop r16

	ret

/************************************************************************************
* Name:     RXC_INTERRUPT_ISR
* Purpose:  Whenever receiver interrupt is activated, read value from transmitter
			and echo it to terminal
* Inputs:   None			 
* Outputs:  None
* Affected: USARTD0_DATA
 ***********************************************************************************/

RXC_INTERRUPT_ISR:
	
	push r16
	lds r16, CPU_SREG
	push r16

	;Read value from transmitter from keyboard
	lds r17, USARTD0_DATA

	;Echo transmitted value to receiver to terminal
	sts USARTD0_DATA, r17

	pop r16
	sts CPU_SREG, r16
	pop r16

	reti						