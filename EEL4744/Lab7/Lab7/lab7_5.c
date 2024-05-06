/*
 * CFile3.c
 *
 * Created: 11/9/2023 1:58:54 PM
 *  Author: henoc
 */ 
#include <avr/io.h>
#include <avr/interrupt.h>
#include <math.h>
#include "lab7_5_inc.h"
volatile int16_t var;
volatile uint8_t glo_flag = 0;
volatile uint8_t read;
volatile uint8_t B = 0;
volatile uint8_t F = 0;

#define BSEL     (9)
#define BSCALE   (-7)


int main()
{
	adc_init();
	tcc0_init();
	usartd0_init();
	
	PMIC_CTRL = PMIC_LOLVLEN_bm;
	CPU_SREG = CPU_I_bm;
	
	while (1)
	{
		if (B)
		{
			//F = 0;
			//ADCA.CH0.CTRL = (ADC_CH_INPUTMODE_DIFFWGAIN_gc | ADC_CH_GAIN_1X_gc);
			ADCA.CH0.MUXCTRL = (ADC_CH_MUXPOS_PIN1_gc | ADC_CH_MUXNEG_PIN6_gc);
			
		}
		if (F)
		{
			//B = 0;
			//ADCA.CH0.CTRL = (ADC_CH_INPUTMODE_DIFFWGAIN_gc | ADC_CH_GAIN_4X_gc);
			ADCA.CH0.MUXCTRL = (ADC_CH_MUXPOS_PIN5_gc | ADC_CH_MUXNEG_PIN4_gc);
			//int16_t var2 = var;
			//uint8_t low = var2 >> 8;
			//transmit(low);
			//int16_t var3 = var;
			//uint8_t high = var3 & 0x00FF;
			//transmit(high);
		}
		if (glo_flag)
		{
			int16_t var2 = var;
			uint8_t low = var2 >> 8;
			transmit(low);
			int16_t var3 = var;
			uint8_t high = var3 & 0x00FF;
			transmit(high);
			glo_flag = 0;
		}
	}
	return 0;
}

void tcc0_init(void)
{
	TCC0_PER = (((2000000 / 4) * 6) / 1000);
	TCC0_CTRLA = TC_CLKSEL_DIV4_gc;
	EVSYS.CH0MUX = EVSYS_CHMUX_TCC0_OVF_gc;
}

void adc_init(void)
{
	ADCA.CTRLB = (ADC_RESOLUTION_12BIT_gc | ADC_CONMODE_bm);
	ADCA.REFCTRL = ADC_REFSEL_AREFB_gc;
	ADCA.PRESCALER = ADC_PRESCALER_DIV16_gc;
	ADCA.CH0.CTRL = (ADC_CH_INPUTMODE_DIFFWGAIN_gc | ADC_CH_GAIN_1X_gc);
	ADCA.CH0.MUXCTRL = (ADC_CH_MUXPOS_PIN1_gc | ADC_CH_MUXNEG_PIN6_gc);
	ADCA.CH0.INTCTRL = ADC_CH_INTLVL0_bm;
	ADCA.EVCTRL = ADC_EVACT_CH0_gc;
	ADCA.CTRLA = ADC_ENABLE_bm;
}

void usartd0_init(void)
{
	PORTD.OUTSET = PIN3_bm;
	PORTD.DIRSET = PIN3_bm;
	PORTD.DIRCLR = PIN2_bm;

	USARTD0.BAUDCTRLA = (uint8_t)BSEL;
	USARTD0.BAUDCTRLB = (uint8_t)((BSCALE << 4)|(BSEL >> 8));
	
	USARTD0.CTRLC =	(USART_CHSIZE_8BIT_gc | USART_PMODE_ODD_gc | USART_CMODE_ASYNCHRONOUS_gc);

	USARTD0.CTRLB = USART_RXEN_bm | USART_TXEN_bm;
	
	USARTD0.CTRLA = USART_RXCINTLVL_LO_gc;
}

void transmit(uint8_t data)
{
	while(!(USARTD0.STATUS & USART_DREIF_bm));
	USARTD0.DATA = data;
}

uint8_t receive(void)
{
	while(!(USARTD0.STATUS & USART_RXCIF_bm));
	uint8_t save = USARTD0.DATA;
	return save;
}

ISR(ADCA_CH0_vect)
{
	var = ADCA.CH0.RES;
	glo_flag = 1;
}

ISR(USARTD0_RXC_vect)
{
	//read = receive();
	read = USARTD0.DATA;
	if(read == 'B')
	{
		B = 1;
	}
	else if(read == 'F')
	{
		F = 1;
	}
}