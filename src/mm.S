.globl memzero
memzero:
	// xzr is 64-bit zero register
	str xzr, [x0], #8 // set x0 to 0 and update x0 address by 8
	subs x1, x1, #8 // Decrement x1 by 8
	// Condition codes are set from arithmetic instruction with S
	b.gt memzero // Call memzero if subs result is greater than 0
	ret
