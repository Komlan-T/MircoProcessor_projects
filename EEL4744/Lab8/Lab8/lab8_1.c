/*
 * Lab8.c
 *
 * Created: 11/16/2023 10:49:16 PM
 * Author : henoc
 */ 

#include <avr/io.h>
#include <math.h>
extern void clock_init(void);
void dac_init(void);

int main(void)
{
   clock_init();
   dac_init();
   
   while(1){
	   while(!(DACB.STATUS & DAC_CH0DRE_bm));
	   DACA.CH0DATA = ((1.2 / 2.5) * 0xFFF);
   }
   return 0;
}

void dac_init(void)
{
	DACA.CTRLB = DAC_CHSEL_SINGLE_gc;
	DACA.CTRLC = DAC_REFSEL_AREFB_gc;
	DACA.CTRLA = (DAC_CH0EN_bm | DAC_ENABLE_bm);
}