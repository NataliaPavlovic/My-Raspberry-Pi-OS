#include "mm.h"

#include "arm/sysregs.h"

// First, we specify that everything defined in boot.S should go in the .text.boot section.
// Section is placed at the beginning of the kernel image in the linker script, so start function gets executed first.
.section ".text.boot"

.globl _start
// All 4 cores start to execute this
_start:
	// mrs copies system register into gpr
    mrs	x0, mpidr_el1		// mpidr_el1 is a system register		
	and	x0, x0,#0xFF		// Check processor id

	// Raspberry Pi 3 has 4 cores. Turn off 3 cores and work with 1
	cbz	x0, master			// Branch to master if processor ID is 0
	b	proc_hang			// Hang for all non-primary CPU
	b master

proc_hang: 
	b 	proc_hang

master:
	// SCTLR register controls if cache is enabled and if MMU is enabled
	// EL1 postfix means EL1 or higher can access it
	// Here we set EL0 and EL1 to use little endian, disabled I and D caches and turned off MMU
	ldr	x0, =SCTLR_VALUE_MMU_DISABLED
	msr	sctlr_el1, x0		

	// Hypervisor Configuration Register (EL2)
	// We are not using EL2, but we need to set a bit to say we are using AArch64 not AArch32
	ldr	x0, =HCR_VALUE
	msr	hcr_el2, x0

	// Secure Configuration Register (EL3)
	// Controls whether all lower levels are executed in "secure" or "nonsecure" state
	// Secure state means memory accesses from those ELs can access secure memory
	// Controls EL2 state
	// Set EL0 and EL1 to be nonsecure state (cannot access secure memory)
	// Set external aborts, SError interrupts and physical FIQ interrupts to be taken to EL3
	ldr	x0, =SCR_VALUE
	msr	scr_el3, x0

	// Saved Program Status Register (EL3)
	// SPSR contains condition flags (N, C, V...), interrupt disable bits, some other info
	// Disabled all types of interrupts (masked)
	// Set EL to be EL1 and SP to be EL1 dedicated SP (5 << 0 = 101)
	ldr	x0, =SPSR_VALUE_EL2
	msr	spsr_el3, x0

	adr	x0, el2_entry		
	msr	elr_el3, x0

	// Saved processor state in SPDR is restored and execution starts at elr_el3
	eret	

// Exercise to go from EL3 to EL2 and then to EL1
el2_entry:
	ldr	x0, =SPSR_VALUE_EL1
	msr	spsr_el2, x0

	adr	x0, el1_entry		
	msr	elr_el2, x0

	eret

el1_entry:
	adr		x0, bss_begin
	adr		x1, bss_end
	sub		x1, x1, x0

	// memzero takes 2 args: start address (bss_begin) and size of section that needs to be cleaned (bss_end - bss_begin)
	bl 		memzero				// Clean the .bss section by calling memzero

	mov		sp, #LOW_MEMORY 	// Initialize the stack pointer to #LOW_MEMORY

    mrs		x0, mpidr_el1		// mpidr_el1 is a system register		
	and		x0, x0,#0xFF		// Check processor id

	bl		kernel_main			// Pass execution to the kernel_main function
	b 		proc_hang			// should never come here

/*
	// In ARMv8 architecture, by convention, the first seven arguments are passed to the called function via registers x0–x6.

	cbnz	x0, L1				// Conditional branch of non zero

	// processor ID 0
	mov		sp, #LOW_MEMORY 	// Initialize the stack pointer to #LOW_MEMORY
	mov 	x19, x0				// Save x0 contents into x19 (callee-saved register)

	// bss_begin and bss_end are defined in linker.ld
	// The bss section contains data that needs to be set to all 0s. To avoid storing the entire section in the ELF binary, we 
	// just store the begin and end and fill in the zeros now using memzero call.
	// bss section contains uninitialized global variables and static local variables (automatically set to 0).
	adr		x0, bss_begin
	adr		x1, bss_end
	sub		x1, x1, x0

	// memzero takes 2 args: start address (bss_begin) and size of section that needs to be cleaned (bss_end - bss_begin)
	bl 		memzero				// Clean the .bss section by calling memzero

	mov		x0, x19				// Move the value saved into x19 into the x0 argument register
	b L2
	// Other processors
L1:	mov		x1, #LOW_MEMORY 	// Initialize the stack pointer to #LOW_MEMORY << processor_id
	lsl		x1, x1, x0
	mov		sp, x1
L2:
	bl	kernel_main			// Pass execution to the kernel_main function
	b 	proc_hang			// should never come here
*/