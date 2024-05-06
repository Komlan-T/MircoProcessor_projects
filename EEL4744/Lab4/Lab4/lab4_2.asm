;*****************************************************************
;  File name: lab4_2.asm
;  Author:  Komlan Tchoukou
;  Created: 10 October 2023 12:13 PM
;  Description: Continually write the digital value specified by
;				each DIP switch connected to the external input 
;				port to a corresponding LED on the LED bank 
;				connected to your output port.
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial = 0x3FFF
.equ IO_START_ADDR = 0x1C7580

.cseg

.org 0x00				
	rjmp MAIN			

.org 0x0100				
MAIN:

	;initialize stack pointer
	ldi r16, low(stack_initial)
	sts CPU_SPL, r16 
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16

	rcall EBI_INIT

	;register Z points to IO start address
	ldi ZL, low(IO_START_ADDR)
	ldi ZH, high(IO_START_ADDR)
	ldi r16, byte3(IO_START_ADDR)
	sts CPU_RAMPZ, r16

	LOOP:
		
		;loading read from IO
		ld r16, Z
		;storing writes to IO
		st Z, r16
		rjmp LOOP

/************************************************************************************
* Name:     EBI_INIT
* Purpose:  Initialize and enable the EBI system for the relevant hardware expansion
* Inputs:   None			 
* Outputs:  None
* Affected: PORTH_OUTSET, PORTH_OUTCLR, PORTH_DIRSET, EBI_CTRL, EBI_CS2_CTRLA,
			EBI_CS2_BASEADDR
 ***********************************************************************************/

EBI_INIT:

	push r16
	
	;Initialize the relevant EBI control signals to be in a false state
	ldi r16, 0x53 
	sts PORTH_OUTSET, r16

	ldi r16, 0x04
	sts PORTH_OUTCLR, r16

	;Initialize the	EBI control signals to be output from the microcontroller
	ldi r16, 0x57
	sts PORTH_DIRSET, r16

	;Initialize the address signals to be output from the microcontroller
	ldi r16, 0xFF
	sts PORTK_DIRSET, r16

	;Initialize the EBI system for SRAM 3-PORT ALE1 mode
	ldi r16, 0x01
	sts EBI_CTRL, r16

	;Configure chip select CS2
	ldi r16, 0x0D
	sts EBI_CS2_CTRLA, r16
	ldi r16, byte2(IO_START_ADDR)
	sts EBI_CS2_BASEADDR, r16
	ldi r16, byte3(IO_START_ADDR)
	sts EBI_CS2_BASEADDR+1, r16

	pop r16

	ret	