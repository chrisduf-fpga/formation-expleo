# SoCTrack Physical constraints
#

## RGB LEDs
#
# LED0_B
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports {LED0[0]}]
# LED0_G
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {LED0[1]}]
# LED0_R
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {LED0[2]}]
# LED1_B
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {LED1[0]}]
# LED1_G
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports {LED1[1]}]
# LED1_R
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {LED1[2]}]
# Don't use actual set_output_delay constraints for a plain LED output,
# which port is not a synchronous interface to another chip/bus.
# Prevent Vivado from treating LED0_R as a timing-critical output path,
# and warn about missing timing constraints.
set_false_path -to [get_ports {LED0[0]}]
set_false_path -to [get_ports {LED0[1]}]
set_false_path -to [get_ports {LED0[2]}]
set_false_path -to [get_ports {LED1[0]}]
set_false_path -to [get_ports {LED1[1]}]
set_false_path -to [get_ports {LED1[2]}]

# Buttons
#
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports BTN0]
#set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; #IO_L4P_T0_35 Sch=btn[1]
set_false_path -from [get_ports BTN0]


# PMOD VGA
# Pmod Header JA
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports {VGA_R[0]}]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports {VGA_R[1]}]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {VGA_R[2]}]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports {VGA_R[3]}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {VGA_B[0]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {VGA_B[1]}]
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {VGA_B[2]}]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports {VGA_B[3]}]

