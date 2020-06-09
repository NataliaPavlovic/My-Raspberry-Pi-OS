#include "mm.h"

// First, we specify that everything defined in boot.S should go in the .text.boot section.
// Section is placed at the beginning of the kernel image in the linker script, so start function gets executed first.
.section ".text.boot"

.globl _start
// All 4 cores start to execute this
_start:
	mrs	x0, mpidr_el1		// mpidr_el1 is a system register		
	and	x0, x0,#0xFF		// Check processor id

	// Raspberry Pi 3 has 4 cores. Turn of 3 cores and work with 1
	//cbz	x0, master			// Branch to master if processor ID is 0
	//b	proc_hang			// Hang for all non-primary CPU
	b master

proc_hang: 
	b 	proc_hang

master:
	// In ARMv8 architecture, by convention, the first seven arguments are passed to the called function via registers x0–x6.
	adr	x0, bss_begin
	adr	x1, bss_end
	sub	x1, x1, x0

	// memzero takes 2 args: start address (bss_begin) and size of section that needs to be cleaned (bss_end - bss_begin)
	bl 	memzero				// Clean the .bss section by calling memzero
	
	mrs	x0, mpidr_el1		// mpidr_el1 is a system register		
	and	x0, x0,#0xFF		// Get processor id

	cbnz	x0, L1
	mov		sp, #LOW_MEMORY 	// Initialize the stack pointer
	b L2
L1:	mov		x1, #LOW_MEMORY 	// Initialize the stack pointer
	lsl		x1, x1, x0
	mov		sp, x1
L2:
	bl	kernel_main			// Pass execution to the kernel_main function
	b 	proc_hang			// should never come here