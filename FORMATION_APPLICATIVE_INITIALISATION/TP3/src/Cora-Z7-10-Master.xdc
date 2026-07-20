# PL System Clock
set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L13P_T2_MRCC_35 Sch=sysclk
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

# Cora 7Z LED1
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { LED1_R }]; #IO_L22P_T3_AD7P_35 Sch=led1_g
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { LED1_G }]; #IO_L22P_T3_AD7P_35 Sch=led1_g
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { LED1_B }]; #IO_L22P_T3_AD7P_35 Sch=led1_g

# Cora 7Z BTN0, reset signal.
set_property -dict { PACKAGE_PIN D20   IOSTANDARD LVCMOS33 } [get_ports { BTN0 }]; #IO_L4N_T0_35 Sch=btn[0]
# Cora 7Z BTN1, restart signam.
set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS33 } [get_ports { BTN1 }]; #IO_L4P_T0_35 Sch=btn[1]
