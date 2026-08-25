# PL System Clock 100 MHz
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk]
# Clock waveform: 10 ns period, 50% duty cycle, and 5 ns phase.
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

# RGB LEDs
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports LED0_R]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports LED0_G]
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports LED0_B]
# Don't use actual set_output_delay constraints for a plain LED output,
# which port is not a synchronous interface to another chip/bus.
# Prevent Vivado from treating LED0_R as a timing-critical output path,
# and warn about missing timing constraints.
set_false_path -to [get_ports LED0_R]
set_false_path -to [get_ports LED0_G]
set_false_path -to [get_ports LED0_B]

# Buttons BTN0 and BTN1.
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports BTN0]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports BTN1]
# Buttons aren't synchronous interfaces to some chip/bus.
set_false_path -from [get_ports BTN0]
set_false_path -from [get_ports BTN1]

# PIN of ChipKit Outer Digital Header.
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports resetn]; #IO_L11P_T1_SRCC_34 Sch=ck_io[0]
set_property PULLUP true [get_ports resetn]

