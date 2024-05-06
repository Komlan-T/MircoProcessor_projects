/*
 * Lab7.c
 *
 * Created: 11/7/2023 10:50:44 PM
 * Author : henoc
 */ 

#include <avr/io.h>
volatile int16_t var;

int main(void)
{
	adc_init();
    
    while (1) 
    {
		ADCA.CH0.CTRL |= ADC_CH_START_bm;
		while (!(ADCA.CH0.INTFLAGS & ADC_CH_CHIF_bm));
		ADCA.CH0.INTFLAGS = ADC_CH_CHIF_bm;
		var = ADCA.CH0.RES;
		asm("nop");
    }
	return 0;
}

void adc_init(void)
{
	ADCA.CTRLB = (ADC_RESOLUTION_12BIT_gc | ADC_CONMODE_bm);
	ADCA.REFCTRL = ADC_REFSEL_AREFB_gc;
	ADCA.PRESCALER = ADC_PRESCALER_DIV16_gc;
	ADCA.CH0.CTRL = ADC_CH_INPUTMODE_DIFFWGAIN_gc;
	ADCA.CH0.MUXCTRL = (ADC_CH_MUXPOS_PIN1_gc | ADC_CH_MUXNEG_PIN6_gc);
	ADCA.CTRLA = ADC_ENABLE_bm;
}

