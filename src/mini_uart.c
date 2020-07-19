#include "utils.h"
#include "peripherals/mini_uart.h"
#include "peripherals/gpio.h"

void uart_send ( char c )
{
	//Infinite loops purpose is to verify whether the device is ready to transmit or receive data
	while(1) {
		//Bit five, if set to 1, tells us that the transmitter is empty, meaning that we can write to the UART (0010_0000)
		if(get32(AUX_MU_LSR_REG)&0x20) 
			break;
	}
	//Store the value of the transmitted character
	put32(AUX_MU_IO_REG,c);
}

char uart_recv ( void )
{
	//Infinite loops purpose is to verify whether the device is ready to transmit or receive data
	while(1) {
		//Bit zero, if set to 1, indicates that the data is ready (0000_0001)
		if(get32(AUX_MU_LSR_REG)&0x01) 
			break;
	}
	//Read value of returned character
	return(get32(AUX_MU_IO_REG)&0xFF);
}

void uart_send_string(char* str)
{
	for (int i = 0; str[i] != '\0'; i ++) {
		uart_send((char)str[i]);
	}
}

void uart_init ( void )
{
	unsigned int selector;

	// put32 and get32 allow us to read and write some data to and from a 32-bit register. Implemented in util.S

	// The GPFSEL1 register is used to control alternative functions for pins 10-19
	selector = get32(GPFSEL1);
	selector &= ~(7<<12);                   // clean gpio14 -> set bits 12-14 to 0
	selector |= 2<<12;                      // set alt5 for gpio14 -> 0010 for alt5
	selector &= ~(7<<15);                   // clean gpio15 -> set bits 15-17 to 0
	selector |= 2<<15;                      // set alt5 for gpio15 -> 0010 for alt5

	put32(GPFSEL1,selector);

	// GPIO states are pull-up, pull-down and neither. We want neither.
	put32(GPPUD,0); 						// Write to GPPUD to set the required control signal (i.e. Pull-up or Pull-Down or neither to remove the current Pull-up/down)

	delay(150);								// Wait 150 cycles – this provides the required set-up time for the control signal
	// Disable pull up/down for pin 14,15
	put32(GPPUDCLK0,(1<<14)|(1<<15));		// Write to GPPUDCLK0 to clock the control signal into the GPIO pads you wish to modify – NOTE only the pads which receive a clock will be modified, all others will retain their previous state.
	delay(150);								// Wait 150 cycles – this provides the required hold time for the control signal
	// Write to GPPUD to remove the control signal -> just means setting GPPUD to 0 (It's already 0. Skip step.).
	put32(GPPUDCLK0,0);						// Write to GPPUDCLK0 to make it take effect.

	put32(AUX_ENABLES,1);                   //Enable mini uart (this also enables access to it registers)
	put32(AUX_MU_CNTL_REG,0);               //Disable auto flow control and disable receiver and transmitter (for now)
	put32(AUX_MU_IER_REG,0);                //Disable receive and transmit interrupts
	put32(AUX_MU_LCR_REG,3);                //Enable 8 bit mode. Mini UART can support either 7- or 8-bit operations. This is because an ASCII character is 7 bits for the standard set and 8 bits for the extended.
	put32(AUX_MU_MCR_REG,0);                //Set RTS line to be always high (used in flow control)
	// baudrate = system_clock_freq / (8 * ( baudrate_reg + 1 )), system_clock_freq is 250 MHz so baudrate_reg is 270
	put32(AUX_MU_BAUD_REG,270);             //Set baud rate to 115200

	put32(AUX_MU_CNTL_REG,3);               //Finally, enable transmitter and receiver
}

// This function is required by printf function
void putc ( void* p, char c)
{
	uart_send(c);
}
