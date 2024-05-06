;*****************************************************************
;  File name: lab4_3b.asm
;  Author:  Komlan Tchoukou
;  Created: 13 October 2023 10:12 AM
;  Description: Perform an infinite loop that writes and reads 
;				from at least two meaningful SRAM locations
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial   = 0x3FFF
.equ SRAM_START_ADDR = 0x3F0000
.equ SRAM_MA1        = 0x3F0C02
.equ SRAM_MA2		 = 0x3F3003

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

	rcall EBI_INIT

	;Y points to SRAM menaingful address 1
	ldi YL, low(SRAM_MA1)
	ldi YH, high(SRAM_MA1)
	ldi r16, byte3(SRAM_MA1)
	sts CPU_RAMPY, r16

	;X points to SRAM meaningful address 2
	ldi XL, low(SRAM_MA2)
	ldi XH, high(SRAM_MA2)
	ldi r16, byte3(SRAM_MA2)
	sts CPU_RAMPX, r16

	LOOP:
		
		;load r16 with non zero 4 bit value	 
		ldi r16, 0x0E

		;store value into first address
		st Y, r16
		;load value from first address
		ld r16, Y

		;store value into second address
		st X, r16
		;load value from second address
		ld r16, X

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

	;Configure chip select CS0
	ldi r16, 0x1D
	sts EBI_CS0_CTRLA, r16
	ldi r16, byte2(SRAM_START_ADDR)
	sts EBI_CS0_BASEADDR, r16
	ldi r16, byte3(SRAM_START_ADDR)
	sts EBI_CS0_BASEADDR+1, r16

	pop r16

	ret	