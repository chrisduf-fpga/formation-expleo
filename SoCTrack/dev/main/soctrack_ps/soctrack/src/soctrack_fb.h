/*
 * SoCTrack Frame Buffer.
 *
 */
#ifndef SOCTRACK_FB_H
#define SOCTRACK_FB_H

#include <stdint.h>

/* Frame buffer size (640 x 480 pixels). */
#define SOCTRACK_FB_SIZE 921600


#ifdef __cplusplus
extern "C" {
#endif

extern uint8_t soctrack_fb[SOCTRACK_FB_SIZE];


#ifdef __cplusplus
}
#endif
#endif /* SOCTRACK_FB_H */
