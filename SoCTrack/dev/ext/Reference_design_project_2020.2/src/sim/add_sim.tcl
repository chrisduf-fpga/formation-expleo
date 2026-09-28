#==============================================================================
# add_sim.tcl
#------------------------------------------------------------------------------
# Ajoute au fileset sim_1 les DEUX bancs de test du projet.
#
# 1. Banc systeme -- Zynq PS7 + AXI4-Lite + GPIO           top : tb_socora_gpio
#      tb_socora_gpio_stim.vhd  couche de stimuli (VHDL)
#      tb_socora_gpio.sv        top : raccordement du DUT + transactions AXI4-Lite
#    Lancement : ./build_all.sh sim
#
# 2. Banc unitaire AXI4-Stream                             top : tb_environnement
#      Axi4s_driver.vhd         BFM source  : lit un fichier texte format ImageJ
#      Axi4s_monitor.vhd        BFM puits   : ecrit un fichier texte format ImageJ
#      tb_environnement.vhd     top VHDL : driver et monitor boucles l'un sur
#                               l'autre. C'EST LE FICHIER QUE LES ETUDIANTS
#                               EDITENT pour y intercaler leur propre IP.
#    Lancement : ./build_all.sh sim-axis
#
# Les deux bancs cohabitent dans sim_1 : tous les fichiers sont compiles a chaque
# fois, mais un seul top est elabore. Le top par defaut du fileset reste
# tb_socora_gpio ; scripts/run_sim_axis.tcl le bascule le temps de son run puis
# le restaure.
#
# Usage, depuis la console Tcl de Vivado avec SoCora.xpr ouvert :
#     source .../src/sim/add_sim.tcl
#
# Le script se localise tout seul, il n'y a pas de repertoire courant a fixer.
# Il est idempotent : on peut le relancer sans creer de doublons.
#==============================================================================

set _sim_dir [file normalize [file dirname [info script]]]

# Banc systeme (Zynq / GPIO)
set _tb_vhd  [file join $_sim_dir "tb_socora_gpio_stim.vhd"]
set _tb_sv   [file join $_sim_dir "tb_socora_gpio.sv"]

# Banc unitaire AXI4-Stream
set _axis_drv [file join $_sim_dir "Axi4s_driver.vhd"]
set _axis_mon [file join $_sim_dir "Axi4s_monitor.vhd"]
set _axis_tb  [file join $_sim_dir "tb_environnement.vhd"]

# Vues d'ondes : une par banc. La propriete xsim.view du fileset n'en accepte
# qu'une, run_sim_axis.tcl bascule dessus le temps de son run.
set _wcfg_gpio [file join $_sim_dir "tb_socora_gpio_behav.wcfg"]
set _wcfg_axis [file join $_sim_dir "tb_environnement_behav.wcfg"]

# Ordre d'ajout : les deux BFM avant le banc qui les instancie.
set _vhd_files [list $_tb_vhd $_axis_drv $_axis_mon $_axis_tb]
set _sv_files  [list $_tb_sv]

foreach _f [concat $_vhd_files $_sv_files] {
    if {![file exists $_f]} { error "Introuvable : $_f" }
}

# Les .wcfg sont facultatifs : leur absence ne doit pas bloquer le projet.
set _wcfg_files {}
foreach _f [list $_wcfg_gpio $_wcfg_axis] {
    if {[file exists $_f]} { lappend _wcfg_files $_f }
}

#------------------------------------------------------------------------------
# 0. Repertoire de sortie du monitor
#------------------------------------------------------------------------------
# axi4s_monitor ouvre son fichier en WRITE_MODE : si le repertoire n'existe pas,
# file_open echoue et la simulation s'arrete. Ce repertoire est vide, donc absent
# d'une archive ou d'un clone : on le recree systematiquement.
file mkdir [file join $_sim_dir "output"]

#------------------------------------------------------------------------------
# 1. Ajout des fichiers au fileset de simulation
#------------------------------------------------------------------------------
foreach _f [concat $_vhd_files $_sv_files $_wcfg_files] {
    if {[llength [get_files -quiet -of_objects [get_filesets sim_1] $_f]] == 0} {
        add_files -fileset sim_1 -norecurse $_f
        puts "INFO : ajoute au fileset sim_1 -> [file tail $_f]"
    } else {
        puts "INFO : deja present dans sim_1 -> [file tail $_f]"
    }
}

# VHDL-93 : les deux BFM et tb_environnement evitent deliberement les
# constructions VHDL-2008 (to_string, relecture d'un port `out`, `<= force`).
foreach _f $_vhd_files {
    set_property file_type VHDL [get_files $_f]
}
foreach _f $_sv_files {
    set_property file_type SystemVerilog [get_files $_f]
}

