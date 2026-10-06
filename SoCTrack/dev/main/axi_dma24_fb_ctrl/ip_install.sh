#!/usr/bin/env sh

PRJ_ROOT=$(  cd -- "$(dirname -- "$0")" >/dev/null 2>&1 &&  pwd -P)
SOCTRACK_ROOT=$(realpath ${PRJ_ROOT}/../../..)
USER_IP_REPO="$SOCTRACK_ROOT/dev/UserIPs"

IP_BASENAME=$(basename "$PRJ_ROOT")
IP_REPO="${USER_IP_REPO}/${IP_BASENAME}"

IP_VENDOR="cd"
IP_LIB="soctrack"
IP_VERSION="1.0"
IP_NAME="${IP_VENDOR}_${IP_LIB}_${IP_BASENAME}_${IP_VERSION}"

echo "IP: ${IP_NAME}"
echo "IP Repository (will be removed): ${IP_REPO}"
echo

printf "Continue? [y/N] "
read -r answer
case "$answer" in
	[nN])
		echo "bye."
		exit 1
		;;
	*)
		echo "Installing IP."
		;;
esac

IP_ZIP=$PRJ_ROOT/${IP_BASENAME}_${IP_VERSION}/${IP_NAME}.zip

if [ -d "${IP_REPO}" ]; then
	rm -rf "${IP_REPO}"
fi
mkdir -p "${IP_REPO}"

unzip -ou -q "${IP_ZIP}" -d "${IP_REPO}"
