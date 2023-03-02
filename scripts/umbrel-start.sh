#!/usr/bin/env bash
set -exo pipefail
UMBREL_ROOT="${UMBREL_DISK}/umbrel"
UMBREL_LOGS="${UMBREL_ROOT}/logs"
USER_FILE="${UMBREL_ROOT}/db/user.json"


REBOOT="${UMBREL_ROOT}/events/signals/reboot"
if [ -f "$REBOOT" ] &&  grep -Fxq "true" "$REBOOT"
 then
    sed -i "\$d" "$REBOOT"
    echo rebooting
    $UMBREL_ROOT/scripts/stop;
 else
    echo starting
fi


# Configure Umbrel if it isn't already configured
if [[ ! -f "${UMBREL_ROOT}/statuses/configured" ]]; then
  NGINX_PORT=${NGINX_PORT:-80} NETWORK="${NETWORK:-mainnet}" "${UMBREL_ROOT}/scripts/configure"
fi
# make sure that we use the correct nginx configuration
cp /templates/nginx-override.conf ${UMBREL_INSTALL_PATH}/templates/nginx-sample.conf
REMOTE_TOR_ACCESS="false"
if [[ -f "${USER_FILE}" ]]; then
  REMOTE_TOR_ACCESS=$(cat "${USER_FILE}" | jq 'has("remoteTorAccess") and .remoteTorAccess')
fi

echo
echo "======================================"
echo "============= STARTING ==============="
echo "============== UMBREL ================"
echo "======================================"
echo

echo "Setting environment variables..."
echo

export IS_UMBREL_OS="false"

# Increase default Docker and Compose timeouts to 240s
# as bitcoin can take a long while to respond
export DOCKER_CLIENT_TIMEOUT=240
export COMPOSE_HTTP_TIMEOUT=240

cd "$UMBREL_ROOT"

echo "Starting karen..."
echo
./karen &>> "${UMBREL_LOGS}/karen.log" &

echo "Starting status monitors..."
pkill -f ./scripts/status-monitor || true
./scripts/status-monitor memory 60 &>> "${UMBREL_LOGS}/status-monitor.log" &
./scripts/status-monitor storage 60 &>> "${UMBREL_LOGS}/status-monitor.log" &
./scripts/status-monitor temperature 15 &>> "${UMBREL_LOGS}/status-monitor.log" &
./scripts/status-monitor uptime 15 &>> "${UMBREL_LOGS}/status-monitor.log" &

echo "Starting memory monitor..."
echo
./scripts/memory-monitor &>> "${UMBREL_LOGS}/memory-monitor.log" &

echo "Starting backup monitor..."
echo
./scripts/backup/monitor &>> "${UMBREL_LOGS}/backup-monitor.log" &

echo "Starting decoy backup trigger..."
echo
./scripts/backup/decoy-trigger &>> "${UMBREL_LOGS}/backup-decoy-trigger.log" &

compose_files=()

if [[ "${REMOTE_TOR_ACCESS}" == "true" ]]; then
  compose_files+=( "--file" "docker-compose.tor.yml" )
fi

compose_files+=( "--file" "docker-compose.yml" )

echo
echo "Starting Docker services..."
echo
docker-compose "${compose_files[@]}" up --detach --build --remove-orphans || {
  echo "Failed to start containers"
  exit 1
}
echo

echo "Removing status server iptables entry..."
"${UMBREL_ROOT}/scripts/umbrel-os/status-server/setup-iptables" --delete

echo
echo "Starting installed apps..."
echo
# Unlock the user file on each start of Umbrel to avoid issues
# Normally, the user file shouldn't ever be locked, if it is, something went wrong, but it could still be working
if [[ -f "${UMBREL_ROOT}/db/user.json.lock" ]]; then
  echo "WARNING: The user file was locked, Umbrel probably wasn't shut down properly"
  rm "${UMBREL_ROOT}/db/user.json.lock"
fi
"${UMBREL_ROOT}/scripts/app" start installed
echo

# If a backup of resolv.conf exists
# (that got created during the Umbrel update process)
# then we'll now restore this after Umbrel
# and the apps have started
# That way if e.g. a Docker image is still missing,
# we would use public DNS servers
RESOLV_CONF_FILE="/etc/resolv.conf"
RESOLV_CONF_BACKUP_FILE="/tmp/resolv.conf"
if [[ -f "${RESOLV_CONF_BACKUP_FILE}" ]]; then
  cat "${RESOLV_CONF_BACKUP_FILE}" > "${RESOLV_CONF_FILE}" || true

  rm --force "${RESOLV_CONF_BACKUP_FILE}" || true
fi

DEVICE_HOSTNAME="$(hostname).local"
DEVICE_IP="$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')"
TOR_HS_WEB_HOSTNAME_FILE="${UMBREL_ROOT}/tor/data/web/hostname"

echo "Umbrel is now accessible at"
echo "  http://${DEVICE_HOSTNAME}"
echo "  http://${DEVICE_IP}"
if [[ "${REMOTE_TOR_ACCESS}" == "true" ]] && [[ -f "${TOR_HS_WEB_HOSTNAME_FILE}" ]]; then
    echo "  http://$(cat "${TOR_HS_WEB_HOSTNAME_FILE}")"
fi

