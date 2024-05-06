;*****************************************************************
;  File name: lab1.asm
;  Author:  Komlan Tchoukou
;  Created: 20 September 2023 2:34 PM
;  Description: To filter data stored within a predefined input  
;				table based on a set of given conditions and  
;				store a subset of filtered values into an output
;				table.
;*****************************************************************
 
;Within an endless loop, output the value of each
;DIP switch circuit located on the OOTB Switch & LED
;Backpack to a corresponding LED circuit also located on the
;backpack. More specifically, if an input switch is determined to
;be closed, the LED located directly below the switch on the
;backpack must be powered on (i.e., illuminated); conversely, if
;an input switch is determined to be open, the LED located
;directly below it must be powered off.
;****/

.include "ATxmega128A1Udef.inc"

.org 0x0				
	rjmp MAIN			;Relative jump to start of program.

.org 0x0100				;Start program at 0x0100 so we don't overwrite 
						;  vectors that are at 0x0000-0x00FD 
MAIN:
	ser r16
	sts PORTC_OUTSET, r16; drive all pins active high
	sts PORTC_DIRSET, r16; all LEDs will be off initially
	clr r16
	sts PORTA_DIR, r16

LOOP:
	lds r17, PORTA_IN  ; read values corresponding to DIP Switches
	sts PORTC_OUT, r17 ; transfer values read to LEDs
	rjmp LOOP				