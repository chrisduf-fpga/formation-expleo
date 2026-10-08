/*
 * SoCTrack GPIO.
 *
 * Memory Mapped AXI Peripheral (axi_gpio_0 on block design).
 */
#ifndef SOCKTRACK_GPIO_H
#define SOCKTRACK_GPIO_H

#include <stdint.h>

#include "xparameters.h"


#define SOCTRACK_GPIO_DEVICE_ID  XPAR_GPIO_0_DEVICE_ID

/* GPIO device base address. */
#define SOCTRACK_GPIO_BASE_ADDR 0x40000000

/* GPIO LED, register width 3 (BGR). */
#define SOCTRACK_GPIO_LED	SOCTRACK_GPIO_BASE_ADDR

/* GPIO LED outputs (3 bits). */
#define SOCTRACK_GPIO_LED_MASK   0x07

#define SOCTRACK_GPIO_LED_CHANNEL 1
#define SOCTRACK_GPIO_BTN_CHANNEL 2


#ifdef __cplusplus
extern "C" {
#endif

/* Initialize GPIO device. */
int soctrack_gpio_init(void);

/* Set GPIO LED (3-bit, BGR). */
void soctrack_gpio_led_set(uint8_t rgb);


#ifdef __cplusplus
}
#endif
#endif /* SOCKTRACK_GPIO_H */