#------------------------------------------------------------------------------
# 2. Vues d'ondes : une seule active a la fois
#------------------------------------------------------------------------------
# PIEGE : launch_simulation ne se contente PAS de la propriete xsim.view, il
# passe a xsim un "-view" par fichier .wcfg ACTIF du fileset. Avec les deux vues
# actives, chaque run affiche une vingtaine de
#   WARNING: Simulation object /<autre banc>/... was not found in the design
# purement cosmetiques : xsim charge les deux vues, garde les signaux qu'il
# trouve et ignore les autres.
#
# On laisse malgre tout LES DEUX ACTIVES par defaut. Desactiver celle du banc
# inactif supprimerait ces avertissements, mais alors un utilisateur qui bascule
# le top a la main dans le GUI se retrouve avec la vue de L'AUTRE banc : fenetre
# d'ondes vide, aucun signal, et l'impression que rien ne s'est passe. Le confort
# du GUI prime sur la proprete du log.
#
# Les deux scripts batch (run_sim.tcl / run_sim_axis.tcl) desactivent
# temporairement la vue de l'autre banc pendant LEUR run, pour garder un log
# lisible, puis remettent les deux actives.
foreach _f [list $_wcfg_gpio $_wcfg_axis] {
    if {[file exists $_f]} { set_property is_enabled true [get_files $_f] }
}
if {[file exists $_wcfg_gpio]} {
    set_property -name {xsim.view} -value $_wcfg_gpio -objects [get_filesets sim_1]
}

#------------------------------------------------------------------------------
# 3. Declaration du top de simulation
#------------------------------------------------------------------------------
# TopAutoSet doit passer a false, sinon Vivado recalcule le top et retombe sur
# design_1_wrapper -- ou, maintenant qu'il y a deux bancs, sur l'un ou l'autre
# de facon arbitraire.
set_property top          tb_socora_gpio [get_filesets sim_1]
set_property top_lib      xil_defaultlib [get_filesets sim_1]
set_property top_auto_set false          [get_filesets sim_1]

update_compile_order -fileset sim_1

#------------------------------------------------------------------------------
# 4. Duree de simulation
#------------------------------------------------------------------------------
# Banc systeme : $finish vers 15.6 us ; on laisse une marge large pour ne pas
# tronquer le run avant le bilan PASS/FAIL.
# Banc AXI4-Stream : ~205 us pour les 32 lignes par defaut. Pour l'image
# complete (480 lignes, ~3 ms) run_sim_axis.tcl releve temporairement cette
# valeur, il n'y a rien a changer ici.
set_property -name {xsim.simulate.runtime} -value {1ms} -objects [get_filesets sim_1]

#------------------------------------------------------------------------------
# 5. Controle du modele de simulation du PS7
#------------------------------------------------------------------------------
# Ne concerne que le banc systeme. En 2020.2, "rtl" (ou vide = defaut)
# correspond DEJA au Zynq VIP (processing_system7_vip_v1_0_10). "tlm" est le
# modele QEMU/DPI-C, qui n'expose pas les taches write_data / read_data
# utilisees par le banc de test.
if {[llength [get_bd_cells -quiet /processing_system7_0]] == 0} {
    puts "INFO : block design non ouvert. Pour verifier le modele de simulation :"
    puts "       open_bd_design \[get_files design_1.bd\]"
    puts "       get_property SELECTED_SIM_MODEL \[get_bd_cells /processing_system7_0\]"
} else {
    set _model [get_property SELECTED_SIM_MODEL [get_bd_cells /processing_system7_0]]
    puts "INFO : SELECTED_SIM_MODEL = '$_model'"
    if {$_model eq "tlm"} {
        puts "ATTENTION : le PS7 est en modele TLM. Le banc de test ne compilera pas."
        puts "            Corriger avec :"
        puts "            set_property SELECTED_SIM_MODEL rtl \[get_bd_cells /processing_system7_0\]"
        puts "            generate_target simulation \[get_files design_1.bd\]"
    }
}

puts ""
puts "OK. Deux bancs disponibles dans sim_1 :"
puts "  tb_socora_gpio   (top courant)  ./build_all.sh sim"
puts "                   attendu : '=== TEST PASSED ===' et 33 verifications"
puts "  tb_environnement                ./build_all.sh sim-axis"
puts "                   attendu : C_IMG_HEIGHT lignes capturees, sans TIMEOUT,"
puts "                   et src/sim/output/stream_out_0.txt identique a l'entree"
puts "Depuis le GUI : Flow Navigator -> Run Simulation, apres avoir bascule le"
puts "top avec  set_property top <nom> \[get_filesets sim_1\]"

unset _sim_dir _tb_vhd _tb_sv _axis_drv _axis_mon _axis_tb
unset _wcfg_gpio _wcfg_axis _wcfg_files _vhd_files _sv_files _f
