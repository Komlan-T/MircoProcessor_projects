/*
 * hw4.c
 *
 * Created: 11/13/2023 12:35:30 PM
 * Author : henoc
 */ 

#include <avr/io.h>
extern void clock_init(void);

int main(void)
{
	clock_init();
	PORTC.DIRSET = PIN7_bm;
	PORTCFG.CLKEVOUT = (PORTCFG_CLKOUT_PC7_gc);
	
    /* Replace with your application code */
    while (1) 
    {
		asm("nop");
    }
}

