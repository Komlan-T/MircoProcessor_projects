/*
 * CFile3.c
 *
 * Created: 11/9/2023 1:58:54 PM
 *  Author: henoc
 */ 
#include <avr/io.h>
#include <avr/interrupt.h>
#include <math.h>
#include "lab7_3_inc.h"
volatile int16_t var;
volatile uint8_t glo_flag = 0;

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
		if (glo_flag)
		{
			write();
			glo_flag = 0;
		}
	}
	return 0;
}

void tcc0_init(void)
{
	TCC0_PER = (2000000 / 1024);
	TCC0_CTRLA = TC_CLKSEL_DIV1024_gc;
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

void usartd0_init(void)
{
	PORTD.OUTSET = PIN3_bm;
	PORTD.DIRSET = PIN3_bm;
	PORTD.DIRCLR = PIN2_bm;

	USARTD0.BAUDCTRLA = (uint8_t)BSEL;
	USARTD0.BAUDCTRLB = (uint8_t)((BSCALE << 4)|(BSEL >> 8));
	
	USARTD0.CTRLC =	(USART_CHSIZE_8BIT_gc | USART_PMODE_ODD_gc | USART_CMODE_ASYNCHRONOUS_gc);

	USARTD0.CTRLB = USART_RXEN_bm | USART_TXEN_bm;
}

void transmit(uint8_t data)
{
	while(!(USARTD0.STATUS & USART_DREIF_bm));
	USARTD0.DATA = data;
}

void write(void)
{
	float voltage = ((float)var * 0.001) + 0.453;
	if(voltage < 0){
		transmit(0x2D);
		voltage = voltage * -1;
	}
	int a = (int)voltage;
	int aa = a + 48;
	transmit((uint8_t)aa);
	float b = 10 * (voltage - a);
	int c = (int)b;
	int cc = c + 48;
	transmit(0x2E);
	transmit((uint8_t)cc);
	float d = 10 * (b - c);
	int e = (int)d;
	int ee = e + 48;
	transmit((uint8_t)ee);
	transmit(0x20);
	transmit(0x56);
	transmit(0x20);
	
	transmit(0x28);
	transmit(0x30);
	transmit(0x78);
	
	
	uint16_t sub = (uint16_t)((voltage - 0.453) / 0.001);
	for (int i = 0; i < 3; i++)
	{
		int x = sub % 16;
		if (x < 10)
		{
			int y = x + 48;
			transmit((uint8_t)y);
		}
		else
		{
			int z = x + 55;
			transmit((uint8_t)z);
		}
		sub = sub / 16;
	}
	
	transmit(0x29);
	
	transmit(0x0D);
	transmit(0x0A);
}

ISR(ADCA_CH0_vect)
{
	var = ADCA.CH0.RES;
	glo_flag = 1;
}