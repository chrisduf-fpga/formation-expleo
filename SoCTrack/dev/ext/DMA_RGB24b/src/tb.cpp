#include "DMA24b_mm2s.h"
#include <iostream>
#include <fstream>
#include <cstdio>
#include <cstring>

using namespace std;

//Remarque : IMAGE_H_o, IMAGE_W_o et les formats sont definis dans generics_n_options.h

//plans couleur de reference (lus depuis les fichiers d'echantillons)
static unsigned char plane_r[IMAGE_H_o][IMAGE_W_o];
static unsigned char plane_g[IMAGE_H_o][IMAGE_W_o];
static unsigned char plane_b[IMAGE_H_o][IMAGE_W_o];

//image en "DDR", vue par le port AXI4 master du DMA
static volatile axi_data_slv A[DDR_SIZE];

//lecture d'un plan couleur : IMAGE_H_o lignes de IMAGE_W_o valeurs decimales
static int read_plane(const char *path, unsigned char plane[IMAGE_H_o][IMAGE_W_o]){
	ifstream f(path);
	if(!f.is_open()){
		printf("ERREUR : impossible d'ouvrir %s\n", path);
		return 1;
	}
	for(int j = 0; j < IMAGE_H_o; j++){
		for(int i = 0; i < IMAGE_W_o; i++){
			int v;
			if(!(f >> v)){
				printf("ERREUR : fichier %s trop court (ligne %d colonne %d)\n", path, j, i);
				return 1;
			}
			plane[j][i] = (unsigned char)v;
		}
	}
	return 0;
}

//ecriture d'un plan couleur au meme format que les fichiers d'entree
static void write_plane(const char *path, unsigned char plane[IMAGE_H_o][IMAGE_W_o]){
	ofstream f(path);
	for(int j = 0; j < IMAGE_H_o; j++){
		for(int i = 0; i < IMAGE_W_o; i++){
			f << (int)plane[j][i];
			f << ((i == IMAGE_W_o-1) ? '\n' : '\t');
		}
	}
}

