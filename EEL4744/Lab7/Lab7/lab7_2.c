/*
 * CFile4.c
 *
 * Created: 11/9/2023 1:59:11 PM
 *  Author: henoc
 */ 
#include <avr/io.h>
#include <avr/interrupt.h>
volatile int16_t var;
 
 int main()
 {
	 PORTD.OUTSET = PIN6_bm;
	 PORTD.DIRSET = PIN6_bm;

	 adc_init();
	 tcc0_init();
	 
	 PMIC_CTRL = PMIC_LOLVLEN_bm;
	 CPU_SREG = CPU_I_bm;
	 
	 while (1)
	 {
		 asm("nop");
	 }
	 return 0;
 }
 
 void tcc0_init(void)
 {
	TCC0_PER = (((2000000 / 4) * 270) / 1000);
	TCC0_CTRLA = TC_CLKSEL_DIV4_gc;
	EVSYS.CH0MUX = EVSYS_CHMUX_TCC0_OVF_gc;
 }
 
 void adc_init(void)
 {
	 ADCA.CTRLB = (ADC_RESOLUTION_12BIT_gc | ADC_CONMODE_bm);
	 ADCA.REFCTRL = ADC_REFSEL_AREFB_gc;
	 ADCA.PRESCALER = ADC_PRESCALER_DIV16_gc;
	 ADCA.CH0.CTRL = ADC_CH_INPUTMODE_DIFFWGAIN_gc;
	 ADCA.CH0.MUXCTRL = (ADC_CH_MUXPOS_PIN1_gc | ADC_CH_MUXNEG_PIN6_gc);
	 ADCA.CH0.INTCTRL = ADC_CH_INTLVL0_bm;
	 ADCA.EVCTRL = ADC_EVACT_CH0_gc;
	 ADCA.CTRLA = ADC_ENABLE_bm;
 }
 
 ISR(ADCA_CH0_vect)
 {
	 var = ADCA.CH0.RES;
	 PORTD.OUTTGL = PIN6_bm;
 }