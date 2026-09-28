#==============================================================================
# create_project.tcl  --  Reference_design_project (portage Vivado 2020.2)
#------------------------------------------------------------------------------
# Recree DE ZERO le projet Vivado "SoCora" et son block design "design_1", a
# l'identique du projet d'origine realise sous Vivado 2022.2.
#
# Vivado ne sait pas retrograder un projet : ni le .xpr, ni le .bd, ni les .xci
# de 2022.2 ne sont lisibles par 2020.2. La seule voie fiable est de rejouer la
# construction du design par script, ce que fait ce fichier.
#
# Usage :
#     vivado -mode batch -source scripts/create_project.tcl
# (depuis la racine Reference_design_project_2020.2, ou n'importe ou : le script
#  se localise tout seul).
#
# ATTENTION -- points a ne PAS modifier sans savoir :
#   * les noms de cellules (processing_system7_0, axi_gpio_0, axi_gpio_1,
#     rst_ps7_0_50M, ps7_0_axi_periph),
#   * les noms de nets forces par "connect_bd_net -net ...",
#   * les noms de ports externes (led, led2, DDR, FIXED_IO),
#   * les offsets d'adresses 0x41200000 / 0x41210000.
# Le banc de test src/sim/tb_socora_gpio.sv y fait reference EN DUR (references
# hierarchiques SystemVerilog -> VHDL) et le fichier de contraintes cible
# led_tri_o[*] / led2_tri_o[*].
#==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root       [file normalize [file join $script_dir ..]]

set proj_name  SoCora
set proj_dir   [file join $root SoCora]
set part       xc7z010clg400-1
set bd_name    design_1

puts "INFO : racine du projet   = $root"
puts "INFO : version de l'outil = [version -short]"

#------------------------------------------------------------------------------
# 0. Garde-fou : ne pas ecraser silencieusement un projet existant
#------------------------------------------------------------------------------
if {[file exists $proj_dir]} {
    error "Le repertoire $proj_dir existe deja. Le supprimer avant de relancer."
}

