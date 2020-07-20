#include "utils.h"
#include "printf.h"
#include "peripherals/timer.h"

const unsigned int interval = 2000000;
unsigned int curVal = 0;

void timer_init ( void )
{
	// TIMER_CLO is the System Timer Counter Lower 32 bits
	// Increases at a rate of 1 MHz
	curVal = get32(TIMER_CLO);	// Read current count
	curVal += interval;			// Add interval
	put32(TIMER_C1, curVal);	// Set compare 1 to the value
}

// When the value of the counter becomes equal to the value stored in one of the compare registers the corresponding interrupt is fired.
void handle_timer_irq( void ) 
{
	curVal += interval;
	put32(TIMER_C1, curVal); // Set compare 1 to the new value
	put32(TIMER_CS, TIMER_CS_M1); // Write a 1 to Timer Control/Status register to clear interrupt
	printf("Timer interrupt received\n\r");
}
