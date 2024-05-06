;*****************************************************************
;  File name: lab4_3a.asm
;  Author:  Komlan Tchoukou
;  Created: 13 October 2023 10:12 AM
;  Description: Sequentially write the data available in the SRAM
;				text file. After this, verify the previous step 
;				was done correctly by reading back the data to the
;				IO port.
;*****************************************************************

.include "ATxmega128A1Udef.inc"

.equ stack_initial   = 0x3FFF
.equ SRAM_START_ADDR = 0x3F0000
.equ IO_START_ADDR   = 0x1C7580
.equ SRAM_END_ADDR   = 0x3F7FFF

.cseg
.org 0x2000

DATA:
.include "sram_data_asm.txt"

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

	;Z pointer points to DATA table in program memory
	ldi ZL, low(DATA << 1)
	ldi ZH, high(DATA << 1)

	;Y pointer points to SRAM start address
	ldi YL, low(SRAM_START_ADDR)
	ldi YH, high(SRAM_START_ADDR)
	ldi r16, byte3(SRAM_START_ADDR)
	sts CPU_RAMPY, r16

	;X pointer points to SRAM end address
	ldi XL, low(SRAM_END_ADDR)
	ldi XH, high(SRAM_END_ADDR)
	ldi r16, byte3(SRAM_END_ADDR)
	sts CPU_RAMPX, r16

	STORE:

		;load data from DATA table in program memory
		lpm r16, Z+
		;store data into SRAM
		st Y+, r16
		;check to see if program is at the end of SRAM space
		cp XL, YL
		cpc XH, YH
		;branch to write when address in SRAM have been used up
		breq WRITE

		rjmp STORE

	WRITE:

		;Y points to SRAM start address
		ldi YL, low(SRAM_START_ADDR)
		ldi YH, high(SRAM_START_ADDR)
		ldi r16, byte3(SRAM_START_ADDR)
		sts CPU_RAMPY, r16

		;X points to SRAM end address
		ldi XL, low(SRAM_END_ADDR)
		ldi XH, high(SRAM_END_ADDR)
		ldi r16, byte3(SRAM_END_ADDR)
		sts CPU_RAMPX, r16

		;Z points to IO start address
		ldi ZL, low(IO_START_ADDR)
		ldi ZH, high(IO_START_ADDR)
		ldi r16, byte3(IO_START_ADDR)
		sts CPU_RAMPZ, r16

		LOOP:
			 
			 ;load data from SRAM
			 ld r16, Y+
			 ;delay for 300 ms in order to see LEDs changing
			 rcall DELAY_300MS
			 ;store data into IO port to see value displayed on LEDs
			 st Z, r16

			 ;check to see if all addresses have been checked
			 cp XL, YL
			 cpc XH, YH
			 ;if so finish program at infinite loop
			 breq DONE

			 rjmp LOOP
	DONE:
		rjmp DONE

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

	;Configure chip select CS2
	ldi r16, 0x0D
	sts EBI_CS2_CTRLA, r16
	ldi r16, byte2(IO_START_ADDR)
	sts EBI_CS2_BASEADDR, r16
	ldi r16, byte3(IO_START_ADDR)
	sts EBI_CS2_BASEADDR+1, r16

	pop r16

	ret	

/************************************************************************************
* Name:     DELAY_300MS
* Purpose:  Delay program for 300 ms
* Inputs:   None			 
* Outputs:  None
* Affected: TCC0_PER, TCCO_CTRLA, TCC0_CNT
 ***********************************************************************************/

DELAY_300MS:

	push r16

	;store count in period register low byte
	ldi r16, low(((2000000 / 64) * 302) / 1000)
	sts	TCC0_PER, r16

	;store count in period register high byte
	ldi r16, high(((2000000 / 64) * 302) / 1000)
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