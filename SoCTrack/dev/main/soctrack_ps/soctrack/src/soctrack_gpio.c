/*
 * SoCTrack GPIO.
 */
#include "soctrack_gpio.h"

#include "xgpio.h"


static XGpio gpio_dev;


int soctrack_gpio_init(void)
{
	int ret = XGpio_Initialize(&gpio_dev, SOCTRACK_GPIO_DEVICE_ID);
	if (ret != XST_SUCCESS) {
		return ret;
	}

	/* Specify which ports are input and which are output.
	 * Bits set to 0 are output and bits set to 1 are input.
	 */
	XGpio_SetDataDirection(&gpio_dev, SOCTRACK_GPIO_LED_CHANNEL, ~SOCTRACK_GPIO_LED_MASK);

	return 0;
}

void soctrack_gpio_led_set(uint8_t bgr)
{
	XGpio_DiscreteWrite(&gpio_dev, SOCTRACK_GPIO_LED_CHANNEL, bgr);
}
