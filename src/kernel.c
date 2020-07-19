#include "printf.h"
#include "mini_uart.h"
#include "utils.h"

volatile int core_counter = 0;

// It works with the Mini UART device to print to screen and read user input. 
// The kernel just prints Hello, world! and then enters an infinite loop that 
// reads characters from the user and sends them back to the screen.
void kernel_main(int proc_id)
{
	while(core_counter != proc_id)
	{
		delay(10);
	}

	if(0 == proc_id)
	{
		uart_init();
		init_printf(0, putc);
		int el = get_el();
		printf("Exception level: %d \r\n", el);
	}

	uart_send_string("Hello, from processor ");
	uart_send((char) proc_id+'0');
	uart_send_string("\r\n");

	// uart_send_string("Hello, world!\r\n");

	core_counter++;

	if(0 == proc_id)
	{
		while (1) {
		uart_send(uart_recv());
		}
	}
}
