/*
 * SoCTrack.
 */
#ifndef SOCTRACK_H
#define SOCTRACK_H

/* Initial AXIS video source (Test Pattern Generator). */
#define SOCTRACK_INITIAL_AXIS_SEL	0


#ifdef __cplusplus
extern "C" {
#endif

/* SocTrack System initialization. */
int soctrack_init(void);

/* SocTrack System cleanup. */
void soctrack_deinit(void);

#ifdef __cplusplus
}
#endif
#endif /* SOCTRACK_H */
