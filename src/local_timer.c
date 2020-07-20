#include "utils.h"
#include "printf.h"
#include "peripherals/local_timer.h"

const unsigned int reload_value = 2000000000;

void timer_init_local ( void )
{
	put32(LOCAL_TIMER_CS, LOCAL_TIMER_CS_INIT|reload_value); // Turn on timer and set reload value
	put32(LOCAL_TIMER_LIR, LOCAL_TIMER_LIR_IRQ_CORE0);   // Set the local interrupt to go to core 0
}

void handle_timer_irq_local ( void ) 
{
	put32(LOCAL_TIMER_CLR, LOCAL_TIMER_CLR_RELOAD); // You do not need to do a reload. It automatically happens.
	// You also do not have to clear bit 31 for a new interrupt to happen, but you should clear it.
	printf("Local timer interrupt received\n\r");
}
