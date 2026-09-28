#!/usr/bin/env bash
#==============================================================================
# build_all.sh  --  reconstruction complete du Reference_design_project en 2020.2
#------------------------------------------------------------------------------
#   ./build_all.sh              projet Vivado + build materiel + XSA + Vitis
#   ./build_all.sh vivado       projet Vivado seul (pas de synthese)
#   ./build_all.sh hw           synthese + implementation + bitstream + XSA
#   ./build_all.sh sim          simulation du banc systeme (Zynq PS7 + GPIO)
#   ./build_all.sh sim-axis     simulation du banc unitaire AXI4-Stream
#                               (driver + monitor boucles, tb_environnement.vhd)
#   ./build_all.sh vitis        workspace Vitis (necessite le XSA)
#
# Les scripts refusent d'ecraser un SoCora/ ou un PSCora/ existant : supprimer
# le repertoire concerne avant de relancer.
#==============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIVADO_SETTINGS=/tools/xilinx/Vivado/2020.2/settings64.sh
VITIS_SETTINGS=/tools/xilinx/Vitis/2020.2/settings64.sh

mkdir -p "$ROOT/logs"

run_vivado () {   # $1 = nom du script tcl (sans repertoire)
    local tcl="$1" name="${1%.tcl}"
    echo "=== Vivado 2020.2 : $tcl ==="
    # shellcheck disable=SC1090
    source "$VIVADO_SETTINGS"
    ( cd "$ROOT" && vivado -mode batch -notrace -nojournal \
        -log "logs/$name.log" -source "scripts/$tcl" )
}

run_vitis () {
    echo "=== Vitis 2020.2 : create_vitis_ws.tcl ==="
    # shellcheck disable=SC1090
    source "$VITIS_SETTINGS"
    ( cd "$ROOT" && xsct scripts/create_vitis_ws.tcl 2>&1 \
        | tee "logs/create_vitis_ws.log" )
}

case "${1:-all}" in
    vivado) run_vivado create_project.tcl ;;
    hw)     run_vivado build_hw.tcl ;;
    sim)      run_vivado run_sim.tcl ;;
    sim-axis) run_vivado run_sim_axis.tcl ;;
    vitis)  run_vitis ;;
    all)    run_vivado create_project.tcl
            run_vivado build_hw.tcl
            run_vivado run_sim.tcl
            run_vitis ;;
    *)      echo "Usage: $0 [all|vivado|hw|sim|sim-axis|vitis]" >&2 ; exit 2 ;;
esac

echo "=== Termine. Logs dans $ROOT/logs ==="
