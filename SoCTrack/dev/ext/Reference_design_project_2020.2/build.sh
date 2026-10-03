#!/usr/bin/env sh

RDP_2020_ROOT=$(  cd -- "$(dirname -- "$0")" >/dev/null 2>&1 &&  pwd -P)
SOCTRACK_ROOT=$(realpath ${RDP_2020_ROOT}/../../..)
USER_IP_REPO="$SOCTRACK_ROOT/dev/UserIPs"
IP_REPO="${USER_IP_REPO}/Reference_design_2020.2"

if [ -f "${SOCTRACK_ROOT}/scripts/xil_env.sh" ]; then
	. "${SOCTRACK_ROOT}/scripts/xil_env.sh"
fi

echo "RD2020_2: ${RDP_2020_ROOT}"
echo "SoCTrack: ${SOCTRACK_ROOT}"
echo "VIVADO_SETTINGS: ${VIVADO_SETTINGS}"
echo "VITIS_SETTINGS:  ${VITIS_SETTINGS}"
echo "IP Repo:  ${IP_REPO}"
echo

printf "Continue? [Y/n] "
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

rm -rf "${RDP_2020_ROOT}/logs"
rm -rf "${RDP_2020_ROOT}/PSCora"
rm -rf "${RDP_2020_ROOT}/SoCora"


"${RDP_2020_ROOT}/build_all.sh" vivado
"${RDP_2020_ROOT}/build_all.sh" hw
"${RDP_2020_ROOT}/build_all.sh" vitis

mkdir -p "$IP_REPO"
cp ${RDP_2020_ROOT}/SoCora/design_1_wrapper.xsa \
	${IP_REPO}/reference_design_2020_2.xsa
