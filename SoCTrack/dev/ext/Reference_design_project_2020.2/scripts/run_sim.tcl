#==============================================================================
# run_sim.tcl  --  banc systeme SoCora (Zynq PS7 + AXI4-Lite + GPIO)
#------------------------------------------------------------------------------
#     vivado -mode batch -source scripts/run_sim.tcl
# ou :
#     ./build_all.sh sim
#
# Attendu dans le log : "=== TEST PASSED ===" et 33 verifications.
# Le banc exerce le VIP PS7, les noms de nets du block design et les adresses
# 0x41200000 / 0x41210000 : c'est le controle de non-regression le plus complet
# du portage.
#
# Le script FIXE lui-meme son top (tb_socora_gpio) : depuis l'ajout du second
# banc, celui persiste dans le .xpr peut etre tb_environnement si quelqu'un l'a
# bascule depuis le GUI. Il restaure ensuite l'etat initial du fileset.
#==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root       [file normalize [file join $script_dir ..]]
set xpr        [file join $root SoCora SoCora.xpr]

if {![file exists $xpr]} {
    error "Projet introuvable : $xpr\nLancer d'abord ./build_all.sh vivado"
}

open_project $xpr

# Idempotent : garantit que les fichiers des deux bancs sont bien dans sim_1.
source [file join $root src sim add_sim.tcl]

open_bd_design [get_files design_1.bd]
puts "INFO : SELECTED_SIM_MODEL du PS7 = [get_property SELECTED_SIM_MODEL \
        [get_bd_cells /processing_system7_0]]"
close_bd_design [current_bd_design]

source [file join $script_dir sim_common.tcl]
tb_run_bench gpio

close_project