#------------------------------------------------------------------------------
# 1. Creation du projet
#------------------------------------------------------------------------------
create_project $proj_name $proj_dir -part $part
# Le wrapper du projet d'origine est en VHDL : on impose le meme langage cible,
# sinon make_wrapper produirait du Verilog et le banc de test (qui traverse la
# hierarchie VHDL) ne retrouverait pas ses signaux.
set_property target_language    VHDL  [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib        xil_defaultlib [current_project]

#------------------------------------------------------------------------------
# 2. Block design
#------------------------------------------------------------------------------
create_bd_design $bd_name

# --- 2.1 Zynq PS7 ------------------------------------------------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

# Le preset Cora Z7 fourni avec le projet contient l'integralite de la config PS
# du design d'origine (verifie parametre par parametre contre design_1.bd :
# aucun ecart, y compris PCW_USE_M_AXI_GP0=1 et FCLK_CLK0 = 50 MHz).
source [file join $root CoraZ7_PS_config.tcl]

set preset_dict [apply_preset processing_system7_0]
set valid_props [list_property [get_bd_cells processing_system7_0]]
set to_apply {}
set skipped  {}
foreach {prop value} $preset_dict {
    if {[lsearch -exact $valid_props $prop] >= 0} {
        lappend to_apply $prop $value
    } else {
        lappend skipped $prop
    }
}
if {[llength $skipped]} {
    puts "INFO : parametres du preset absents de l'IP 2020.2, ignores : $skipped"
}

# Application en bloc ; si un parametre est en lecture seule sous 2020.2, on
# repasse un a un pour isoler et signaler le coupable au lieu de tout perdre.
if {[catch {set_property -dict $to_apply [get_bd_cells processing_system7_0]} err]} {
    puts "ATTENTION : application groupee du preset refusee ($err)"
    puts "            reprise parametre par parametre."
    set failed {}
    foreach {prop value} $to_apply {
        if {[catch {set_property $prop $value [get_bd_cells processing_system7_0]}]} {
            lappend failed $prop
        }
    }
    if {[llength $failed]} {
        puts "ATTENTION : parametres PS7 non appliques : $failed"
    }
}

# Modele de simulation du PS7 : "rtl" = Zynq VIP (celui qu'utilise le banc de
# test). "tlm" (QEMU/DPI-C) n'expose pas write_data / read_data.
set_property SELECTED_SIM_MODEL rtl [get_bd_cells processing_system7_0]

# --- 2.2 Peripheriques AXI ---------------------------------------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
set_property -dict [list CONFIG.C_ALL_OUTPUTS {1} CONFIG.C_GPIO_WIDTH {3}] \
    [get_bd_cells axi_gpio_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_1
set_property -dict [list CONFIG.C_ALL_OUTPUTS {1} CONFIG.C_GPIO_WIDTH {3}] \
    [get_bd_cells axi_gpio_1]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_50M

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps7_0_axi_periph
set_property -dict [list CONFIG.NUM_MI {2}] [get_bd_cells ps7_0_axi_periph]

#------------------------------------------------------------------------------
# 3. Interconnexions
#------------------------------------------------------------------------------
# --- 3.1 Bus AXI -------------------------------------------------------------
connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 \
    [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
    [get_bd_intf_pins ps7_0_axi_periph/S00_AXI]
connect_bd_intf_net -intf_net ps7_0_axi_periph_M00_AXI \
    [get_bd_intf_pins ps7_0_axi_periph/M00_AXI] \
    [get_bd_intf_pins axi_gpio_0/S_AXI]
connect_bd_intf_net -intf_net ps7_0_axi_periph_M01_AXI \
    [get_bd_intf_pins ps7_0_axi_periph/M01_AXI] \
    [get_bd_intf_pins axi_gpio_1/S_AXI]

# --- 3.2 Horloge et resets ---------------------------------------------------
# Les noms de nets sont IMPOSES : le banc de test lit
#   design_1_i.processing_system7_0_FCLK_CLK0
#   design_1_i.rst_ps7_0_50M_peripheral_aresetn
connect_bd_net -net processing_system7_0_FCLK_CLK0 \
    [get_bd_pins processing_system7_0/FCLK_CLK0] \
    [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
    [get_bd_pins ps7_0_axi_periph/ACLK] \
    [get_bd_pins ps7_0_axi_periph/S00_ACLK] \
    [get_bd_pins ps7_0_axi_periph/M00_ACLK] \
    [get_bd_pins ps7_0_axi_periph/M01_ACLK] \
    [get_bd_pins rst_ps7_0_50M/slowest_sync_clk] \
    [get_bd_pins axi_gpio_0/s_axi_aclk] \
    [get_bd_pins axi_gpio_1/s_axi_aclk]

connect_bd_net -net processing_system7_0_FCLK_RESET0_N \
    [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
    [get_bd_pins rst_ps7_0_50M/ext_reset_in]

connect_bd_net -net rst_ps7_0_50M_peripheral_aresetn \
    [get_bd_pins rst_ps7_0_50M/peripheral_aresetn] \
    [get_bd_pins ps7_0_axi_periph/ARESETN] \
    [get_bd_pins ps7_0_axi_periph/S00_ARESETN] \
    [get_bd_pins ps7_0_axi_periph/M00_ARESETN] \
    [get_bd_pins ps7_0_axi_periph/M01_ARESETN] \
    [get_bd_pins axi_gpio_0/s_axi_aresetn] \
    [get_bd_pins axi_gpio_1/s_axi_aresetn]

#------------------------------------------------------------------------------
# 4. Ports externes
#------------------------------------------------------------------------------
# -name est obligatoire : sans lui Vivado nommerait DDR_0 / FIXED_IO_0 / GPIO_0,
# et les contraintes (led_tri_o[*], led2_tri_o[*]) ne s'appliqueraient plus.
make_bd_intf_pins_external -name DDR       [get_bd_intf_pins processing_system7_0/DDR]
make_bd_intf_pins_external -name FIXED_IO  [get_bd_intf_pins processing_system7_0/FIXED_IO]
make_bd_intf_pins_external -name led       [get_bd_intf_pins axi_gpio_0/GPIO]
make_bd_intf_pins_external -name led2      [get_bd_intf_pins axi_gpio_1/GPIO]

#------------------------------------------------------------------------------
# 5. Cartographie memoire
#------------------------------------------------------------------------------
# Offsets repris tels quels du design d'origine ; ils sont codes en dur dans le
# banc de test et exportes vers Vitis via xparameters.h.
assign_bd_address -offset 0x41200000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces processing_system7_0/Data] \
    [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
assign_bd_address -offset 0x41210000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces processing_system7_0/Data] \
    [get_bd_addr_segs axi_gpio_1/S_AXI/Reg] -force

#------------------------------------------------------------------------------
# 6. Validation, generation et wrapper
#------------------------------------------------------------------------------
regenerate_bd_layout
validate_bd_design
save_bd_design

set bd_file [get_files ${bd_name}.bd]
generate_target all $bd_file
make_wrapper -files $bd_file -top -import
set_property top design_1_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1

#------------------------------------------------------------------------------
# 7. Contraintes
#------------------------------------------------------------------------------
add_files -fileset constrs_1 -norecurse \
    [file join $root src constraints Cora-Z7-10-Master.xdc]

#------------------------------------------------------------------------------
# 8. Simulation
#------------------------------------------------------------------------------
# add_sim.tcl est le script d'origine (inchange hormis ses commentaires de
# version) : il ajoute les deux fichiers du banc, fixe le top de simulation et
# la duree de run. Il est idempotent.
source [file join $root src sim add_sim.tcl]

set wcfg [file join $root src sim tb_socora_gpio_behav.wcfg]
if {[file exists $wcfg]} {
    if {[llength [get_files -quiet -of_objects [get_filesets sim_1] $wcfg]] == 0} {
        add_files -fileset sim_1 -norecurse $wcfg
    }
    catch {set_property -name {xsim.view} -value $wcfg -objects [get_filesets sim_1]}
}

#------------------------------------------------------------------------------
# 9. Bilan
#------------------------------------------------------------------------------
puts "=============================================================="
puts "Projet cree   : [get_property DIRECTORY [current_project]]"
puts "Part          : [get_property PART [current_project]]"
puts "Top synthese  : [get_property top [get_filesets sources_1]]"
puts "Top simulation: [get_property top [get_filesets sim_1]]"
puts "IP verrouillee: [get_ips -quiet -filter {IS_LOCKED}]"
puts "=============================================================="

close_project
