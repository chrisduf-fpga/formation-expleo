#==============================================================================
# sim_common.tcl  --  logique partagee par run_sim.tcl et run_sim_axis.tcl
#------------------------------------------------------------------------------
# Les deux bancs du projet partagent le fileset sim_1, qui n'a qu'UN top, qu'UNE
# duree de run et qu'un jeu de vues d'ondes. Chaque script batch doit donc :
#   * FIXER le top qui l'interesse -- et non se fier a celui qui traine dans le
#     .xpr, qui peut avoir ete change depuis le GUI. Sans cela ./build_all.sh sim
#     simule silencieusement l'autre banc (constate).
#   * neutraliser les points d'arret enregistres (cf. tb_clear_breakpoints dans
#     src/sim/select_tb.tcl : un seul suffit a arreter le run a t=0, et deux dans
#     un meme fichier VHDL font echouer l'etape 'simulate' sous xsim 2020.2) ;
#   * desactiver la vue d'ondes de l'autre banc le temps du run, pour ne pas
#     noyer le log sous les "Simulation object ... was not found" ;
#   * TOUT REMETTRE en etat ensuite, y compris apres un echec.
#
# tb_run_bench <banc> ou <banc> vaut "gpio" ou "axis".
#==============================================================================

proc tb_run_bench {which} {

    set root [file normalize [file join [file dirname [info script]] ..]]
    source [file join $root src sim select_tb.tcl]

    switch -exact -- $which {
        gpio {
            set my_wcfg [file join $root src sim tb_socora_gpio_behav.wcfg]
            set select   tb_gpio
        }
        axis {
            set my_wcfg [file join $root src sim tb_environnement_behav.wcfg]
            set select   tb_axis
        }
        default { error "banc inconnu : $which (attendu gpio ou axis)" }
    }

    set sim1       [get_filesets sim_1]
    set saved_top  [get_property top $sim1]
    set saved_run  [get_property -quiet xsim.simulate.runtime $sim1]
    set saved_view [get_property -quiet xsim.view $sim1]

    # Les vues d'ondes des AUTRES bancs : a desactiver le temps du run.
    set wcfg_others {}
    foreach f [get_files -quiet -of_objects $sim1 {*.wcfg}] {
        if {[file normalize $f] ne [file normalize $my_wcfg]} {
            lappend wcfg_others $f
        }
    }

    set rc [catch {
        $select
        foreach f $wcfg_others {
            catch {set_property is_enabled false [get_files -of_objects $sim1 $f]}
        }
        if {[file exists $my_wcfg]} {
            catch {set_property is_enabled true [get_files -of_objects $sim1 $my_wcfg]}
        }
        puts "INFO : top de simulation = [get_property top $sim1]"
        launch_simulation
        close_sim
    } err]

    #--------------------------------------------------------------------------
    # Restauration -- systematique, y compris apres echec.
    #--------------------------------------------------------------------------
    # Etat de reference (celui que pose add_sim.tcl) : les DEUX vues actives,
    # pour qu'un utilisateur du GUI qui bascule le top a la main voie malgre tout
    # ses signaux. Voir le pave dans src/sim/add_sim.tcl.
    foreach f [get_files -quiet -of_objects $sim1 {*.wcfg}] {
        catch {set_property is_enabled true [get_files -of_objects $sim1 $f]}
    }
    catch {set_property top $saved_top $sim1}
    catch {set_property -name {xsim.simulate.runtime} -value $saved_run -objects $sim1}
    if {$saved_view ne ""} {
        catch {set_property -name {xsim.view} -value $saved_view -objects $sim1}
    }

    # Verification explicite : une restauration ratee doit se voir dans le log,
    # pas se decouvrir au run suivant de l'autre banc.
    puts "INFO : sim_1 restaure -- top=[get_property top $sim1]\
 runtime=[get_property -quiet xsim.simulate.runtime $sim1]\
 vue=[file tail [get_property -quiet xsim.view $sim1]]"

    if {$rc} { error $err }
}
