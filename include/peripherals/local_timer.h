#ifndef	_P_LOCAL_TIMER_H
#define	_P_LOCAL_TIMER_H

#include "peripherals/base.h"

#define LOCAL_TIMER_CS              (PBASELOCAL+0x00000034) // Control and Status
#define LOCAL_TIMER_CLR             (PBASELOCAL+0x00000038) // Clear and Reload
#define LOCAL_TIMER_LIR             (PBASELOCAL+0x00000024) // Local Interrupt Routing

#define LOCAL_TIMER_CS_INIT         ((1 << 29) | (1 << 28))
#define LOCAL_TIMER_CLR_RELOAD      (1 << 31)

#define LOCAL_TIMER_LIR_IRQ_CORE0   (0)

#endif  /*_P_TIMER_H */