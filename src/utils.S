.globl put32
put32:
	str w1,[x0] // Stores bottom 32-bits of x1 into the memory address x0
	ret

.globl get32
get32:
	// return value is always sent in x0 if it is a simple value
	// Loads the bottom 32-bits at address x0 into register x0
	ldr w0,[x0] 
	ret

.globl delay
delay:
	subs x0, x0, #1
	bne delay
	ret	

.globl get_el
get_el:
    mrs x0, CurrentEL
    lsr x0, x0, #2
    ret
