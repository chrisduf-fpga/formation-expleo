# PL System Clock 100 MHz.
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

# RGB LEDs
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports LED0_R]
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports LED0_B]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports LED0_G]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports LED1_R]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports LED1_B]
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports LED1_G]

# Don't use actual set_output_delay constraints for a plain LED output,
# which port is not a synchronous interface to another chip/bus.
# Prevent Vivado from treating LED0_R as a timing-critical output path,
# and warn about missing timing constraints.
set_false_path -to [get_ports LED0_R]
set_false_path -to [get_ports LED0_G]
set_false_path -to [get_ports LED0_B]
set_false_path -to [get_ports LED1_R]
set_false_path -to [get_ports LED1_G]
set_false_path -to [get_ports LED1_B]

# PIN of ChipKit Outer Digital Header.
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports resetn]
set_property PULLUP true [get_ports resetn]

# Fast-to-slow Cross Domain Crossing.
#set_false_path -from [get_pins {r_pulse_f2s_reg[3]/C}] -to [get_pins {DRV_LED1/r_color_reg[0]/D}]
#set_false_path -from [get_pins {r_pulse_f2s_reg[3]/C}] -to [get_pins {DRV_LED1/r_color_reg[1]/D}]





