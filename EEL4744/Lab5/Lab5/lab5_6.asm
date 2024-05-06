;*****************************************************************
;  File name:   lab5_6.asm
;  Author:      Komlan Tchoukou
;  Created:     23 October 2023 1:45 PM
;  Description: Output character string of arbitray length
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial   = 0x3FFF
.equ CR              = 0x0D
.equ BS              = 0x08
.equ DEL             = 0x7F
.equ LF				 = 0x0A
.equ NULL            = 0x00
.equ ALLOCATE        = 15
.equ OUT_RANGE       = 0x1FFF

.dseg

.org 0x2000

STRING:
.byte ALLOCATE

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

	ldi YL, low(STRING)
	ldi YH, high(STRING)

	ldi XL, low(OUT_RANGE)
	ldi XH, high(OUT_RANGE)

	LOOP_4:

		rcall IN_STRING

		;Reload Z pointer back to beginning of string
		ldi ZL, low(STRING)
		ldi ZH, high(STRING)

		rcall OUT_STRING


		ldi r17, CR
		rcall OUT_CHAR
		ldi r17, LF
		rcall OUT_CHAR

		rjmp LOOP_4

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
	
	;Poll receiver interrupt flag until data in the receiver buffer has been registered
	CHECK_RXCIF:
		lds r16, USARTD0_STATUS
		sbrs r16, USART_RXCIF_bp
		rjmp CHECK_RXCIF

	;Receive data and store in data register
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

/************************************************************************************
* Name:     IN_STRING
* Purpose:  Transmit string from data memory
* Inputs:   None			 
* Outputs:  None
* Affected: N/A
 ***********************************************************************************/

IN_STRING:
	
	push r16
	
	LOOP:

		rcall IN_CHAR

		;Check if ENTER is pressed
		cpi r17, CR
		breq STORE_NULL
		;Check if BACKSPACE is pressed
		cpi r17, BS
		breq DECREMENT
		;Check if DELETE is pressed
		cpi r17, DEL
		breq DECREMENT

		;If none of those keys are pressed, store value at Y pointer
		st Y+, r17

		rjmp LOOP

	;When ENTER is pressed, leave subroutine
	STORE_NULL:
		ldi r17, NULL
		st Y, r17
		rjmp LEAVE_IN_STRING
		
	;When BACKSPACE or DELETE is pressed, decrement Y pointer to make room for potential new character
	DECREMENT:
		ldi r17, 0x00
		st -Y, r17
		;Check if BACKSPACE or DELETE is pressed pass string start address
		cp YL, XL
		cpc YH, XH
		breq TOO_FAR
		rjmp LOOP

	;If BACKSPACE or DELETE is pressed pass string start address, restore Y pointer back to 0x2000
	TOO_FAR:
		ldi r17, NULL
		st Y+, r17
		rjmp LOOP

	LEAVE_IN_STRING:

	pop r16

	ret



/************************************************************************************
* Name:     OUT_STRING
* Purpose:  Receive string from data memory
* Inputs:   None			 
* Outputs:  None
* Affected: N/A
 ***********************************************************************************/

OUT_STRING:
	
	push r16
	;Keep track of string length in r18
	ldi r18, ALLOCATE

	LOOP_3:
		ld r17, Z+
		rcall OUT_CHAR
		dec r18
		cpi r18, 0x00
		breq LEAVE_OUT_STRING
		rjmp LOOP_3

	LEAVE_OUT_STRING:

	pop r16

	ret