#include "DMA24b_mm2s.h"
#include <stdio.h>


/*
 * Process producteur : lit la memoire par paquets de BURST_LEN_g mots AXI4
 * et pousse chaque mot dans le FIFO au fil de l'eau.
 * Nid de boucles parfait -> aplati par HLS, pipeline II=1 sans bulle entre paquets.
 */
void DMA24b_mm2s_fetch(volatile axi_data_slv* mm_buffer, mm_fifo_t &fifo, int img_w, int img_h){
	axi_data_slv data_mm_buffer;
	const int beats_per_line = (img_w/PX_PER_GROUP_g)*BEATS_PER_GROUP_g; //mots AXI4 par ligne utile
	const int nb_burst       = beats_per_line/BURST_LEN_g;               //doit tomber juste (cf. utils.h)
	line_loop: for (int j=0; j<img_h; j++){                    //pour toutes les lignes
		burst_loop: for (int i=0; i<nb_burst; i++){            //pour tous les paquets de la ligne
			beat_loop: for (int b=0; b<BURST_LEN_g; b++){      //burst de BURST_LEN_g mots
				#pragma HLS PIPELINE II = 1
				data_mm_buffer = mm_buffer[i*BURST_LEN_g + b + j*MM_LINE_STRIDE_c];
				fifo << data_mm_buffer;
			}
		}
	}
}

/*
 * Process consommateur : depile le FIFO et debite sur le bus AXI4-Stream.
 * Traite un "groupe" a la fois : BEATS_PER_GROUP_g mots memoire donnent
 * exactement PX_PER_GROUP_g pixels RGB, sans pixel a cheval sur deux groupes.
 * La boucle est pipelinee a II = PX_PER_GROUP_g avec les boucles internes
 * deroulees -> debit soutenu de 1 pixel par coup d'horloge sur l'AXI4-Stream.
 * TLAST est positionne sur le dernier pixel de chaque ligne (EOL),
 * TUSER sur le tout premier pixel de l'image (SOF).
 */
void DMA24b_mm2s_streamout(video_stream_out &STR_video_out, mm_fifo_t &fifo, int img_w, int img_h){
	video_stream_element_out video_elt_out; //element en sortie
	mm_group_t grp;                         //groupe memoire courant
	const int last_i = img_w/PX_PER_GROUP_g - 1;
	line_loop: for(int j = 0; j < img_h; j++){                 //pour toutes les lignes
		group_loop: for(int i = 0; i <= last_i; i++){          //pour tous les groupes de la ligne
			PRAGMA_HLS(HLS PIPELINE II = PX_PER_GROUP_g)
			read_loop: for(int b = 0; b < BEATS_PER_GROUP_g; b++){
				#pragma HLS UNROLL
				grp.range(AXI_MM_SIZE_g*(b+1)-1, AXI_MM_SIZE_g*b) = fifo.read();
			}
			px_loop: for(int p = 0; p < PX_PER_GROUP_g; p++){
				#pragma HLS UNROLL
				video_elt_out.data = DMA24b_mm2s_get_pixel(grp, p);
				video_elt_out.keep = -1;                                              //tous les octets valides
				video_elt_out.strb = -1;
				video_elt_out.last = ((i == last_i) && (p == PX_PER_GROUP_g-1)) ? 1 : 0; //fin de ligne
				video_elt_out.user = ((j == 0) && (i == 0) && (p == 0)) ? 1 : 0;         //debut d'image
				STR_video_out << video_elt_out;
			}
		}
	}
}

void DMA24bUnit_mm2s (video_stream_out &STR_video_out, param_type_0 image_w, param_type_0 image_h, volatile axi_data_slv *image_in){
	#pragma HLS INTERFACE axis    port = STR_video_out //implementation du port STR_video_out ; pour la sortie
	#pragma HLS INTERFACE ap_none port = image_w       //pas de protocol, l'interface est un port de donnee ; donnee image_w
	#pragma HLS INTERFACE ap_none port = image_h       //pas de protocol, l'interface est un port de donnee ; donnee image_h
	PRAGMA_HLS(HLS INTERFACE m_axi port=image_in depth=DDR_SIZE offset=direct max_read_burst_length=MAX_READ_BURST_g)

	DMA24b_mm2s(STR_video_out, image_w, image_h, image_in);
}


void DMA24b_mm2s (video_stream_out &STR_video_out, param_type_0 image_w, param_type_0 image_h, volatile axi_data_slv *BAR_image_in){
	#pragma HLS DATAFLOW

	//canal de dataflow entre le fetch et la sortie : local et non-static
	//la profondeur du FIFO est portee par le parametre template de mm_fifo_t (MM2S_FIFO_DEPTH_g)
	mm_fifo_t mm_fifo("mm_fifo");

	DMA24b_mm2s_fetch(BAR_image_in, mm_fifo, image_w, image_h);

	DMA24b_mm2s_streamout(STR_video_out, mm_fifo, image_w, image_h);
}
