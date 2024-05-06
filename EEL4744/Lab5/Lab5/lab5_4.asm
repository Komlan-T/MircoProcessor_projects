;*****************************************************************
;  File name:   lab5_4.asm
;  Author:      Komlan Tchoukou
;  Created:     22 October 2023 3:50 PM
;  Description: Output a character string of arbitrary length
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial   = 0x3FFF

.cseg

.org 0x2000

NAME:
.db "Komlan Tchoukou", 0x00

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

	ldi ZL, low(NAME << 1)
	ldi ZH, high(NAME << 1)

	rcall OUT_STRING

	DONE:
		rjmp DONE

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

	;Set TXD0 high / initially on
	ldi r16, (1 << 3)
	sts PORTD_OUTSET, r16

	;Set TXD0 as an output
	sts PORTD_DIRSET, r16

	;Asynchronous = 00, Odd Parity = 11, 1 Stop Bit = 0, 8 Bit Character Size = 011
	ldi r16, 0x33
	sts USARTD0_CTRLC, r16
	
	;BSEL = 1
	ldi r16, 0x01
	sts USARTD0_BAUDCTRLA, r16

	;BSCALE = 1
	ldi r16, 0x10
	sts USARTD0_BAUDCTRLB, r16
	
	;Enable transmitter 
	ldi r16, (1 << 3)
	sts USARTD0_CTRLB, r16

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

/************************************************************************************
* Name:     OUT_STRING
* Purpose:  Receive string from program memory
* Inputs:   None			 
* Outputs:  None
* Affected: N/A
 ***********************************************************************************/

 OUT_STRING:
	
	push r16
	
	LOOP:
		;Load string from program memory
		lpm r17, Z+
		;Leave loop when NULL value is encountered
		cpi r17, 0x00
		breq LEAVE
		rcall OUT_CHAR
		rjmp LOOP

	LEAVE:

	pop r16

	ret