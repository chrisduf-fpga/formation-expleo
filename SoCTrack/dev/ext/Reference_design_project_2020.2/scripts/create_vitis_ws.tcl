#==============================================================================
# create_vitis_ws.tcl  --  workspace Vitis 2020.2 "PSCora"
#------------------------------------------------------------------------------
#     source /tools/xilinx/Vitis/2020.2/settings64.sh
#     xsct scripts/create_vitis_ws.tcl
#
# Un workspace Vitis n'est pas plus retrocompatible qu'un projet Vivado : celui
# de 2022.2 est recree ici a partir du XSA produit par Vivado 2020.2.
#
# Reproduit la structure d'origine :
#   plateforme SoCora  -> domaines zynq_fsbl (boot, auto) et standalone_domain
#   applications       -> xgpio_example_1, xuartps_hello_world_example_1
#                         (template "Empty Application", sources dans src/sw/)
#==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root       [file normalize [file join $script_dir ..]]
set ws         [file join $root PSCora]
set xsa        [file join $root SoCora design_1_wrapper.xsa]

if {![file exists $xsa]} {
    error "XSA introuvable : $xsa -- lancer d'abord scripts/build_hw.tcl"
}
if {[file exists $ws]} {
    error "Le workspace $ws existe deja. Le supprimer avant de relancer."
}

file mkdir $ws
setws $ws

#------------------------------------------------------------------------------
# 1. Plateforme materielle
#------------------------------------------------------------------------------
# Sans -no-boot-bsp, Vitis cree tout seul le domaine de boot zynq_fsbl, comme
# dans le workspace d'origine.
platform create -name SoCora -hw $xsa
platform active SoCora

# Domaine applicatif. Le nom "standalone_domain" est celui du workspace 2022.2 ;
# le laisser par defaut donnerait "standalone_ps7_cortexa9_0" et casserait les
# references des .prj.
domain create -name standalone_domain -proc ps7_cortexa9_0 -os standalone
platform generate

#------------------------------------------------------------------------------
# 2. Applications
#------------------------------------------------------------------------------
# Le workspace d'origine utilise le template "Empty Application" (cf.
# <template appTemplateName="empty_application"/> dans les .prj 2022.2), le code
# provenant des exemples de driver embeddedsw. On fait pareil et on importe les
# sources depuis src/sw/.
foreach app {xgpio_example_1 xuartps_hello_world_example_1} {
    puts "INFO : creation de l'application $app"
    app create -name $app -platform SoCora -domain standalone_domain \
               -template "Empty Application"
    importsources -name $app -path [file join $root src sw $app]
    app build -name $app
}

#------------------------------------------------------------------------------
# 3. Bilan
#------------------------------------------------------------------------------
puts "=============================================================="
foreach app {xgpio_example_1 xuartps_hello_world_example_1} {
    set elf [file join $ws $app Debug $app.elf]
    if {[file exists $elf]} {
        puts "OK  : $elf ([file size $elf] octets)"
    } else {
        puts "ECHEC : $elf non produit"
    }
}
puts "=============================================================="
