;*****************************************************************
;  File name: lab2_4.asm
;  Author:  Komlan Tchoukou
;  Created: 23 September 2023 12:01 PM
;  Description: To filter data stored within a predefined input  
;				table based on a set of given conditions and  
;				store a subset of filtered values into an output
;				table.
;*****************************************************************

;*******INCLUDES*************************************

; The inclusion of the following file is REQUIRED for our course, since
; it is intended that you understand concepts regarding how to specify an 
; "include file" to an assembler. 
.include "ATxmega128a1udef.inc"
;*******END OF INCLUDES******************************

;*******DEFINED SYMBOLS******************************
.equ ANIMATION_START_ADDR	=	0x2000 ;useful, but not required
.equ ANIMATION_SIZE			=	14	;useful, but not required
.equ stack_initial          =   0x3FFF
;*******END OF DEFINED SYMBOLS***********************

;*******MEMORY CONSTANTS*****************************
; data memory allocation
.dseg

.org ANIMATION_START_ADDR
ANIMATION:
.byte ANIMATION_SIZE
;*******END OF MEMORY CONSTANTS**********************

;*******MAIN PROGRAM*********************************
.cseg
; upon system reset, jump to main program (instead of executing
; instructions meant for interrupt vectors)
.org 0x00
	rjmp MAIN

; place the main program somewhere after interrupt vectors (ignore for now)
.org 0xFF		; >= 0xFD
MAIN:
; initialize the stack pointer

	ldi r16, low(stack_initial)
	sts CPU_SPL, r16
	ldi r16, high(stack_initial)
	sts CPU_SPH, r16

; initialize relevant I/O modules (switches and LEDs)

	rcall IO_INIT

; initialize (but do not start) the relevant timer/counter module(s)

	rcall TC_INIT

; Initialize the X and Y indices to point to the beginning of the 
; animation table. (Although one pointer could be used to both
; store frames and playback the current animation, it is simpler
; to utilize a separate index for each of these operations.)
; Note: recognize that the animation table is in DATA memory

	ldi XL, low(ANIMATION_START_ADDR)
	ldi XH, high(ANIMATION_START_ADDR)

	ldi YL, low(ANIMATION_START_ADDR)
	ldi YH, high(ANIMATION_START_ADDR)

; begin main program loop 
	
; "EDIT" mode
EDIT:
	
; Check if it is intended that "PLAY" mode be started, i.e.,
; determine if the relevant switch has been pressed.

	lds r16, PORTF_IN
	sbrs r16, 2

; If it is determined that relevant switch was pressed, 
; go to "PLAY" mode.

	rjmp PLAY

; Otherwise, if the "PLAY" mode switch was not pressed,
; update display LEDs with the voltage values from relevant DIP switches
; and check if it is intended that a frame be stored in the animation
; (determine if this relevant switch has been pressed).

	lds r17, PORTA_IN
	sts PORTC_OUT, r17
	lds r16, PORTF_IN
	sbrc r16, 3

; If the "STORE_FRAME" switch was not pressed,
; branch back to "EDIT".

	rjmp EDIT

; Otherwise, if it was determined that relevant switch was pressed,
; perform debouncing process, e.g., start relevant timer/counter
; and wait for it to overflow. (Write to CTRLA and loop until
; the OVFIF flag within INTFLAGS is set.)

	sts TCC0_CTRLA, r18; start timer/counter

	LOOP1:
		lds r16, TCC0_INTFLAGS
		sbrs r16, 0
		rjmp LOOP1
	
; After relevant timer/counter has overflowed (i.e., after
; the relevant debounce period), disable this timer/counter,
; clear the relevant timer/counter OVFIF flag,
; and then read switch value again to verify that it was
; actually pressed. If so, perform intended functionality, and
; otherwise, do not; however, in both cases, wait for switch to
; be released before jumping back to "EDIT".

	ldi r16, TC_CLKSEL_OFF_gc
	sts TCC0_CTRLA, r16
	ldi r16, 0b00000001
	sts TCC0_INTFLAGS, r16
	clr r16
	sts TCC0_CNT, r16
	sts (TCC0_CNT+1), r16
	lds r16, PORTF_IN
	sbrc r16, 3
	rjmp EDIT


