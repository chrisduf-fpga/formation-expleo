#==============================================================================
# run_sim_axis.tcl  --  banc unitaire AXI4-Stream sous xsim 2020.2
#------------------------------------------------------------------------------
#     vivado -mode batch -source scripts/run_sim_axis.tcl
# ou :
#     ./build_all.sh sim-axis
#
# Elabore et execute tb_environnement (src/sim/tb_environnement.vhd) : le driver
# et le monitor AXI4-Stream boucles l'un sur l'autre, lisant
# src/sim/sample_in_gray.txt et ecrivant src/sim/output/stream_out_0.txt.
#
# Attendu dans le log : "lignes capturees : 32 (attendu 32)" et
# "pixels captures : 20480 (attendu 20480)", sans TIMEOUT.
# Verification du contenu :
#     diff <(head -32 src/sim/sample_in_gray.txt) src/sim/output/stream_out_0.txt
#
# Le script FIXE lui-meme son top (tb_environnement), neutralise les points
# d'arret enregistres, puis restaure l'etat initial du fileset : voir
# scripts/sim_common.tcl pour le detail et les raisons.
#==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root       [file normalize [file join $script_dir ..]]
set xpr        [file join $root SoCora SoCora.xpr]

if {![file exists $xpr]} {
    error "Projet introuvable : $xpr\nLancer d'abord ./build_all.sh vivado"
}

open_project $xpr

# Idempotent : rend ce script utilisable sur un projet deja construit, sans
# avoir a le recreer pour y faire entrer les fichiers du banc AXI4-Stream.
source [file join $root src sim add_sim.tcl]

# axi4s_monitor ouvre son fichier de sortie en WRITE_MODE : le repertoire doit
# exister avant le run.
file mkdir [file join $root src sim output]

source [file join $script_dir sim_common.tcl]
tb_run_bench axis

close_project
