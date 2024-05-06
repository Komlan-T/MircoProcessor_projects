#define TABSIZE 16
#include <avr/io.h>
int main(void){
	// create an array of 8-bit value with a size of 16; replace ?? with the values in Table 1, separated by commas
	uint8_t IN_TAB [TABSIZE] = {201,0x22,051,91,0x91,0x2A,'U',0130,'#',0b01010101,'J',0x21,0x55,32,0b00011110,0};
	uint8_t *IN_TAB_P = &IN_TAB; // create a pointer to this table
	// Note that using the // create a pointer to this table & above is not necessary since by default, 8-bit arrays are
	// 	pointers which point to the first element of the array.
	// Thus, using both *IN_TAB_P = &IN_TAB;   or   *IN_TAB_P = IN_TAB; will produce the same
	// 	functionality since IN_TAB  is an address; however, to remain consistent we will use the  ampersand.

	// Initialize a pointer to point to the output table at location 0x3700. Call it OUT_TAB_P
	uint8_t OUT_TAB = 0x3700;
	uint8_t *OUT_TAB_P = &OUT_TAB;
	uint8_t BIT5;
	//To start the processing, we can use the following template:
	while(1){
		// Loop till null, i.e., loop while the values at that address are non-zero (not null)
		while(*IN_TAB_P){
			// Check for the conditions
			// Recall when using an *, we are analyzing the value at that pointer
			// Dereference IN_TAB_P and check if bit 5 is set (See the Example 2).
			//if bit 5 was set, then …
			BIT5 = (*IN_TAB_P) & (1 << 5);
			if(BIT5 == (1 << 5)){
				// check if the value at IN_TAB_P times two is greater than or equal to 70
				if((*IN_TAB_P) * 2 >= 70) {
					/*Store the result to address pointed by OUT_TAB_P */
					// remember to alter the data at an address using a pointer, then you must use an (*). (See Example 1)
					*OUT_TAB_P = *IN_TAB_P;
					/*Increment OUT_TAB_P to move to next available space */
					OUT_TAB_P+=1;
				}
			}
			else{
				// if the input value (dereference IN_TAB_P) +3 is less than 78 …
				if((*IN_TAB_P) + 3 < 78){
					/*Store the result to address pointed by OUT_TAB_P */
					*OUT_TAB_P = *IN_TAB_P;
					/*Increment OUT_TAB_P to move to available space */
					OUT_TAB_P+=1;
				}
			}
			IN_TAB_P+=1;
		}
	}
	return 0;
}