int main(int argc, char **argv){

	const char *dir_in  = (argc > 1) ? argv[1] : INPUT_DATA_PATH_o;
	const char *dir_out = (argc > 2) ? argv[2] : OUTPUT_DATA_PATH_o;

	char path[512];

	//------------------------------------------------------------------
	// 1) lecture des echantillons d'entree (3 plans R, G, B)
	//------------------------------------------------------------------
	sprintf(path, "%ssample_in_r.txt", dir_in); if(read_plane(path, plane_r)) return 1;
	sprintf(path, "%ssample_in_g.txt", dir_in); if(read_plane(path, plane_g)) return 1;
	sprintf(path, "%ssample_in_b.txt", dir_in); if(read_plane(path, plane_b)) return 1;
	printf("Image %dx%d lue, format memoire = %s, %d pixel(s)/groupe, %d mot(s) AXI4/groupe\n",
	       IMAGE_W_o, IMAGE_H_o,
	       RGB_MM_PACKED_g ? "RGB888 packe (3 o/px)" : "XRGB8888 (4 o/px)",
	       PX_PER_GROUP_g, BEATS_PER_GROUP_g);

	//------------------------------------------------------------------
	// 2) construction de l'image en memoire, au format attendu par le DMA
	//------------------------------------------------------------------
	for(int j = 0; j < IMAGE_H_o; j++){
		for(int i = 0; i < IMAGE_W_o/PX_PER_GROUP_g; i++){
			mm_group_t grp = 0;
			for(int p = 0; p < PX_PER_GROUP_g; p++){
				const int x = i*PX_PER_GROUP_g + p;
				video_pixel_t px;
				px.range(3*COMP_SIZE_g-1, 2*COMP_SIZE_g) = plane_r[j][x];
				px.range(2*COMP_SIZE_g-1,   COMP_SIZE_g) = plane_g[j][x];
				px.range(  COMP_SIZE_g-1,             0) = plane_b[j][x];
				DMA24b_mm2s_set_pixel(grp, p, px);
			}
			for(int b = 0; b < BEATS_PER_GROUP_g; b++){
				A[j*MM_LINE_STRIDE_c + i*BEATS_PER_GROUP_g + b] =
					grp.range(AXI_MM_SIZE_g*(b+1)-1, AXI_MM_SIZE_g*b);
			}
		}
	}

	//------------------------------------------------------------------
	// 3) appel du DMA : genere le stream video de sortie
	//------------------------------------------------------------------
	static video_stream_out         stream_out;    //stream de l'image de sortie
	static video_stream_element_out video_elt_out; //un element du stream de sortie

	DMA24bUnit_mm2s(stream_out, IMAGE_W_o, IMAGE_H_o, A);

	//------------------------------------------------------------------
	// 4) relecture du stream : verification data / TLAST / TUSER
	//    et reconstruction des plans de sortie
	//------------------------------------------------------------------
	static unsigned char out_r[IMAGE_H_o][IMAGE_W_o];
	static unsigned char out_g[IMAGE_H_o][IMAGE_W_o];
	static unsigned char out_b[IMAGE_H_o][IMAGE_W_o];

	int err_data = 0, err_last = 0, err_user = 0;

	for(int j = 0; j < IMAGE_H_o; j++){
		for(int i = 0; i < IMAGE_W_o; i++){
			if(stream_out.empty()){
				printf("ERREUR : stream trop court (ligne %d colonne %d)\n", j, i);
				return 1;
			}
			stream_out >> video_elt_out;

			const unsigned char r = (unsigned char)(unsigned int)video_elt_out.data.range(3*COMP_SIZE_g-1, 2*COMP_SIZE_g);
			const unsigned char g = (unsigned char)(unsigned int)video_elt_out.data.range(2*COMP_SIZE_g-1,   COMP_SIZE_g);
			const unsigned char b = (unsigned char)(unsigned int)video_elt_out.data.range(  COMP_SIZE_g-1,             0);
			out_r[j][i] = r; out_g[j][i] = g; out_b[j][i] = b;

			//verification de la donnee
			if(r != plane_r[j][i] || g != plane_g[j][i] || b != plane_b[j][i]){
				if(err_data < 10) printf("ERREUR data ligne %d colonne %d : lu (%3d,%3d,%3d), attendu (%3d,%3d,%3d)\n",
				                         j, i, r, g, b, plane_r[j][i], plane_g[j][i], plane_b[j][i]);
				err_data++;
			}

			//verification du TLAST : actif uniquement sur le dernier pixel de la ligne
			const int exp_last = (i == IMAGE_W_o-1) ? 1 : 0;
			if((int)video_elt_out.last != exp_last){
				if(err_last < 10) printf("ERREUR tlast ligne %d colonne %d : lu %d, attendu %d\n",
				                         j, i, (int)video_elt_out.last, exp_last);
				err_last++;
			}

			//verification du TUSER (SOF) : actif uniquement sur le premier pixel de l'image
			const int exp_user = ((j == 0) && (i == 0)) ? 1 : 0;
			if((int)video_elt_out.user != exp_user){
				if(err_user < 10) printf("ERREUR tuser ligne %d colonne %d : lu %d, attendu %d\n",
				                         j, i, (int)video_elt_out.user, exp_user);
				err_user++;
			}
		}
	}

	if(!stream_out.empty()){
		printf("ERREUR : le stream contient des elements en trop\n");
		err_data++;
	}

	//------------------------------------------------------------------
	// 5) ecriture des echantillons de sortie
	//------------------------------------------------------------------
	sprintf(path, "%ssample_out_r.txt", dir_out); write_plane(path, out_r);
	sprintf(path, "%ssample_out_g.txt", dir_out); write_plane(path, out_g);
	sprintf(path, "%ssample_out_b.txt", dir_out); write_plane(path, out_b);

	//image couleur reconstituee, directement visualisable
	sprintf(path, "%ssample_out_rgb.ppm", dir_out);
	FILE *fppm = fopen(path, "wb");
	if(fppm){
		fprintf(fppm, "P6\n%d %d\n255\n", IMAGE_W_o, IMAGE_H_o);
		for(int j = 0; j < IMAGE_H_o; j++){
			for(int i = 0; i < IMAGE_W_o; i++){
				unsigned char px[3] = { out_r[j][i], out_g[j][i], out_b[j][i] };
				fwrite(px, 1, 3, fppm);
			}
		}
		fclose(fppm);
	}
	printf("Echantillons de sortie ecrits dans %s\n", dir_out);

	//------------------------------------------------------------------
	printf("Erreurs data  : %d\n", err_data);
	printf("Erreurs tlast : %d\n", err_last);
	printf("Erreurs tuser : %d\n", err_user);
	if(err_data != 0 || err_last != 0 || err_user != 0){
		printf("TEST FAILED\n");
		return 1;
	}
	printf("TEST PASSED\n");

	return 0;
}