## Pmod Header JB
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {VGA_G[0]}]
set_property -dict {PACKAGE_PIN Y14 IOSTANDARD LVCMOS33} [get_ports {VGA_G[1]}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {VGA_G[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {VGA_G[3]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports VGA_HSYNC]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports VGA_VSYNC]
#set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { jb[6] }]; #IO_L4P_T0_34 Sch=jb_p[4]
#set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { jb[7] }]; #IO_L4N_T0_34 Sch=jb_n[4]



#create_debug_core u_ila_0 ila
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
#set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
#set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
#set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
#set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
#set_property port_width 1 [get_debug_ports u_ila_0/clk]
#connect_debug_port u_ila_0/clk [get_nets [list BD/soctrack_pl_bd_i/processing_system7_0/inst/FCLK_CLK0]]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
#set_property port_width 12 [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0 [get_nets [list {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[0]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[1]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[2]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[3]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[4]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[5]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[6]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[7]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[8]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[9]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[10]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_width[11]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
#set_property port_width 24 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets [list {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[0]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[1]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[2]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[3]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[4]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[5]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[6]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[7]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[8]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[9]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[10]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[11]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[12]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[13]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[14]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[15]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[16]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[17]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[18]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[19]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[20]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[21]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[22]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/s1_axis_tdata[23]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
#set_property port_width 24 [get_debug_ports u_ila_0/probe2]
#connect_debug_port u_ila_0/probe2 [get_nets [list {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[0]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[1]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[2]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[3]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[4]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[5]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[6]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[7]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[8]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[9]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[10]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[11]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[12]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[13]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[14]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[15]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[16]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[17]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[18]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[19]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[20]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[21]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[22]} {BD/soctrack_pl_bd_i/axis_mux_0/U0/m_axis_tdata[23]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
#set_property port_width 8 [get_debug_ports u_ila_0/probe3]
#connect_debug_port u_ila_0/probe3 [get_nets [list {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_w[4]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_w[5]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_w[6]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_w[7]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_w[8]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_w[9]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_w[10]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_w[11]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
#set_property port_width 12 [get_debug_ports u_ila_0/probe4]
#connect_debug_port u_ila_0/probe4 [get_nets [list {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[0]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[1]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[2]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[3]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[4]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[5]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[6]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[7]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[8]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[9]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[10]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_h[11]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
#set_property port_width 1 [get_debug_ports u_ila_0/probe5]
#connect_debug_port u_ila_0/probe5 [get_nets [list {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TUSER[0]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
#set_property port_width 60 [get_debug_ports u_ila_0/probe6]
#connect_debug_port u_ila_0/probe6 [get_nets [list {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[4]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[5]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[6]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[7]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[8]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[9]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[10]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[11]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[12]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[13]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[14]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[15]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[16]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[17]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[18]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[19]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[20]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[21]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[22]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[23]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[24]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[25]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[26]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[27]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[28]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[29]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[30]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[31]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[32]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[33]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[34]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[35]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[36]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[37]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[38]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[39]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[40]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[41]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[42]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[43]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[44]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[45]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[46]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[47]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[48]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[49]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[50]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[51]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[52]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[53]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[54]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[55]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[56]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[57]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[58]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[59]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[60]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[61]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[62]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/image_in[63]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
#set_property port_width 1 [get_debug_ports u_ila_0/probe7]
#connect_debug_port u_ila_0/probe7 [get_nets [list {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TLAST[0]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
#set_property port_width 24 [get_debug_ports u_ila_0/probe8]
#connect_debug_port u_ila_0/probe8 [get_nets [list {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[0]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[1]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[2]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[3]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[4]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[5]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[6]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[7]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[8]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[9]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[10]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[11]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[12]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[13]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[14]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[15]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[16]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[17]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[18]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[19]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[20]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[21]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[22]} {BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TDATA[23]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
#set_property port_width 12 [get_debug_ports u_ila_0/probe9]
#connect_debug_port u_ila_0/probe9 [get_nets [list {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[0]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[1]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[2]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[3]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[4]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[5]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[6]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[7]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[8]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[9]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[10]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_height[11]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
#set_property port_width 64 [get_debug_ports u_ila_0/probe10]
#connect_debug_port u_ila_0/probe10 [get_nets [list {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[0]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[1]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[2]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[3]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[4]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[5]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[6]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[7]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[8]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[9]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[10]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[11]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[12]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[13]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[14]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[15]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[16]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[17]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[18]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[19]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[20]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[21]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[22]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[23]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[24]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[25]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[26]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[27]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[28]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[29]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[30]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[31]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[32]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[33]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[34]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[35]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[36]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[37]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[38]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[39]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[40]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[41]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[42]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[43]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[44]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[45]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[46]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[47]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[48]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[49]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[50]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[51]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[52]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[53]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[54]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[55]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[56]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[57]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[58]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[59]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[60]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[61]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[62]} {BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_fb_addr[63]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
#set_property port_width 1 [get_debug_ports u_ila_0/probe11]
#connect_debug_port u_ila_0/probe11 [get_nets [list BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/ap_done]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
#set_property port_width 1 [get_debug_ports u_ila_0/probe12]
#connect_debug_port u_ila_0/probe12 [get_nets [list BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/ap_start]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
#set_property port_width 1 [get_debug_ports u_ila_0/probe13]
#connect_debug_port u_ila_0/probe13 [get_nets [list BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TREADY]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
#set_property port_width 1 [get_debug_ports u_ila_0/probe14]
#connect_debug_port u_ila_0/probe14 [get_nets [list BD/soctrack_pl_bd_i/DMA24bUnit_mm2s_0/STR_video_out_TVALID]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
#set_property port_width 1 [get_debug_ports u_ila_0/probe15]
#connect_debug_port u_ila_0/probe15 [get_nets [list BD/soctrack_pl_bd_i/axi_dma24_fb_ctrl_0/o_ap_start]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
#set_property port_width 1 [get_debug_ports u_ila_0/probe16]
#connect_debug_port u_ila_0/probe16 [get_nets [list BD/soctrack_pl_bd_i/axis_mux_0/U0/i_axis_sel]]
#create_debug_core u_ila_1 ila
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
#set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
#set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
#set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
#set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
#set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
#set_property port_width 1 [get_debug_ports u_ila_1/clk]
#connect_debug_port u_ila_1/clk [get_nets [list BD/soctrack_pl_bd_i/axis_to_vga_out_0/U0/axis_to_vga_out_bd_i/clk_wiz_vga/inst/clk_vga]]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
#set_property port_width 4 [get_debug_ports u_ila_1/probe0]
#connect_debug_port u_ila_1/probe0 [get_nets [list {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_r[0]} {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_r[1]} {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_r[2]} {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_r[3]}]]
#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
#set_property port_width 4 [get_debug_ports u_ila_1/probe1]
#connect_debug_port u_ila_1/probe1 [get_nets [list {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_b[0]} {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_b[1]} {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_b[2]} {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_b[3]}]]
#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
#set_property port_width 4 [get_debug_ports u_ila_1/probe2]
#connect_debug_port u_ila_1/probe2 [get_nets [list {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_g[0]} {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_g[1]} {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_g[2]} {BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_rgb4_g[3]}]]
#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
#set_property port_width 1 [get_debug_ports u_ila_1/probe3]
#connect_debug_port u_ila_1/probe3 [get_nets [list BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_hsync]]
#create_debug_port u_ila_1 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
#set_property port_width 1 [get_debug_ports u_ila_1/probe4]
#connect_debug_port u_ila_1/probe4 [get_nets [list BD/soctrack_pl_bd_i/axis_to_vga_out_0/o_vga_vsync]]
#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets u_ila_1_clk_vga]
