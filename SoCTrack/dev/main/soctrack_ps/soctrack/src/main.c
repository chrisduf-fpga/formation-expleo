/*
 * SoCTrack firmware entry point.
 *
 */

#include <stdio.h>

#include "xil_printf.h"

#include "soctrack.h"
#include "soctrack_fb.h"
#include "soctrack_registers.h"


int main(void)
{
	int err;
	uint32_t axis_sel;

	print("--------\r\n");
	print("SoCTrack\r\n");
    print("\r\n");

	err = soctrack_init();
	if (err) {
		xil_printf("initialization error: %d\r\n", err);
		goto ret;
	}

	xil_printf("main():     0x%08x\r\n", (uintptr_t)main);
	xil_printf("FB address: 0x%08x\r\n", (uintptr_t)soctrack_fb);
    print("\r\n");

    soctrack_reg_set(SOCTRACK_REG_STATUS, SOCTRACK_INITIAL_AXIS_SEL);
    soctrack_reg_set(SOCTRACK_REG_FB_WIDTH, 640u);
    soctrack_reg_set(SOCTRACK_REG_FB_HEIGHT, 480u);
    soctrack_reg_set(SOCTRACK_REG_FB_ADDR_LOW, (uintptr_t)soctrack_fb);
    soctrack_reg_set(SOCTRACK_REG_FB_ADDR_HIGH,0);

    xil_printf("CTRL_REG_STATUS:        %p    0x%08lx\r\n", SOCTRACK_REG_STATUS, *SOCTRACK_REG_STATUS);
    xil_printf("CTRL_REG_FB_WIDTH:      %p    %lu\r\n", SOCTRACK_REG_FB_WIDTH, *SOCTRACK_REG_FB_WIDTH);
    xil_printf("CTRL_REG_FB_HEIGHT:     %p    %lu\r\n", SOCTRACK_REG_FB_HEIGHT, *SOCTRACK_REG_FB_HEIGHT);
    xil_printf("CTRL_REG_FB_ADDR_HIGH:  %p    0x%08lx\r\n", SOCTRACK_REG_FB_ADDR_HIGH, *SOCTRACK_REG_FB_ADDR_HIGH);
    xil_printf("CTRL_REG_FB_ADDR_LOW:   %p    0x%08lx\r\n", SOCTRACK_REG_FB_ADDR_LOW, *SOCTRACK_REG_FB_ADDR_LOW);
    print("\r\n");

    axis_sel = *SOCTRACK_REG_STATUS & SOCTRACK_REG_AXIS_SEL_MASK;
    xil_printf("CTRL_AXIS_SEL: %s\r\n", (axis_sel == SOCTRACK_AXIS_SEL_TPG) ? "CTRL_AXIS_SEL_TPG" : "CTRL_AXIS_SEL_IMG");

    /* Initialization complete, turn on green LED. */
    soctrack_gpio_led_set(0x02);

ret:
	/* Firmware usually return 0 (or don't return). */
	soctrack_deinit();
	return 0;
}
