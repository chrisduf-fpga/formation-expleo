# IP DMA RGB — MM2S (Vitis HLS)

Lit une image RGB en memoire via un port **AXI4 master (m_axi)** et la debite sur un
port **AXI4-Stream master**, 1 pixel par coup d'horloge.

## Fichiers

| fichier | role |
|---|---|
| `generics_n_options.h` | tous les parametres (taille image, format memoire, bursts, FIFO, chemins fichiers) |
| `DMA24b_mm2s_utils.h`  | types, constantes derivees, (de)packing d'un pixel dans un mot memoire |
| `DMA24b_mm2s.h/.cpp`   | l'IP : `DMA24bUnit_mm2s` (top, pragmas d'interface) + coeur dataflow |
| `tb.cpp`               | testbench csim : lit `samples/input`, verifie data/TLAST/TUSER, ecrit `samples/output` |

## Interface

```
void DMA24bUnit_mm2s(video_stream_out &STR_video_out,   // AXI4-Stream master
                     param_type_0 image_w,              // ap_none, 12 bits (640)
                     param_type_0 image_h,              // ap_none, 12 bits (480)
                     volatile axi_data_slv *image_in);  // m_axi, 128 bits, offset=direct
```

Sortie AXI4-Stream (protocole video Xilinx) :
* `TDATA[23:16] = R`, `TDATA[15:8] = G`, `TDATA[7:0] = B`
* `TLAST = 1` sur le dernier pixel de chaque ligne (EOL)
* `TUSER = 1` sur le premier pixel de l'image (SOF)

## Format memoire

`RGB_MM_PACKED_g = 1` (defaut) : **RGB888 packe**, 3 octets par pixel dans l'ordre
raster `R,G,B,R,G,B,...`. 16 pixels tiennent exactement dans 3 mots de 128 bits, donc
aucun pixel n'est a cheval sur deux groupes et une ligne de 640 pixels fait
exactement 120 mots AXI4 (1920 octets). Empreinte 640x480 : 921 600 octets.

`RGB_MM_PACKED_g = 0` : **XRGB8888**, 1 mot de 32 bits par pixel (`0x00RRGGBB`),
4 pixels par mot de 128 bits. Plus simple a produire cote logiciel, +33 % de DDR.

Contraintes : `IMAGE_W_o` et `IMAGE_STRIDE_o` multiples de `PX_PER_GROUP_g` (16 en
packe, 4 en XRGB), et nombre de mots par ligne multiple de `BURST_LEN_g`.
Ces trois conditions sont verifiees a la compilation (`#error` dans `DMA24b_mm2s_utils.h`).

## Architecture

`#pragma HLS DATAFLOW` avec deux process concurrents relies par un FIFO de
`MM2S_FIFO_DEPTH_g` mots :

* `DMA24b_mm2s_fetch` : lit la DDR par bursts de `BURST_LEN_g` mots, pipeline II=1
  (1 mot / cycle, soit ~5,3 pixels / cycle en packe) ;
* `DMA24b_mm2s_streamout` : consomme un groupe (`BEATS_PER_GROUP_g` mots), en extrait
  `PX_PER_GROUP_g` pixels et les emet ; boucle pipelinee a `II = PX_PER_GROUP_g` avec
  boucles internes deroulees, soit **1 pixel / cycle soutenu**.

Le fetch est volontairement surdimensionne par rapport au streamout : le FIFO absorbe
la latence memoire et le backpressure AXI4-Stream sans bulle en sortie.

Note : Vitis HLS n'expanse pas les macros dans `#pragma HLS`. Les pragmas parametres
par un generic (`II`, `max_read_burst_length`) passent donc par `PRAGMA_HLS(...)`
(indirection `_Pragma`), defini dans `DMA24b_mm2s_utils.h`.

## Simulation

```bash
cd hls && make csim        # csim autonome (g++ + headers Vitis HLS), rapide
cd hls && vitis_hls -f run_hls.tcl   # csim + csynth (+ export IP, a decommenter)
```

Le testbench accepte deux arguments optionnels : `<dir_in> <dir_out>` (par defaut les
chemins absolus definis dans `generics_n_options.h`).

Sorties ecrites dans `samples/output/` :
`sample_out_r.txt`, `sample_out_g.txt`, `sample_out_b.txt` (meme format que l'entree)
et `sample_out_rgb.ppm` (image couleur visualisable).
