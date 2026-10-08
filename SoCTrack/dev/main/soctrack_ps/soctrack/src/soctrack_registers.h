/*
 * SoCTrack control registers.
 *
 * Memory Mapped AXI Peripheral ((axi_dma24_fb_ctr_0 on block design).
 */
#ifndef SOCTRACK_REGISTERS_H
#define SOCTRACK_REGISTERS_H

#include <stdint.h>

/* Peripheral registers base address. */
#define SOCTRACK_REG_BASE 0x84A00000U

/* AXIS source selection is status LSB */
#define SOCTRACK_REG_AXIS_SEL_MASK 	0x00000001

/* AXIS source Test Pattern Generator. */
#define SOCTRACK_AXIS_SEL_TPG 	0

/* AXIS source Frame Buffer. */
#define SOCTRACK_AXIS_SEL_FB	1


#ifdef __cplusplus
extern "C" {
#endif

/* Status registers  (AXI video source selection and control). */
extern volatile uint32_t *const SOCTRACK_REG_STATUS;

/* Frame buffer width (pixels) register. */
extern volatile uint32_t *const SOCTRACK_REG_FB_WIDTH;

/* Frame buffer height (pixels) register. */
extern volatile uint32_t *const SOCTRACK_REG_FB_HEIGHT;

/* Frame buffer base address register.
 * 4 Least Significant Bytes of 64-bit address.
 */
extern volatile uint32_t *const SOCTRACK_REG_FB_ADDR_LOW;

/* Frame buffer base address register.
 * 4 Most Significant Bytes of 64-bit address.
 */
extern volatile uint32_t *const SOCTRACK_REG_FB_ADDR_HIGH;

/* Set AXI register value.
 * Writes data from the host to the FPGA's memory.
 */
void soctrack_reg_set(volatile uint32_t *const reg, uint32_t value);

/* Get AXI register value.
 * Dereferencing the register address is also perfectly fine.
 */
uint32_t soctrack_reg_get(volatile uint32_t *const reg);

#ifdef __cplusplus
}
#endif
#endif /* SOCTRACK_REGISTERS_H */
