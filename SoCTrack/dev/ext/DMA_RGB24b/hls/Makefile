# csim autonome (sans lancer Vitis HLS) : compile le testbench avec g++
XILINX_HLS ?= /tools/xilinx/Vitis_HLS/2020.2
SRC        := ../src
CXXFLAGS   := -O2 -std=c++14 -I$(SRC) -I$(XILINX_HLS)/include -Wno-unknown-pragmas

all: csim

csim: tb_dma24b
	./tb_dma24b

tb_dma24b: $(SRC)/tb.cpp $(SRC)/DMA24b_mm2s.cpp $(SRC)/DMA24b_mm2s.h $(SRC)/DMA24b_mm2s_utils.h $(SRC)/generics_n_options.h
	g++ $(CXXFLAGS) -o $@ $(SRC)/tb.cpp $(SRC)/DMA24b_mm2s.cpp

clean:
	rm -f tb_dma24b

.PHONY: all csim clean
