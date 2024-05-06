/*
 * IncFile1.h
 *
 * Created: 11/12/2023 3:04:09 PM
 *  Author: henoc
 */ 


#ifndef INCFILE1_H_
#define INCFILE1_H_

void tcc0_init(void);

void adc_init(void);

void usartd0_init(void);

void transmit(uint8_t data);

uint8_t receive(void);

#endif /* INCFILE1_H_ */