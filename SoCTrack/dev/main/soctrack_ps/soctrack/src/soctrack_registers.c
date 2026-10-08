/*
 * SoCTrackregisters.
 *
 * Host writes into FPGA memory with xil_put().
 * FPGA only reads this memory, xil_get() unnecessary on host.
 *
 */
#include "soctrack_registers.h"

#include <stdint.h>

#include "xil_io.h"

#define REG_STATUS       SOCTRACK_REG_BASE
#define REG_FB_WIDTH     (SOCTRACK_REG_BASE + 4)
#define REG_FB_HEIGHT    (SOCTRACK_REG_BASE + 8)
#define REG_FB_ADDR_LOW  (SOCTRACK_REG_BASE + 12)
#define REG_FB_ADDR_HIGH (SOCTRACK_REG_BASE + 16)

volatile uint32_t *const SOCTRACK_REG_STATUS = (volatile uint32_t *)REG_STATUS;
volatile uint32_t *const SOCTRACK_REG_FB_WIDTH = (volatile uint32_t *)REG_FB_WIDTH;
volatile uint32_t *const SOCTRACK_REG_FB_HEIGHT = (volatile uint32_t *)REG_FB_HEIGHT;
volatile uint32_t *const SOCTRACK_REG_FB_ADDR_LOW = (volatile uint32_t *)REG_FB_ADDR_LOW;
volatile uint32_t *const SOCTRACK_REG_FB_ADDR_HIGH = (volatile uint32_t *)REG_FB_ADDR_HIGH;

void soctrack_reg_set(volatile uint32_t *const reg, uint32_t value)
{
	Xil_Out32((uintptr_t)reg, value);
}

uint32_t soctrack_reg_get(volatile uint32_t *const reg)
{
	return *reg;
}
