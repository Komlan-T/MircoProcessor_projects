/*
 * CFile1.c
 *
 * Created: 11/4/2023 10:54:53 AM
 *  Author: henoc
 */ 
#include <avr/io.h>
#include <avr/interrupt.h>
#include "spi.h"
#include "lsm6dsl.h"
#include "lsm6dsl_registers.h"
#include "usart.h"

volatile uint8_t x_axis_l;
volatile uint8_t x_axis_h;
volatile uint8_t y_axis_l;
volatile uint8_t y_axis_h;
volatile uint8_t z_axis_l;
volatile uint8_t z_axis_h;
volatile uint8_t accel_flag = 0;

volatile uint16_t x;
volatile uint16_t y;
volatile uint16_t z;

int main()
{
	spi_init();
	LSM_init();
	usartd0_init();
	dac_init();
	tcc0_init();
	
	PMIC_CTRL = PMIC_LOLVLEN_bm;
	CPU_SREG = CPU_I_bm;
	
	PORTK.OUTSET = PIN0_bm;
	PORTK.DIRSET = PIN0_bm;
	
	
	while(1){
		if (accel_flag)
		{
			x_axis_l = LSM_read(OUTX_L_XL);
			transmit(x_axis_l);
			x_axis_h = LSM_read(OUTX_H_XL);
			transmit(x_axis_h);
			y_axis_l = LSM_read(OUTY_L_XL);
			transmit(y_axis_l);
			y_axis_h = LSM_read(OUTY_H_XL);
			transmit(y_axis_h);
			z_axis_l = LSM_read(OUTZ_L_XL);
			transmit(z_axis_l);
			z_axis_h = LSM_read(OUTZ_H_XL);
			//transmit(z_axis_h);
			
			x = x_axis_h | x_axis_l;
			y = y_axis_h | y_axis_l;
			z = z_axis_h | z_axis_l;
			
			if ((z > 0) & (x <= 0) & (y <= 0))
			{
				transmit('F');
				transmit('l');
				transmit('a');
				transmit('t');
				transmit(' ');
				transmit('o');
				transmit('n');
				transmit(' ');
				transmit('t');
				transmit('a');
				transmit('b');
				transmit('l');
				transmit('e');
				while(!(DACB.STATUS & DAC_CH0DRE_bm));
				DACA.CH0DATA = x;

			}
			if ((x > 0) & (x == 0) & (y == 0))
			{
				transmit('O');
				transmit('M');
				transmit('B');
				transmit(' ');
				transmit('p');
				transmit('i');
				transmit('n');
				transmit('s');
				transmit(' ');
				transmit('o');
				transmit('n');
				transmit(' ');
				transmit('t');
				transmit('o');
				transmit('p');
				while(!(DACB.STATUS & DAC_CH0DRE_bm));
				DACA.CH0DATA = y;

			}
			if ((y < 0) & (x == 0) & (z == 0))
			{
				transmit('U');
				transmit('S');
				transmit('B');
				transmit(' ');
				transmit('o');
				transmit('n');
				transmit(' ');
				transmit('t');
				transmit('o');
				transmit('p');
				while(!(DACB.STATUS & DAC_CH0DRE_bm));
				DACA.CH0DATA = z;

			}
			accel_flag = 0;
			CPU_SREG = CPU_I_bm;
		}
	}
	
	return 0;
}

void transmit(uint8_t XL_data)
{
	usartd0_out_char(XL_data);
}

void dac_init(void)
{
	DACA.CTRLB = DAC_CHSEL_SINGLE_gc;
	DACA.CTRLC = DAC_REFSEL_AREFB_gc;
	DACA.CTRLA = (DAC_CH0EN_bm | DAC_ENABLE_bm);
}

void tcc0_init(void)
{
	TCC0_PER = (((2000000 / 4) * 370) / 1000);
	TCC0.CNT = 0;
	TCC0_CTRLA = TC_CLKSEL_DIV4_gc;
}

ISR(PORTC_INT0_vect)
{
  CPU_SREG = 0x00;
  accel_flag = 1;	
}

ISR(TCC0_OVF_vect)
{
	PORTK.OUTTGL = PIN0_bm;
}