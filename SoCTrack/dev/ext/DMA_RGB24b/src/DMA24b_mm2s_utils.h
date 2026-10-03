#ifndef DMA24B_MM2S_UTILS_H
#define DMA24B_MM2S_UTILS_H

// vhls common lib
#include <string.h>
#include <hls_stream.h>
#include <ap_axi_sdata.h>

// dedicated lib
#include "generics_n_options.h"

// type definitions
typedef ap_uint<AXI_MM_SIZE_g>            axi_data_slv;          // 1 mot (beat) du port AXI4 m_axi
typedef ap_uint<AXI_MM_SIZE_g*BEATS_PER_GROUP_g> mm_group_t;     // groupe atomique de pixels en memoire
typedef ap_uint<PIXEL_SIZE_g>             video_pixel_t;         // 1 pixel RGB888

typedef ap_axiu<AXI_STREAM_SIZE_g,1,0,0>  video_stream_element_out;  // TUSER 1 bit = SOF
typedef hls::stream<video_stream_element_out> video_stream_out;
typedef hls::stream<axi_data_slv,MM2S_FIFO_DEPTH_g> mm_fifo_t;   // canal dataflow entre le fetch AXI4 et la sortie AXI4-S

typedef ap_uint<12>   param_type_0;
typedef ap_uint<1>    param_type_1;

// Vitis HLS n'expanse pas les macros dans les directives #pragma HLS :
// on passe par _Pragma() avec une double indirection pour pouvoir parametrer
// les pragmas (II, max_read_burst_length) avec les generics ci-dessus.
#define PRAGMA_SUB(x) _Pragma(#x)
#define PRAGMA_HLS(x) PRAGMA_SUB(x)

// constantes derivees
// nb de mots AXI4 par ligne utile / par ligne de stride, et taille du buffer DDR
const int BEATS_PER_LINE_c   = (IMAGE_W_o      / PX_PER_GROUP_g) * BEATS_PER_GROUP_g;
const int MM_LINE_STRIDE_c   = (IMAGE_STRIDE_o / PX_PER_GROUP_g) * BEATS_PER_GROUP_g;
const int DDR_SIZE           = MM_LINE_STRIDE_c * IMAGE_H_o;

// verifications de coherence des generics
#if (IMAGE_W_o % PX_PER_GROUP_g) != 0
  #error "IMAGE_W_o doit etre un multiple de PX_PER_GROUP_g"
#endif
#if (IMAGE_STRIDE_o % PX_PER_GROUP_g) != 0
  #error "IMAGE_STRIDE_o doit etre un multiple de PX_PER_GROUP_g"
#endif
#if ((((IMAGE_W_o/PX_PER_GROUP_g)*BEATS_PER_GROUP_g) % BURST_LEN_g) != 0)
  #error "le nombre de mots AXI4 par ligne doit etre un multiple de BURST_LEN_g"
#endif

/*
 * Extraction du pixel p d'un groupe memoire, et remise dans l'ordre TDATA = {R,G,B}.
 *
 * RGB_MM_PACKED_g = 1 : la memoire contient les octets R,G,B consecutifs en ordre raster.
 *                       Sur un bus little-endian, l'octet d'adresse la plus faible est
 *                       le LSB du mot -> R est dans les bits de poids faible du pixel brut.
 * RGB_MM_PACKED_g = 0 : la memoire contient un mot 32 bits 0x00RRGGBB par pixel.
 */
inline video_pixel_t DMA24b_mm2s_get_pixel(const mm_group_t &grp, int p){
	#pragma HLS INLINE
	video_pixel_t px;
#if RGB_MM_PACKED_g
	ap_uint<PIXEL_SIZE_g> raw = grp.range(PIXEL_SIZE_g*(p+1)-1, PIXEL_SIZE_g*p);
	px.range(3*COMP_SIZE_g-1, 2*COMP_SIZE_g) = raw.range(  COMP_SIZE_g-1,           0); // R = octet 0
	px.range(2*COMP_SIZE_g-1,   COMP_SIZE_g) = raw.range(2*COMP_SIZE_g-1,   COMP_SIZE_g); // G = octet 1
	px.range(  COMP_SIZE_g-1,             0) = raw.range(3*COMP_SIZE_g-1, 2*COMP_SIZE_g); // B = octet 2
#else
	ap_uint<MM_PIXEL_SIZE_c> w = grp.range(MM_PIXEL_SIZE_c*(p+1)-1, MM_PIXEL_SIZE_c*p);
	px = w.range(PIXEL_SIZE_g-1, 0);                                                      // 0x00RRGGBB
#endif
	return px;
}

/*
 * Fonction miroir de la precedente : insere un pixel {R,G,B} dans un groupe memoire.
 * Utilisee uniquement par le testbench pour construire l'image en DDR.
 */
inline void DMA24b_mm2s_set_pixel(mm_group_t &grp, int p, video_pixel_t px){
	#pragma HLS INLINE
#if RGB_MM_PACKED_g
	ap_uint<PIXEL_SIZE_g> raw;
	raw.range(  COMP_SIZE_g-1,             0) = px.range(3*COMP_SIZE_g-1, 2*COMP_SIZE_g); // octet 0 = R
	raw.range(2*COMP_SIZE_g-1,   COMP_SIZE_g) = px.range(2*COMP_SIZE_g-1,   COMP_SIZE_g); // octet 1 = G
	raw.range(3*COMP_SIZE_g-1, 2*COMP_SIZE_g) = px.range(  COMP_SIZE_g-1,             0); // octet 2 = B
	grp.range(PIXEL_SIZE_g*(p+1)-1, PIXEL_SIZE_g*p) = raw;
#else
	ap_uint<MM_PIXEL_SIZE_c> w = 0;
	w.range(PIXEL_SIZE_g-1, 0) = px;
	grp.range(MM_PIXEL_SIZE_c*(p+1)-1, MM_PIXEL_SIZE_c*p) = w;
#endif
}

#endif // DMA24B_MM2S_UTILS_H
