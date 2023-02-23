#!/usr/bin/env bash
set -euox pipefail

UMBREL_DISK=${UMBREL_DISK:-};
UMBREL_VERSION="v0.5.3";
UMBREL_INSTALL_PATH="${UMBREL_DISK}/umbrel";


echo "About to install Umbrel in \"${UMBREL_INSTALL_PATH}\"."
mkdir -p "${UMBREL_INSTALL_PATH}"
curl --location "https://api.github.com/repos/getumbrel/umbrel/tarball/${UMBREL_VERSION}" | \
tar --extract --gzip --strip-components=1 --directory="${UMBREL_INSTALL_PATH}";

# edit the docker compose to enable ipv6
yq -i '.networks.default.enable_ipv6=true' ${UMBREL_INSTALL_PATH}/docker-compose.yml;
yq -i '.networks.default.ipam.config +={"subnet":"2001:db8:a::/64", "gateway":"2001:db8:a::1"}' ${UMBREL_INSTALL_PATH}/docker-compose.yml; 

# remove docker-compose up from start script

sed -i  "s/up --detach --build --remove-orphans/pull/" ${UMBREL_INSTALL_PATH}/scripts/start;
sed -i  "s/.*docker-compose.tor.yml.*/ docker-compose --file docker-compose.tor.yml up --detach --build --remove-orphans;/" ${UMBREL_INSTALL_PATH}/scripts/start;
 ${UMBREL_INSTALL_PATH}/scripts/start