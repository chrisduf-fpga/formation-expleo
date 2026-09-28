#==============================================================================
# select_tb.tcl  --  bascule entre les deux bancs de test du projet
#------------------------------------------------------------------------------
# Le projet contient deux bancs, qui partagent le fileset sim_1. Or un fileset
# n'a qu'UN top, qu'UNE duree de run et qu'un jeu de vues d'ondes : il faut donc
# basculer plusieurs proprietes ensemble, et c'est ce que font les deux
# procedures ci-dessous.
#
# UTILISATION DEPUIS LE GUI (console Tcl de Vivado, projet SoCora ouvert) :
#
#     source <racine>/src/sim/select_tb.tcl
#     tb_axis                 ;# banc unitaire AXI4-Stream (tb_environnement)
#     launch_simulation
#
#     tb_gpio                 ;# banc systeme Zynq/GPIO (tb_socora_gpio)
#     launch_simulation
#
# Changer le top "a la main" dans le GUI ne suffit pas : la duree de run et la
# vue d'ondes resteraient celles de l'autre banc.
#
# EN LIGNE DE COMMANDE, rien a faire : ./build_all.sh sim et
# ./build_all.sh sim-axis appellent tout cela eux-memes.
#
# Ce fichier fournit aussi tb_clear_breakpoints, voir le pave plus bas.
#==============================================================================

set ::TB_SIM_DIR [file normalize [file dirname [info script]]]

#------------------------------------------------------------------------------
# tb_clear_breakpoints -- supprime les points d'arret enregistres par xsim
#------------------------------------------------------------------------------
# DEUX RAISONS, toutes deux mesurees sous Vivado 2020.2 :
#
# 1. BUG xsim : a partir de DEUX points d'arret dans un meme fichier VHDL, xsim
#    concatene le chemin du fichier avec lui-meme et l'etape 'simulate' avorte :
#      ERROR: [Simulator 45-7] No such file
#        '<...>/src/sim/tb_environnement.vhd<...>/src/sim/tb_environnement.vhd'
#        in the design.
#    Symptome vu de l'utilisateur : la simulation ne demarre pas du tout --
#    l'horloge parait "non generee", la fenetre d'ondes reste vide, et AUCUN
#    relancement ne passe tant que les points d'arret sont la. Mesure : 1 point
#    d'arret passe, 2 et 3 echouent. Le meme essai sur le banc SystemVerilog
#    (tb_socora_gpio.sv) avec 1 point d'arret fonctionne normalement.
#
# 2. Meme sans ce bug, un point d'arret n'a pas de sens en mode batch : le run
#    s'arrete dessus et rend la main sans avoir rien verifie (constate : le banc
#    GPIO s'arrete a t=0 fs et n'affiche jamais son bilan).
#
# Les points d'arret sont stockes hors du .xpr, dans
#   SoCora/SoCora.sim/sim_1/behav/xsim/xsim.dir/<top>_behav/TempBreakPointFile.txt
# Les supprimer depuis le GUI se fait normalement par la fenetre "Breakpoints"
# (ou Ctrl+clic sur la pastille rouge dans la marge) ; cette procedure est le
# recours quand la simulation ne demarre plus et qu'on ne peut donc plus ouvrir
# cette fenetre.
#------------------------------------------------------------------------------
proc tb_clear_breakpoints {{quiet 0}} {
    set pdir [get_property DIRECTORY [current_project]]
    set pat  [file join $pdir *.sim * * xsim xsim.dir * TempBreakPointFile.txt]
    set n 0
    foreach f [glob -nocomplain $pat] {
        # Ne compter que les fichiers qui contiennent autre chose que l'en-tete.
        set nb 0
        if {![catch {set fh [open $f r]}]} {
            set nb [expr {[llength [split [string trim [read $fh]] "\n"]] - 1}]
            close $fh
        }
        if {$nb > 0} {
            catch {file copy -force $f "$f.bak"}
            if {![catch {set fh [open $f w]}]} {
                puts $fh "Breakpoint File Version 1.0"
                close $fh
                incr n $nb
                if {!$quiet} {
                    puts "INFO : $nb point(s) d'arret retire(s) de [file tail [file dirname $f]] (copie dans [file tail $f].bak)"
                }
            }
        }
    }
    if {$n == 0 && !$quiet} {
        puts "INFO : aucun point d'arret enregistre."
    }
    return $n
}

#------------------------------------------------------------------------------
# Bascule interne
#------------------------------------------------------------------------------
proc tb_select {top runtime wcfg_name} {
    set sim1 [get_filesets sim_1]

    set_property top          $top           $sim1
    set_property top_lib      xil_defaultlib $sim1
    set_property top_auto_set false          $sim1
    set_property -name {xsim.simulate.runtime} -value $runtime -objects $sim1

    # Vue d'ondes : on pointe celle du banc choisi si elle est dans le fileset.
    set wcfg [file join $::TB_SIM_DIR $wcfg_name]
    if {[file exists $wcfg]} {
        catch {set_property -name {xsim.view} -value $wcfg -objects $sim1}
    }

    update_compile_order -fileset sim_1
    tb_clear_breakpoints

    puts "INFO : sim_1 -> top=$top runtime=$runtime vue=$wcfg_name"
    puts "INFO : lancer maintenant  launch_simulation"
}

#------------------------------------------------------------------------------
# Les deux bancs
#------------------------------------------------------------------------------
proc tb_gpio {} {
    # Banc systeme : Zynq PS7 VIP + AXI4-Lite + GPIO. $finish vers 15.6 us.
    tb_select tb_socora_gpio {1ms} "tb_socora_gpio_behav.wcfg"
}

proc tb_axis {} {
    # Banc unitaire AXI4-Stream. 205 us pour C_IMG_HEIGHT = 32, ~3 ms pour 480 :
    # 20 ms couvrent les deux. Le banc coupe son horloge des la fin de capture,
    # une valeur haute ne coute donc rien.
    tb_select tb_environnement {20ms} "tb_environnement_behav.wcfg"
}

puts "select_tb.tcl charge. Procedures disponibles :"
puts "  tb_gpio                 -> banc systeme Zynq/GPIO   (tb_socora_gpio)"
puts "  tb_axis                 -> banc AXI4-Stream         (tb_environnement)"
puts "  tb_clear_breakpoints    -> retire les points d'arret enregistres"
puts "Puis : launch_simulation"
