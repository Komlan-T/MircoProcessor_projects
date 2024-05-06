;*****************************************************************
;  File name: lab4_3b.asm
;  Author:  Komlan Tchoukou
;  Created: 13 October 2023 10:12 AM
;  Description: Sequentially write the data available in the SRAM
;				text file. After this, verify the previous step 
;				was done correctly by reading back the data to the
;				IO port.
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial   = 0x3FFF
.equ IO_START_ADDR_CS2   = 0x006000
.equ IO_START_ADDR_CS3   = 0x008000

.cseg
.org 0x2000

DATA:
.include "01.inc"

.org 0x00				
	rjmp MAIN			

.org 0x0100				
MAIN:

	;Initialize stack pointer
	ldi r16, low(stack_initial)
	sts CPU_SPL, r16 
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16

	rcall IO_INIT
	rcall EBI_INIT

	ldi ZL, low(DATA)
	ldi ZH, high(DATA)

	ldi YL, low(IO_START_ADDR_CS2)
	ldi YH, high(IO_START_ADDR_CS2)
	ldi r16, byte3(IO_START_ADDR_CS2)
	sts CPU_RAMPY, r16

	LOOP:
		ld r16, Y
		st Z, r16
		rjmp LOOP
	

		
	DONE:
		rjmp DONE

/************************************************************************************
* Name:     IO_INIT
* Purpose:  Subroutine to initialize one of the LEDs as an output
* Inputs:   None			 
* Outputs:  None
* Affected: PORTC_OUTCLR, PORTC_DIRSET
 ***********************************************************************************/

IO_INIT:

	push r16

	ldi r16, 0x01

	sts PORTA_DIRCLR, r16

	pop r16

	ret

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
	ldi r16, 0x15
	sts EBI_CS2_CTRLA, r16
	ldi r16, byte2(IO_START_ADDR_CS2)
	sts EBI_CS2_BASEADDR, r16
	ldi r16, byte3(IO_START_ADDR_CS2)
	sts EBI_CS2_BASEADDR+1, r16

	;Configure chip select CS3
	ldi r16, 0x1D
	sts EBI_CS3_CTRLA, r16
	ldi r16, byte2(IO_START_ADDR_CS3)
	sts EBI_CS3_BASEADDR, r16
	ldi r16, byte3(IO_START_ADDR_CS3)
	sts EBI_CS3_BASEADDR+1, r16

	pop r16

	ret	

/************************************************************************************
* Name:     DELAY_300MS
* Purpose:  Delay program for 300 ms
* Inputs:   None			 
* Outputs:  None
* Affected: TCC0_PER, TCCO_CTRLA, TCC0_CNT
 ***********************************************************************************/

DELAY_57MS:

	push r16

	;store count in period register low byte
	ldi r16, low(((2000000 / 64) * 57) / 1000)
	sts	TCC0_PER, r16

	;store count in period register high byte
	ldi r16, high(((2000000 / 64) * 57) / 1000)
	sts	(TCC0_PER+1), r16

	;set prescaler to 64
	ldi r16, TC_CLKSEL_DIV64_gc   
	sts TCC0_CTRLA, r16          

	OVERFLOW:
		
		;load interrupt register values into r16
		lds r16, TCC0_INTFLAGS
		;leave loop if overflow flag is set
		sbrs r16, 0
		rjmp OVERFLOW

	;turn off timer/counter
	ldi r16, TC_OVFINTLVL_OFF_gc
	sts TCC0_INTCTRLA, r16

	;clear overflow flag
	ldi r16, 0x01   
	sts TCC0_INTFLAGS, r16

	;reset counter
	clr r16
	sts TCC0_CNT, r16
	sts (TCC0_CNT+1), r16

	pop r16

	ret	