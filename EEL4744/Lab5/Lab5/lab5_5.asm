;*****************************************************************
;  File name:   lab5_5.asm
;  Author:      Komlan Tchoukou
;  Created:     23 October 2023 10:05 AM
;  Description: Configure the appropriate USART module to receive
;				serial data from computer
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial   = 0x3FFF

.cseg

.org 0x00				
	rjmp MAIN			

.org 0x0100				
MAIN:

	;Initialize stack pointer
	ldi r16, low(stack_initial)
	sts CPU_SPL, r16 
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16

	rcall USART_INIT

	LOOP:
		;Read characters transmitted from keyboard
		rcall IN_CHAR
		;Echo transmission to receiver to print to terminal
		rcall OUT_CHAR
		rjmp LOOP

	

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
* Name:     IN_CHAR
* Purpose:  Transmit value from keyboard
* Inputs:   None			 
* Outputs:  None
* Affected: USARTD0_DATA
 ***********************************************************************************/

IN_CHAR:
	
	push r16
	
	;Check receiver interrupt flag to make sure no value in receiver buffer is unread
	CHECK_RXCIF:
		lds r16, USARTD0_STATUS
		sbrs r16, USART_RXCIF_bp
		rjmp CHECK_RXCIF

	;Load transmitted value from data register
	lds r17, USARTD0_DATA

	pop r16

	ret



/************************************************************************************
* Name:     OUT_CHAR
* Purpose:  Receive value from data register
* Inputs:   None			 
* Outputs:  None
* Affected: N/A
 ***********************************************************************************/

OUT_CHAR:
	
	push r16
	
	;Make sure DATA register is ready to receive new data
	CHECK_DREIF:
		lds r16, USARTD0_STATUS
		sbrs r16, USART_DREIF_bp
		rjmp CHECK_DREIF
	
	;Transmit the character passed into the subroutine
	sts USARTD0_DATA, r17

	pop r16

	ret