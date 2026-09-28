#==============================================================================
# build_hw.tcl  --  synthese, implementation, bitstream et export XSA
#------------------------------------------------------------------------------
# A lancer apres scripts/create_project.tcl :
#     vivado -mode batch -source scripts/build_hw.tcl
#
# Produit :
#     SoCora/SoCora.runs/impl_1/design_1_wrapper.bit
#     SoCora/design_1_wrapper.xsa      (plateforme figee, bitstream inclus)
# Le XSA est l'entree du workspace Vitis (scripts/create_vitis_ws.tcl).
#==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root       [file normalize [file join $script_dir ..]]
set xpr        [file join $root SoCora SoCora.xpr]
set xsa        [file join $root SoCora design_1_wrapper.xsa]

if {![file exists $xpr]} {
    error "Projet introuvable : $xpr -- lancer d'abord scripts/create_project.tcl"
}

# Nombre de jobs : on laisse un coeur libre, borne a 8.
set jobs [expr {max(1, min(8, [exec nproc] - 1))}]
puts "INFO : build sur $jobs jobs"

open_project $xpr

proc run_and_check {run_name args} {
    reset_run $run_name
    eval launch_runs $run_name $args
    wait_on_run $run_name
    set st  [get_property STATUS   [get_runs $run_name]]
    set pr  [get_property PROGRESS [get_runs $run_name]]
    puts "INFO : $run_name -> $st ($pr)"
    if {$pr ne "100%"} {
        error "Le run $run_name a echoue : $st ($pr)"
    }
}

run_and_check synth_1 -jobs $jobs
run_and_check impl_1  -to_step write_bitstream -jobs $jobs

open_run impl_1

# Bilan timing : setup (max) et hold (min) doivent etre positifs.
set wns [get_property SLACK [get_timing_paths -delay_type max]]
set whs [get_property SLACK [get_timing_paths -delay_type min]]
puts "INFO : WNS (setup) = $wns ns / WHS (hold) = $whs ns"
if {$wns < 0 || $whs < 0} {
    puts "ATTENTION : contraintes de timing non tenues."
}
report_timing_summary -file [file join $root logs timing_summary.rpt]
report_utilization    -file [file join $root logs utilization.rpt]

# --- Export de la plateforme materielle vers Vitis ---------------------------
write_hw_platform -fixed -include_bit -force $xsa
validate_hw_platform $xsa

puts "=============================================================="
puts "Bitstream : [glob -nocomplain [file join $root SoCora SoCora.runs impl_1 *.bit]]"
puts "XSA       : $xsa"
puts "WNS/WHS   : $wns ns / $whs ns"
puts "=============================================================="

close_project
