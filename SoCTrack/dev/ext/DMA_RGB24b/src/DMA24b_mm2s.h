#ifndef DMA24B_MM2S_H
#define DMA24B_MM2S_H

#include "DMA24b_mm2s_utils.h"

/*
 * DMA RGB memory-mapped to stream
 *
 *   entree  : image RGB en memoire, lue par un port AXI4 master (m_axi)
 *   sortie  : port AXI4-Stream master, 1 pixel RGB888 par coup d'horloge
 *             TDATA[23:16]=R  TDATA[15:8]=G  TDATA[7:0]=B
 *             TLAST = 1 sur le dernier pixel de chaque ligne  (EOL)
 *             TUSER = 1 sur le premier pixel de l'image       (SOF)
 */

// top level : porte les pragmas d'interface
void DMA24bUnit_mm2s (video_stream_out &STR_video_out, param_type_0 image_w, param_type_0 image_h, volatile axi_data_slv *BAR_image_in);

// coeur dataflow
void DMA24b_mm2s (video_stream_out &STR_video_out, param_type_0 image_w, param_type_0 image_h, volatile axi_data_slv *image_in);

#endif // DMA24B_MM2S_H