; Wait for the "STORE FRAME" switch to be released
; before jumping to "EDIT".

STORE_FRAME_SWITCH_RELEASE_WAIT_LOOP:
	lds r16, PORTF_IN
	sbrs r16, 3
	rjmp STORE_FRAME_SWITCH_RELEASE_WAIT_LOOP
	st X+, r17
	rjmp EDIT 

; "PLAY" mode
PLAY:

; Reload the relevant index to the first memory location
; within the animation table to play animation from first frame.

	ldi YL, low(ANIMATION_START_ADDR)
	ldi YH, high(ANIMATION_START_ADDR)

PLAY_LOOP:

; Check if it is intended that "EDIT" mode be started
; i.e., check if the relevant switch has been pressed.`

	lds r16, PORTE_IN
	sbrs r16, 0

; If it is determined that relevant switch was pressed, 
; go to "EDIT" mode.

	rjmp EDIT

; Otherwise, if the "EDIT" mode switch was not pressed,
; determine if index used to load frames has the same
; address as the index used to store frames, i.e., if the end
; of the animation has been reached during playback.
; (Placing this check here will allow animations of all sizes,
; including zero, to playback properly.)
; To efficiently determine if these index values are equal,
; a combination of the "CP" and "CPC" instructions is recommended.

	cp XL, YL
	cpc XH, YH

; If index values are equal, branch back to "PLAY" to
; restart the animation.

	breq PLAY

; Otherwise, load animation frame from table, 
; display this "frame" on the relevant LEDs,
; start relevant timer/counter,
; wait until this timer/counter overflows (to more or less
; achieve the "frame rate"), and then after the overflow,
; stop the timer/counter,
; clear the relevant OVFIF flag,
; and then jump back to "PLAY_LOOP".

	ld r19, Y+
	sts PORTC_OUT, r19
	sts TCC0_CTRLA, r18
		LOOP2:
		lds r16, TCC0_INTFLAGS
		sbrs r16, 0 
		rjmp LOOP2
	ldi r16, TC_CLKSEL_OFF_gc
	sts TCC0_CTRLA, r16
	ldi r16, 0b00000001
	sts TCC0_INTFLAGS, r16
	clr r16
	sts TCC0_CNT, r16
	sts (TCC0_CNT+1), r16
	rjmp PLAY_LOOP


; end of program (never reached)
DONE: 
	rjmp DONE
;*******END OF MAIN PROGRAM *************************

;*******SUBROUTINES**********************************

;****************************************************
; Name: IO_INIT 
; Purpose: To initialize the relevant input/output modules, as pertains to the
;		   application.
; Input(s): N/A
; Output: N/A
;****************************************************
IO_INIT:
; protect relevant registers

	push r16

; initialize the relevant I/O

	ser r16
	sts PORTC_OUTSET, r16; drive all pins active high
	sts PORTC_DIRSET, r16; make all outputs; all LEDs will be off initially since they are active low
	clr r16
	sts PORTA_DIR, r16; make switches as inputs

	ldi r16, 0b00001100
	sts PORTF_DIRCLR, r16; configure PF2 and PF3 to be inputs to read S1 and S2


; recover relevant registers

	pop r16
	
; return from subroutine
	ret
;****************************************************
; Name: TC_INIT 
; Purpose: To initialize the relevant timer/counter modules, as pertains to
;		   application.
; Input(s): N/A
; Output: N/A
;****************************************************
TC_INIT:
; protect relevant registers

	push r16

; initialize the relevant TC modules

	ldi r16, low(((2000000 / 8) * 30) / 1000)
	sts	TCC0_PER, r16
	ldi r16, low(((2000000 / 8) * 30) / 1000)
	sts	(TCC0_PER+1), r16
	ldi r16, TC_CLKSEL_DIV8_gc
	mov r18, r16
	
; recover relevant registers
	
	pop r16
	
; return from subroutine
	ret

;*******END OF SUBROUTINES***************************