/*
 * SoCTrack.
 */
#include "soctrack.h"

#include "platform.h"

#include "soctrack_gpio.h"

int soctrack_init(void)
{
	int ret;

	/* Generated (platform.c) */
	init_platform();

	ret = soctrack_gpio_init();

	return ret;
}

void soctrack_deinit(void)
{
	cleanup_platform();
}
