#!/usr/bin/env sh

DMARGB24_ROOT=$(  cd -- "$(dirname -- "$0")" >/dev/null 2>&1 &&  pwd -P)
SOCTRACK_ROOT=$(realpath ${DMARGB24_ROOT}/../../..)
USER_IP_REPO="$SOCTRACK_ROOT/dev/UserIPs"
IP_REPO="${USER_IP_REPO}/DMA24bUnit_mm2s"

if [ -f "${SOCTRACK_ROOT}/scripts/xil_env.sh" ]; then
	. "${SOCTRACK_ROOT}/scripts/xil_env.sh"
fi

echo "DMARGB24: ${DMARGB24_ROOT}"
echo "SoCTrack: ${SOCTRACK_ROOT}"
echo "VIVADO_SETTINGS: ${VIVADO_SETTINGS}"
echo "VITIS_SETTINGS:  ${VITIS_SETTINGS}"
echo "IP Repo: ${IP_REPO}"
echo

printf "Continue? [y/N] "
read -r answer
case "$answer" in
	[nN])
		echo "bye."
		exit 1
		;;
	*)
		echo "......."
		;;
esac

# ld linker bundled with Vivado expects LIBRARY_PATH, not LD_LIBRARY_PATH.
# See https://adaptivesupport.amd.com/s/question/0D52E00006hpJpSSAU
export LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LIBRARY_PATH"

. ${VITIS_HLS_SETTINGS}

cd ${DMARGB24_ROOT}/hls || exit

vitis_hls -f run_hls.tcl

DMA24_IP_ZIP="${DMARGB24_ROOT}/hls/DMA24b_mm2s_prj/solution1/impl/export.zip"

if [ -d "${IP_REPO}" ]; then
	rm -rf "${IP_REPO}"
fi
mkdir -p "${IP_REPO}"

unzip -ou -q "${DMA24_IP_ZIP}" -d "${IP_REPO}"
