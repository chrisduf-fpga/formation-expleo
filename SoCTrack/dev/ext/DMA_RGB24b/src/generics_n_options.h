/*
 *
 * listing parameters that configure processing functions
 * parameter type "option" will change design behavior during csim only
 * parameter type "generic" will change design behavior both during csim, cosim and synthesis results
 *
 * convention
 * - option  : VARIABLE_o
 * - generic : VARIABLE_g
 * - constante derivee : VARIABLE_c
 */

#ifndef GENERICS_N_OPTIONS_H
#define GENERICS_N_OPTIONS_H

/*
 *	OPTIONS
 */
#define DEBUG_o
#define IMAGE_W_o        640
#define IMAGE_H_o        480
#define IMAGE_STRIDE_o   IMAGE_W_o   // stride en pixels (>= IMAGE_W_o)


/*
 *	GENERICS
 */

/* --- format pixel --------------------------------------------------------
 * Sortie AXI4-Stream : 1 pixel par coup d'horloge, TDATA sur 24 bits
 *     TDATA[23:16] = R   TDATA[15:8] = G   TDATA[7:0] = B
 */
#define COMP_SIZE_g          8                        // taille d'une composante couleur
#define PIXEL_SIZE_g        (3*COMP_SIZE_g)           // 24 bits RGB888
#define AXI_STREAM_SIZE_g    PIXEL_SIZE_g             // largeur TDATA du master AXI4-Stream
#define PIXEL_PER_CLOCK_g    1                        // ppc sur le port AXI4-Stream

/* --- format memoire ------------------------------------------------------
 * RGB_MM_PACKED_g = 1 : RGB888 "packe", 3 octets par pixel, ordre R,G,B
 *                       -> 16 pixels tiennent exactement dans 3 mots de 128 bits
 * RGB_MM_PACKED_g = 0 : XRGB8888, 4 octets par pixel, mot = 0x00RRGGBB
 *                       -> 4 pixels par mot de 128 bits
 */
#define AXI_MM_SIZE_g       128   // largeur en bits du port AXI4 master (m_axi)
#define RGB_MM_PACKED_g       1

#if RGB_MM_PACKED_g
  #define PX_PER_GROUP_g      16  // nb de pixels par groupe atomique memoire
  #define BEATS_PER_GROUP_g    3  // nb de mots AXI4 par groupe  (16*24 = 3*128)
  #define BURST_LEN_g         40  // nb de mots lus par burst AXI4 (doit diviser BEATS_PER_LINE_c)
#else
  #define MM_PIXEL_SIZE_c     32  // 1 pixel = 1 mot de 32 bits
  #define PX_PER_GROUP_g       4  // 4 pixels par mot de 128 bits
  #define BEATS_PER_GROUP_g    1
  #define BURST_LEN_g         32
#endif

#define MAX_READ_BURST_g     64   // pragma m_axi : puissance de 2, >= BURST_LEN_g
#define MM2S_FIFO_DEPTH_g   256   // plusieurs bursts en vol : absorbe la latence memoire
                                  // et le backpressure AXI4-S

/*
 *	FILE PATHS
 * chemins absolus : la csim Vitis HLS s'execute depuis <prj>/<solution>/csim/build
 * (le testbench accepte aussi 2 arguments : <dir_in> <dir_out>)
 */
#define INPUT_DATA_PATH_o  "/mnt/isaac_sbay0/lbo-ws/Temp/FPGA_EXPLEO/samples/input/"
#define OUTPUT_DATA_PATH_o "/mnt/isaac_sbay0/lbo-ws/Temp/FPGA_EXPLEO/samples/output/"

#endif // GENERICS_N_OPTIONS_H
